import { expect } from 'chai'
import { setup, SetupFunction } from './tools/setup'
import { generateTree } from '../utils/merkleTree'
import Account from '../utils/ap/account'
import Note from '../utils/ap/note'
import Controller from '../utils/ap/controller'
import * as fs from 'fs'
import { getPubKey, toFixedHex } from '../utils/utils'
import { MockTornadoTrees } from '../generated-types/ethers'
import { deimpresonate, impresonate } from './helpers/impresonator'
import { toBN } from 'web3-utils'

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

type PreFunctionParameter = ReturnType<SetupFunction> extends Promise<infer U> ? U : never

async function pre({ deployer, instances }: Pick<PreFunctionParameter, 'deployer' | 'instances'>) {
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

  const note2 = new Note({
    instance: erc20_100Address,
    depositBlock: 10,
    withdrawalBlock: 10 + 2 * 4 * 60 * 24,
  })

  const note3 = new Note({
    instance: erc20_100Address,
    depositBlock: 10,
    withdrawalBlock: 10 + 3 * 4 * 60 * 24,
  })

  const notes = [note, note2, note3]

  const depositData = []
  const withdrawalData = []

  const PGRouterAddress = deployer['PGRouter'].address

  for (const note of notes) {
    const { depositLeaf, withdrawalLeaf } = await registerNote(
      note,
      deployer['TornadoTrees'],
      PGRouterAddress,
    )
    withdrawalData.push(withdrawalLeaf)
    depositData.push(depositLeaf)
  }

  const minerReward =
    deployer['Miner'][
      'reward(bytes,(uint256,uint256,address,bytes32,bytes32,bytes32,bytes32,(address,bytes),(bytes32,bytes32,bytes32,uint256,bytes32)))'
    ]

  const minerReward4 =
    deployer['Miner'][
      'reward(bytes,(uint256,uint256,address,bytes32,bytes32,bytes32,bytes32,(address,bytes),(bytes32,bytes32,bytes32,uint256,bytes32)),bytes,(bytes32,bytes32,bytes32,uint256))'
    ]

  const controller = new Controller({
    contract: deployer['Miner'],
    tornadoTreesContract: deployer['TornadoTrees'],
    merkleTreeHeight: 20,
    provingKeys,
  })

  await controller.init()

  return {
    note,
    note2,
    note3,
    controller,
    depositData,
    withdrawalData,
    minerReward,
    minerReward4,
  }
}

