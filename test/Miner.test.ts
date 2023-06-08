import { expect } from 'chai'
import { setup } from './tools/setup'
import { generateTree } from '../utils/merkleTree'
import Account from '../utils/ap/account'
import Note from '../utils/ap/note'
import { utils } from 'ethers'
import Controller from '../utils/ap/controller'
import * as fs from 'fs'
import { getPubKey, toFixedHex } from '../utils/utils'
import { MockTornadoTrees } from '../generated-types/ethers'
import { deimpresonate, impresonate } from './helpers/impresonator'
import { packEncryptedMessage } from '../utils/ap/utils'

const provingKeys = {
  rewardCircuit: require('../build/circuits/Reward.json'),
  withdrawCircuit: require('../build/circuits/Withdraw.json'),
  treeUpdateCircuit: require('../build/circuits/TreeUpdate.json'),
  rewardProvingKey: fs.readFileSync('./build/circuits/Reward_proving_key.bin').buffer,
  withdrawProvingKey: fs.readFileSync('./build/circuits/Withdraw_proving_key.bin').buffer,
  treeUpdateProvingKey: fs.readFileSync('./build/circuits/TreeUpdate_proving_key.bin').buffer,
}

const firstHardhatAccountPrivateKey = 'ac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80'
const firstHardhatPublicKey = getPubKey(firstHardhatAccountPrivateKey, 'hex')

async function registerNote(note: Note, tornadoTrees: MockTornadoTrees, pgRouterAddress: string) {
  const impresonatedPGRouter = await impresonate(pgRouterAddress)

  await tornadoTrees.setBlockNumber(note.depositBlock.toString())
  await tornadoTrees.connect(impresonatedPGRouter).registerDeposit(note.instance, toFixedHex(note.commitment))

  await tornadoTrees.setBlockNumber(note.withdrawalBlock.toString())
  await tornadoTrees
    .connect(impresonatedPGRouter)
    .registerWithdrawal(note.instance, toFixedHex(note.nullifierHash))

  deimpresonate(pgRouterAddress)

  return {
    depositLeaf: {
      instance: note.instance,
      hash: toFixedHex(note.commitment),
      block: toFixedHex(note.depositBlock),
    },
    withdrawalLeaf: {
      instance: note.instance,
      hash: toFixedHex(note.nullifierHash),
      block: toFixedHex(note.withdrawalBlock),
    },
  }
}

async function pre({ deployer, instances }) {
  const [
    {
      deployedInstance: { address: erc20_100Address },
    },
  ] = instances.deployed

  const note = new Note({
    instance: erc20_100Address,
    depositBlock: 10,
    withdrawalBlock: 10 + 4 * 60 * 24,
  })

  const depositData = []
  const withdrawalData = []

  const PGRouterAddress = await deployer['PGRouter'].address

  const { depositLeaf, withdrawalLeaf } = await registerNote(note, deployer['TornadoTrees'], PGRouterAddress)
  depositData.push(depositLeaf)
  withdrawalData.push(withdrawalLeaf)

  await deployer['TornadoTrees'].updateRoots(depositData, withdrawalData)

  const controller = new Controller({
    contract: deployer['Miner'],
    tornadoTreesContract: deployer['TornadoTrees'],
    merkleTreeHeight: 20,
    provingKeys,
  })

  await controller.init()

  return {
    note,
    controller,
    depositData,
    withdrawalData,
  }
}

describe.only('Miner', function () {
  describe('Deployment', function () {
    it('Should deploy Miner', async function () {
      const { deployer } = await setup()
      expect(deployer['Miner'].address).to.be.properAddress
    })
  })

  describe('constructor', function () {
    it('should set tornadoTrees', async function () {
      const { deployer } = await setup()
      expect(await deployer['Miner'].tornadoTrees()).to.equal(deployer['TornadoTrees'].address)
    })

    it('should set governance', async function () {
      const { deployer } = await setup()
      expect(await deployer['Miner'].governance()).to.equal(deployer.address)
    })

    it('should set verifiers', async function () {
      const { deployer } = await setup()
      const Miner = deployer['Miner']

      expect(await Miner.rewardVerifier()).to.equal(deployer['RewardVerifier'].address)
      expect(await Miner.withdrawVerifier()).to.equal(deployer['WithdrawVerifier'].address)
      expect(await Miner.treeUpdateVerifier()).to.equal(deployer['TreeUpdateVerifier'].address)
    })

    it('should set initial accountRoot', async function () {
      const { deployer } = await setup()

      const emptyTree = generateTree(20)
      const accountRoot = await deployer['Miner'].accountRoots(0)
      expect(accountRoot).to.equal(emptyTree.root())
    })

    it('should set rates', async function () {
      const { deployer, instances } = await setup()

      const [erc20_100, erc20_1000] = instances.deployed

      expect(await deployer['Miner'].rates(erc20_100.deployedInstance.address)).to.equal(10)
      expect(await deployer['Miner'].rates(erc20_1000.deployedInstance.address)).to.equal(100)
    })
  })

  describe.only('reward', function () {
    it('should reward', async function () {
      const { deployer, instances } = await setup()

      const { note, controller } = await pre({ deployer, instances })

      const zeroAccount = new Account()
      const accountCount = await deployer['Miner'].accountCount()

      expect(zeroAccount.amount).to.equal(0)

      const rewardNullifierBefore = await deployer['Miner'].rewardNullifiers(toFixedHex(note.rewardNullifier))
      expect(rewardNullifierBefore).to.equal(false)

      const accountNullifierBefore = await deployer['Miner'].accountNullifiers(
        toFixedHex(zeroAccount.nullifier),
      )
      expect(accountNullifierBefore).to.equal(false)

      const { proof, args, account, encryptedAccount } = await controller.reward({
        account: zeroAccount,
        note,
        publicKey: firstHardhatPublicKey,
      })

      const tx = deployer['Miner'][
        'reward(bytes,(uint256,uint256,address,bytes32,bytes32,bytes32,bytes32,(address,bytes),(bytes32,bytes32,bytes32,uint256,bytes32)))'
      ](proof, args)

      await expect(tx).to.emit(deployer['Miner'], 'NewAccount')

      const receipt = await tx

      const event = ((await receipt.wait()) as any).events[0]

      expect(event.args.encryptedAccount).to.equal(encryptedAccount)
      expect(event.args.commitment).to.equal(toFixedHex(account.commitment))
      expect(event.args.nullifier).to.equal(toFixedHex(zeroAccount.nullifierHash))
    })
  })
})
