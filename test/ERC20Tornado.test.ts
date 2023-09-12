import { expect } from 'chai'
import * as fs from 'fs'
import { bigInt } from 'snarkjs'
import MarkleTree from 'fixed-merkle-tree'
import websnarkUtils from 'websnark/src/utils'
import buildGroth16 from 'websnark/src/groth16'

import { setup } from './tools/setup'

import { poseidonHash2, toFixedHex } from '../utils/utils'
import { generateDepositArgs, getExtWithdrawAssetArgsHash } from '../utils/withdrawal/args'

import circuit from '../build/circuits/WithdrawAsset.json'
import { pedersenHash } from '../utils/withdrawal/utils'
const proving_key = fs.readFileSync('build/circuits/WithdrawAsset_proving_key.bin').buffer

export const makeDeposit = async (commitment: string, deployer: any, amount: number = 100) => {
  await deployer['InstanceMockERC20'].mint(deployer.address, amount)
  await deployer['InstanceMockERC20'].approve(deployer['ERC20Tornado100'].address, amount)
  await deployer['ERC20Tornado100'].deposit(commitment)
}

describe('ERC20Tornado', async function () {
  describe('Deployment', async function () {
    it('Should deploy ERC20Tornado', async function () {
      const { deployer } = await setup()
      expect(deployer['ERC20Tornado100'].address).to.be.properAddress
    })
  })
  describe('constructor', async function () {
    it('should set token', async function () {
      const { deployer } = await setup()
      expect(await deployer['ERC20Tornado100'].token()).to.be.equal(deployer['InstanceMockERC20'].address)
    })

    it('should create markle tree', async function () {
      const { deployer } = await setup()
      expect(await deployer['ERC20Tornado100'].levels()).to.be.equal(20)
    })
  })

  describe('deposit', async function () {
    it('should deposit', async function () {
      const { deployer, InstanceMockERC20 } = await setup()
      const depositArgs = generateDepositArgs()
      const commitment = toFixedHex(depositArgs.commitment)

      await makeDeposit(commitment, deployer)

      expect(await deployer['ERC20Tornado100'].commitments(commitment)).to.be.equal(true)
      expect(await deployer['ERC20Tornado100'].currentRootIndex()).to.be.equal(1)
    })
  })

  describe('withdraw', async function () {
    it('should withdraw', async function () {
      const { deployer, users } = await setup()

      const tree = new MarkleTree(20, [], {
        hashFunction: poseidonHash2,
        zeroElement: '21663839004416932945382355908790599225266501822907911457504978515578255421292',
      })

      const [user1, user2] = users

      const depositArgs = generateDepositArgs()
      const commitment = toFixedHex(depositArgs.commitment)

      await makeDeposit(commitment, deployer)

      tree.insert(commitment)
      const root = tree.root()
      const { pathElements, pathIndices } = tree.path(0)

      const extData = {
        refund: bigInt(0),
        relayer: user2.address,
        recipient: user2.address,
        fee: bigInt(0),
      }
      const extDataHash = getExtWithdrawAssetArgsHash(extData)

      const input = {
        root,
        extDataHash,
        nullifierHash: pedersenHash(depositArgs.nullifier.leInt2Buff(31)),
        pathIndices,
        pathElements,
        secret: depositArgs.secret,
        nullifier: depositArgs.nullifier,
      }

      const groth16 = await buildGroth16()

      const proofData = await websnarkUtils.genWitnessAndProve(groth16, input, circuit, proving_key)
      const { proof } = websnarkUtils.toSolidityInput(proofData)

      expect(await deployer['ERC20Tornado100'].isSpent(toFixedHex(input.nullifierHash))).to.be.equal(false)
      expect(await deployer['InstanceMockERC20'].balanceOf(user2.address)).to.be.equal(0)

      await deployer['ERC20Tornado100'].withdraw(
        proof,
        toFixedHex(input.root),
        toFixedHex(input.nullifierHash),
        toFixedHex(extData.recipient, 20),
        toFixedHex(extData.relayer, 20),
        toFixedHex(extData.fee),
        toFixedHex(extData.refund),
      )

      expect(await deployer['ERC20Tornado100'].isSpent(toFixedHex(input.nullifierHash))).to.be.equal(true)
      expect(await deployer['InstanceMockERC20'].balanceOf(user2.address)).to.be.equal(100)
    })
  })
})