describe('Miner', function () {
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

  describe('reward', function () {
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

    it('should use fallback with outdated tree', async function () {
      const { deployer, instances } = await setup()

      const { note, controller, note2, minerReward4, minerReward } = await pre({ deployer, instances })

      const { proof, args, account } = await controller.reward({
        account: new Account(),
        note,
        publicKey: firstHardhatPublicKey,
      })

      const tmp = await controller.reward({
        account: new Account(),
        note: note2,
        publicKey: firstHardhatPublicKey,
      })

      await minerReward(tmp.proof, tmp.args)

      await expect(minerReward(proof, args)).to.be.revertedWith('Outdated account merkle root')

      const update = await controller.treeUpdate(account.commitment)
      await minerReward4(proof, args, update.proof, update.args)

      const rootAfter = await deployer['Miner'].getLastAccountRoot()
      expect(rootAfter).to.equal(update.args.newRoot)
    })

    it('should reject with incorrect insert position', async function () {
      const { deployer, instances } = await setup()
      const { note, controller, minerReward4, minerReward, note2 } = await pre({ deployer, instances })

      const tmp = await controller.reward({
        account: new Account(),
        note: note2,
        publicKey: firstHardhatPublicKey,
      })
      await minerReward(tmp.proof, tmp.args)

      const { proof, args } = await controller.reward({
        account: new Account(),
        note,
        publicKey: firstHardhatPublicKey,
      })
      const malformedArgs = JSON.parse(JSON.stringify(args))

      let fakeIndex = toBN(args.account.outputPathIndices).sub(toBN('1'))
      malformedArgs.account.outputPathIndices = toFixedHex(fakeIndex)

      await expect(minerReward(proof, malformedArgs)).to.be.revertedWith('Incorrect account insert index')

      fakeIndex = toBN(args.account.outputPathIndices).add(toBN('1'))
      malformedArgs.account.outputPathIndices = toFixedHex(fakeIndex)

      await expect(minerReward(proof, malformedArgs)).to.be.revertedWith('Incorrect account insert index')

      fakeIndex = toBN(args.account.outputPathIndices).add(toBN('10000000000000000000000000'))
      malformedArgs.account.outputPathIndices = toFixedHex(fakeIndex)

      await expect(minerReward(proof, malformedArgs)).to.be.revertedWith('Incorrect account insert index')
    })

    it('should reject with incorrect external data hash', async () => {
      const { deployer, instances } = await setup()
      const { note, controller, minerReward4, minerReward, note2 } = await pre({ deployer, instances })

      const { proof, args } = await controller.reward({
        account: new Account(),
        note,
        publicKey: firstHardhatPublicKey,
      })
      const malformedArgs = JSON.parse(JSON.stringify(args))

      malformedArgs.extDataHash = toFixedHex('0xdeadbeef')

      await expect(minerReward(proof, malformedArgs)).to.be.revertedWith('Incorrect external data hash')

      malformedArgs.extDataHash = toFixedHex('0x00')

      await expect(minerReward(proof, malformedArgs)).to.be.revertedWith('Incorrect external data hash')
    })

    it('should prevent fee overflow', async () => {
      const { deployer, instances } = await setup()
      const { note, controller, minerReward4, minerReward, note2 } = await pre({ deployer, instances })

      const { proof, args } = await controller.reward({
        account: new Account(),
        note,
        publicKey: firstHardhatPublicKey,
      })
      const malformedArgs = JSON.parse(JSON.stringify(args))

      malformedArgs.fee = toFixedHex(toBN(2).pow(toBN(248)))

      await expect(minerReward(proof, malformedArgs)).to.be.revertedWith('Fee value out of range')

      malformedArgs.fee = toFixedHex(toBN(2).pow(toBN(256)).sub(toBN(1)))

      await expect(minerReward(proof, malformedArgs)).to.be.revertedWith('Fee value out of range')
    })

    it('should reject with invalid reward rate', async () => {
      const { deployer, instances } = await setup()
      const { note, controller, minerReward4, minerReward, note2 } = await pre({ deployer, instances })

      const { proof, args } = await controller.reward({
        account: new Account(),
        note,
        publicKey: firstHardhatPublicKey,
      })
      const malformedArgs = JSON.parse(JSON.stringify(args))

      malformedArgs.instance = deployer['Miner'].address
      await expect(minerReward(proof, malformedArgs)).to.be.revertedWith('Invalid reward rate')

      malformedArgs.rate = toFixedHex(toBN(9999999))
      await expect(minerReward(proof, malformedArgs)).to.be.revertedWith('Invalid reward rate')

      malformedArgs.instance = toFixedHex('0x00', 20)
      await expect(minerReward(proof, malformedArgs)).to.be.revertedWith('Invalid reward rate')

      const anotherInstance = instances.deployed[1].deployedInstance.address
      const rate = toBN(1000)
      await deployer['Miner'].setRates([{ instance: anotherInstance, value: rate.toString() }])

      malformedArgs.instance = anotherInstance
      malformedArgs.rate = toFixedHex(rate)

      await expect(minerReward(proof, malformedArgs)).to.be.revertedWith('Invalid reward proof')
    })

    it('should reject for double spend', async () => {
      const { deployer, instances } = await setup()
      const { note, controller, minerReward4, minerReward, note2 } = await pre({ deployer, instances })

      let { proof, args } = await controller.reward({
        account: new Account(),
        note,
        publicKey: firstHardhatPublicKey,
      })

      await expect(minerReward(proof, args)).to.be.fulfilled
      ;({ proof, args } = await controller.reward({
        account: new Account(),
        note,
        publicKey: firstHardhatPublicKey,
      }))

      await expect(minerReward(proof, args)).to.be.revertedWith('Reward has been already spent')
    })

    it('should reject for invalid proof', async () => {
      const { deployer, instances } = await setup()
      const { note, controller, minerReward4, minerReward, note2 } = await pre({ deployer, instances })

      const claim1 = await controller.reward({
        account: new Account(),
        note,
        publicKey: firstHardhatPublicKey,
      })
      const claim2 = await controller.reward({
        account: new Account(),
        note: note2,
        publicKey: firstHardhatPublicKey,
      })

      await expect(minerReward(claim2.proof, claim1.args)).to.be.revertedWith('Invalid reward proof')
    })

    it('should reject for invalid account root', async () => {
      const { deployer, instances } = await setup()
      const { note, controller, minerReward4, minerReward, note2 } = await pre({ deployer, instances })

      const account1 = new Account()
      const account2 = new Account()
      const account3 = new Account()

      const fakeTree = generateTree(20, [account1.commitment, account2.commitment, account3.commitment])

      const { proof, args } = await controller.reward({
        account: account1,
        note,
        publicKey: firstHardhatPublicKey,
      })
      const malformedArgs = JSON.parse(JSON.stringify(args))
      malformedArgs.account.inputRoot = toFixedHex(fakeTree.root())

      await expect(minerReward(proof, malformedArgs)).to.be.revertedWith('Invalid account root')
    })

    it('should reject with outdated account root (treeUpdate proof validation)', async () => {
      const { deployer, instances } = await setup()
      const { note, controller, minerReward4, minerReward, note2, note3 } = await pre({ deployer, instances })

      const { proof, args, account } = await controller.reward({
        account: new Account(),
        note,
        publicKey: firstHardhatPublicKey,
      })

      const tmp = await controller.reward({
        account: new Account(),
        note: note2,
        publicKey: firstHardhatPublicKey,
      })

      await minerReward(tmp.proof, tmp.args)

      await expect(minerReward(proof, args)).to.be.revertedWith('Outdated account merkle root')

      const update = await controller.treeUpdate(account.commitment)

      const tmp2 = await controller.reward({
        account: new Account(),
        note: note3,
        publicKey: firstHardhatPublicKey,
      })
      await minerReward(tmp2.proof, tmp2.args)

      await expect(minerReward4(proof, args, update.proof, update.args)).to.be.revertedWith(
        'Outdated tree update merkle root',
      )
    })

    it('should reject for incorrect commitment (treeUpdate proof validation)', async () => {
      const { deployer, instances } = await setup()
      const { note, controller, minerReward4, minerReward, note2, note3 } = await pre({ deployer, instances })

      const claim = await controller.reward({
        account: new Account(),
        note,
        publicKey: firstHardhatPublicKey,
      })

      const tmp = await controller.reward({
        account: new Account(),
        note: note2,
        publicKey: firstHardhatPublicKey,
      })
      await minerReward(tmp.proof, tmp.args)

      await expect(minerReward(claim.proof, claim.args)).to.be.revertedWith('Outdated account merkle root')
      const anotherAccount = new Account()
      const update = await controller.treeUpdate(anotherAccount.commitment)

      await expect(minerReward4(claim.proof, claim.args, update.proof, update.args)).to.be.revertedWith(
        'Incorrect commitment inserted',
      )

      claim.args.account.outputCommitment = update.args.leaf

      await expect(minerReward4(claim.proof, claim.args, update.proof, update.args)).to.be.revertedWith(
        'Invalid reward proof',
      )
    })

    it('should reject for incorrect account insert index (treeUpdate proof validation)', async () => {
      const { deployer, instances } = await setup()
      const { note, controller, minerReward4, minerReward, note2, note3 } = await pre({ deployer, instances })

      const { proof, args, account } = await controller.reward({
        account: new Account(),
        note,
        publicKey: firstHardhatPublicKey,
      })

      const tmp = await controller.reward({
        account: new Account(),
        note: note2,
        publicKey: firstHardhatPublicKey,
      })
      await minerReward(tmp.proof, tmp.args)

      await expect(minerReward(proof, args)).to.be.revertedWith('Outdated account merkle root')

      const update = await controller.treeUpdate(account.commitment)
      const malformedArgs = JSON.parse(JSON.stringify(update.args))

      let fakeIndex = toBN(update.args.pathIndices).sub(toBN('1'))
      malformedArgs.pathIndices = toFixedHex(fakeIndex)

      await expect(minerReward4(proof, args, update.proof, malformedArgs)).to.be.revertedWith(
        'Incorrect account insert index',
      )
    })

    it('should reject for invalid tree update proof (treeUpdate proof validation)', async () => {
      const { deployer, instances } = await setup()
      const { note, controller, minerReward4, minerReward, note2, note3 } = await pre({ deployer, instances })

      const { proof, args, account } = await controller.reward({
        account: new Account(),
        note,
        publicKey: firstHardhatPublicKey,
      })

      const tmp = await controller.reward({
        account: new Account(),
        note: note2,
        publicKey: firstHardhatPublicKey,
      })
      await minerReward(tmp.proof, tmp.args)

      await expect(minerReward(proof, args)).to.be.revertedWith('Outdated account merkle root')

      const update = await controller.treeUpdate(account.commitment)

      await expect(minerReward4(proof, args, tmp.proof, update.args)).to.be.revertedWith(
        'Invalid tree update proof',
      )
    })
  })

  describe('withdraw', () => {
    const preWithdraw = async ({
      deployer,
      instances,
    }: Pick<PreFunctionParameter, 'deployer' | 'instances'>) => {
      const outerPreResponse = await pre({ deployer, instances })

      const {
        proof,
        args,
        account: newAccount,
      } = await outerPreResponse.controller.reward({
        account: new Account(),
        note: outerPreResponse.note,
        publicKey: firstHardhatPublicKey,
      })

      await outerPreResponse.minerReward(proof, args)

      return {
        ...outerPreResponse,
        proof,
        args,
        account: newAccount,
        recipient: deployer.address,
      }
    }
    it('should work', async function () {
      const { deployer, instances } = await setup()
      const { controller, minerReward, note, note2, note3, account, recipient } = await preWithdraw({
        deployer,
        instances,
      })

      const apAmount = account.amount

      expect(await deployer['Miner'].accountNullifiers(toFixedHex(account.nullifierHash))).to.equal(false)

      const withdrawSnark = await controller.withdraw({
        account,
        amount: apAmount.toString(),
        recipient,
        publicKey: firstHardhatPublicKey,
      })

      const balanceBefore = await deployer['PGAP'].balanceOf(recipient)

      await deployer['Miner'][
        'withdraw(bytes,(uint256,bytes32,(uint256,address,address,bytes),(bytes32,bytes32,bytes32,uint256,bytes32)))'
      ](withdrawSnark.proof, withdrawSnark.args)

      const balanceAfter = await deployer['PGAP'].balanceOf(recipient)

      expect(balanceBefore).to.equal(0)
      expect(balanceAfter).to.equal(apAmount)
    })
    it('should fail for double spend', async function () {
      const { deployer, instances } = await setup()
      const { controller, minerReward, note, note2, note3, account, recipient } = await preWithdraw({
        deployer,
        instances,
      })

      const apAmount = account.amount

      expect(await deployer['Miner'].accountNullifiers(toFixedHex(account.nullifierHash))).to.equal(false)

      const withdrawSnark = await controller.withdraw({
        account,
        amount: apAmount.toString(),
        recipient,
        publicKey: firstHardhatPublicKey,
      })

      await deployer['Miner'][
        'withdraw(bytes,(uint256,bytes32,(uint256,address,address,bytes),(bytes32,bytes32,bytes32,uint256,bytes32)))'
      ](withdrawSnark.proof, withdrawSnark.args)

      const balanceAfter = await deployer['PGAP'].balanceOf(recipient)

      expect(balanceAfter).to.equal(apAmount)

      await expect(
        deployer['Miner'][
          'withdraw(bytes,(uint256,bytes32,(uint256,address,address,bytes),(bytes32,bytes32,bytes32,uint256,bytes32)))'
        ](withdrawSnark.proof, withdrawSnark.args),
      ).to.be.revertedWith('Outdated account state')
    })

    it('should fail for invalid amount', async function () {
      const { deployer, instances } = await setup()
      const { controller, minerReward, note, note2, note3, account, recipient } = await preWithdraw({
        deployer,
        instances,
      })

      const apAmount = account.amount

      const withdrawSnark = await controller.withdraw({
        account,
        amount: apAmount.toString(),
        recipient,
        publicKey: firstHardhatPublicKey,
      })

      const malformedArgs = JSON.parse(JSON.stringify(withdrawSnark.args))
      malformedArgs.amount = toFixedHex(toBN(2).pow(toBN(248)))

      await expect(
        deployer['Miner'][
          'withdraw(bytes,(uint256,bytes32,(uint256,address,address,bytes),(bytes32,bytes32,bytes32,uint256,bytes32)))'
        ](withdrawSnark.proof, malformedArgs),
      ).to.be.revertedWith('Amount value out of range')

      const balanceAfter = await deployer['PGAP'].balanceOf(recipient)

      expect(balanceAfter).to.equal(0)
    })
  })
})
