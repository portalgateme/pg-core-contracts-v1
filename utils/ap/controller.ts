import { BigNumber, Contract, utils } from 'ethers'
// @ts-ignore
import MerkleTree from 'fixed-merkle-tree'
// @ts-ignore
import * as websnarkUtils from 'websnark/src/utils'
// @ts-ignore
import buildGroth16 from 'websnark/src/groth16'
import Web3 from 'web3'
import { bitsToNumber, getExtRewardArgsHash, getExtWithdrawArgsHash, packEncryptedMessage } from './utils'
import { toFixedHex, poseidonHash, poseidonHash2, ethersBNtoWeb3BN } from '../utils'
import Account from './account'
import { RewardArgs } from './types'
import Note from './note'
import { toBN } from 'web3-utils'
import { BN } from 'ethereumjs-util'

const web3 = new Web3()

interface IControllerOptions {
  contract: Contract
  tornadoTreesContract: Contract
  merkleTreeHeight: string | number
  provingKeys: any
}

class Controller {
  private merkleTreeHeight: number
  private provingKeys: any
  private contract: Contract
  private tornadoTreesContract: Contract
  private groth16: any

  constructor({ contract, tornadoTreesContract, merkleTreeHeight, provingKeys }: IControllerOptions) {
    this.merkleTreeHeight = Number(merkleTreeHeight)
    this.provingKeys = provingKeys
    this.contract = contract
    this.tornadoTreesContract = tornadoTreesContract
    this.groth16 = null
  }

  async init() {
    this.groth16 = await buildGroth16()
  }

  async _fetchAccountCommitments(): Promise<BN[] | null> {
    const filter = this.contract.filters.NewAccount()
    const events = await this.contract.queryFilter(filter)
    return events
      .sort((a, b) => a.args!.index.toNumber() - b.args!.index.toNumber())
      .map((e) => e.args!.commitment)
  }

  private async _fetchDepositDataEvents() {
    return await this._fetchEvents('DepositData')
  }

  private async _fetchWithdrawalDataEvents() {
    return await this._fetchEvents('WithdrawalData')
  }

  private async _fetchEvents(eventName: string) {
    const filter = this.tornadoTreesContract.filters[eventName]()
    const events = await this.tornadoTreesContract.queryFilter(filter)
    return events
      .sort((a, b) => a.args!.index.toNumber() - b.args!.index.toNumber())
      .map((e) => ({
        instance: utils.hexZeroPad(e.args!.instance, 20),
        hash: utils.hexZeroPad(e.args!.hash, 32),
        block: e.args!.block.toNumber(),
        index: e.args!.index.toNumber(),
      }))
  }

  private _updateTree(tree: MerkleTree, element: any) {
    const oldRoot = tree.root()
    tree.insert(element)
    const newRoot = tree.root()
    const { pathElements, pathIndices } = tree.path(tree.elements().length - 1)
    return {
      oldRoot,
      newRoot,
      pathElements,
      pathIndices: bitsToNumber(pathIndices),
    }
  }

  async batchReward({
    account,
    notes,
    publicKey,
    fee = 0,
    relayer = 0,
  }: {
    account: Account
    notes: Note[]
    publicKey: string
    fee?: number
    relayer?: number
  }) {
    const accountCommitments = await this._fetchAccountCommitments()
    let lastAccount = account
    const proofs = []
    for (const note of notes) {
      const proof = await this.reward({
        account: lastAccount,
        note,
        publicKey,
        fee,
        relayer,
        accountCommitments: accountCommitments?.slice(),
      })
      proofs.push(proof)
      lastAccount = proof.account
      accountCommitments?.push(lastAccount.commitment)
    }
    const args = proofs.map((x) => web3.eth.abi.encodeParameters(['bytes', RewardArgs], [x.proof, x.args]))
    return { proofs, args }
  }

  /**
   * Generates proof and args to claim AP (anonymity points) for a note
   * @param {Account} account The account the AP will be added to
   * @param {Note} note The target note
   * @param {String} publicKey ETH public key for the Account encryption
   * @param {Number} fee Fee for the relayer
   * @param {String} relayer Relayer address
   * @param {Number} rate How many AP is generated for the note in block time
   * @param {String[]} accountCommitments An array of account commitments from miner contract
   * @param {String[]} depositDataEvents An array of account commitments from miner contract
   * @param {{instance: String, hash: String, block: Number, index: Number}[]} depositDataEvents An array of deposit objects from tornadoTrees contract. hash = commitment
   * @param {{instance: String, hash: String, block: Number, index: Number}[]} withdrawalDataEvents An array of withdrawal objects from tornadoTrees contract. hash = nullifierHash
   */
  async reward({
    account,
    note,
    publicKey,
    fee = 0,
    relayer = 0,
    accountCommitments = null,
  }: {
    account: Account
    note: Note
    publicKey: string
    fee?: number
    relayer?: number
    rate?: number | null
    accountCommitments?: any
  }) {
    const rate = await this.contract.rates(note.instance)

    const newAmount = account.amount.add(
      toBN(rate)
        // @ts-ignore
        .mul(toBN(note.withdrawalBlock).sub(toBN(note.depositBlock)))
        .sub(toBN(fee)),
    )
    const newAccount = new Account({ amount: newAmount })

    const depositDataEvents = await this._fetchDepositDataEvents()
    const depositLeaves = depositDataEvents.map((x) => poseidonHash([x.instance, x.hash, x.block]))
    const depositTree = new MerkleTree(this.merkleTreeHeight, depositLeaves, { hashFunction: poseidonHash2 })
    const depositItem = depositDataEvents.filter((x) => x.hash === toFixedHex(note.commitment))
    if (depositItem.length === 0) {
      throw new Error('The deposits tree does not contain such note commitment')
    }
    const depositPath = depositTree.path(depositItem[0].index)

    const withdrawalDataEvents = await this._fetchWithdrawalDataEvents()
    const withdrawalLeaves = withdrawalDataEvents.map((x) => poseidonHash([x.instance, x.hash, x.block]))
    const withdrawalTree = new MerkleTree(this.merkleTreeHeight, withdrawalLeaves, {
      hashFunction: poseidonHash2,
    })
    const withdrawalItem = withdrawalDataEvents.filter((x) => x.hash === toFixedHex(note.nullifierHash))
    if (withdrawalItem.length === 0) {
      throw new Error('The withdrawals tree does not contain such note nullifier')
    }
    const withdrawalPath = withdrawalTree.path(withdrawalItem[0].index)

    accountCommitments = accountCommitments || (await this._fetchAccountCommitments())
    const accountTree = new MerkleTree(this.merkleTreeHeight, accountCommitments, {
      hashFunction: poseidonHash2,
    })
    const zeroAccount = {
      pathElements: new Array(this.merkleTreeHeight).fill(0),
      pathIndices: new Array(this.merkleTreeHeight).fill(0),
    }
    const accountIndex = accountTree.indexOf(account.commitment, (a: any, b: any) => a.eq(b))
    const accountPath = accountIndex !== -1 ? accountTree.path(accountIndex) : zeroAccount
    const accountTreeUpdate = this._updateTree(accountTree, newAccount.commitment)

    const encryptedAccount = packEncryptedMessage(newAccount.encrypt(publicKey))
    const extDataHash = getExtRewardArgsHash({ relayer, encryptedAccount })

    const input = {
      rate,
      fee,
      instance: note.instance,
      rewardNullifier: note.rewardNullifier,
      extDataHash,

      noteSecret: note.secret,
      noteNullifier: note.nullifier,

      inputAmount: account.amount,
      inputSecret: account.secret,
      inputNullifier: account.nullifier,
      inputRoot: accountTreeUpdate.oldRoot,
      inputPathElements: accountPath.pathElements,
      inputPathIndices: bitsToNumber(accountPath.pathIndices),
      inputNullifierHash: account.nullifierHash,

      outputAmount: newAccount.amount,
      outputSecret: newAccount.secret,
      outputNullifier: newAccount.nullifier,
      outputRoot: accountTreeUpdate.newRoot,
      outputPathIndices: accountTreeUpdate.pathIndices,
      outputPathElements: accountTreeUpdate.pathElements,
      outputCommitment: newAccount.commitment,

      depositBlock: note.depositBlock,
      depositRoot: depositTree.root(),
      depositPathIndices: bitsToNumber(depositPath.pathIndices),
      depositPathElements: depositPath.pathElements,

      withdrawalBlock: note.withdrawalBlock,
      withdrawalRoot: withdrawalTree.root(),
      withdrawalPathIndices: bitsToNumber(withdrawalPath.pathIndices),
      withdrawalPathElements: withdrawalPath.pathElements,
    }

    const proofData = await websnarkUtils.genWitnessAndProve(
      this.groth16,
      input,
      this.provingKeys.rewardCircuit,
      this.provingKeys.rewardProvingKey,
    )
    const { proof } = websnarkUtils.toSolidityInput(proofData)

    const args = {
      rate: toFixedHex(input.rate),
      fee: toFixedHex(input.fee),
      instance: toFixedHex(input.instance, 20),
      rewardNullifier: toFixedHex(input.rewardNullifier),
      extDataHash: toFixedHex(input.extDataHash),
      depositRoot: toFixedHex(input.depositRoot),
      withdrawalRoot: toFixedHex(input.withdrawalRoot),
      extData: {
        relayer: toFixedHex(relayer, 20),
        encryptedAccount,
      },
      account: {
        inputRoot: toFixedHex(input.inputRoot),
        inputNullifierHash: toFixedHex(input.inputNullifierHash),
        outputRoot: toFixedHex(input.outputRoot),
        outputPathIndices: toFixedHex(input.outputPathIndices),
        outputCommitment: toFixedHex(input.outputCommitment),
      },
    }

    return {
      proof,
      args,
      account: newAccount,
      encryptedAccount,
    }
  }

  async withdraw({
    account,
    amount,
    recipient,
    publicKey,
    fee = 0,
    relayer = 0,
  }: {
    account: Account
    amount: string
    recipient: string
    publicKey: string
    fee?: number
    relayer?: number
  }) {
    const newAmount = account.amount.sub(toBN(amount)).sub(toBN(fee))
    const newAccount = new Account({ amount: newAmount })

    const accountCommitments = await this._fetchAccountCommitments()
    const accountTree = new MerkleTree(this.merkleTreeHeight, accountCommitments, {
      hashFunction: poseidonHash2,
    })
    const accountIndex = accountTree.indexOf(account.commitment, (a: any, b: any) => a.eq(b))
    if (accountIndex === -1) {
      throw new Error('The accounts tree does not contain such account commitment')
    }
    const accountPath = accountTree.path(accountIndex)
    const accountTreeUpdate = this._updateTree(accountTree, newAccount.commitment)

    const encryptedAccount = packEncryptedMessage(newAccount.encrypt(publicKey))
    const extDataHash = getExtWithdrawArgsHash({ fee, recipient, relayer, encryptedAccount })

    const input = {
      amount: toBN(amount).add(toBN(fee)),
      extDataHash,

      inputAmount: account.amount,
      inputSecret: account.secret,
      inputNullifier: account.nullifier,
      inputNullifierHash: account.nullifierHash,
      inputRoot: accountTreeUpdate.oldRoot,
      inputPathIndices: bitsToNumber(accountPath.pathIndices),
      inputPathElements: accountPath.pathElements,

      outputAmount: newAccount.amount,
      outputSecret: newAccount.secret,
      outputNullifier: newAccount.nullifier,
      outputRoot: accountTreeUpdate.newRoot,
      outputPathIndices: accountTreeUpdate.pathIndices,
      outputPathElements: accountTreeUpdate.pathElements,
      outputCommitment: newAccount.commitment,
    }

    const proofData = await websnarkUtils.genWitnessAndProve(
      this.groth16,
      input,
      this.provingKeys.withdrawCircuit,
      this.provingKeys.withdrawProvingKey,
    )
    const { proof } = websnarkUtils.toSolidityInput(proofData)

    const args = {
      amount: toFixedHex(input.amount),
      extDataHash: toFixedHex(input.extDataHash),
      extData: {
        fee: toFixedHex(fee),
        recipient: toFixedHex(recipient, 20),
        relayer: toFixedHex(relayer, 20),
        encryptedAccount,
      },
      account: {
        inputRoot: toFixedHex(input.inputRoot),
        inputNullifierHash: toFixedHex(input.inputNullifierHash),
        outputRoot: toFixedHex(input.outputRoot),
        outputPathIndices: toFixedHex(input.outputPathIndices),
        outputCommitment: toFixedHex(input.outputCommitment),
      },
    }

    return {
      proof,
      args,
      account: newAccount,
    }
  }

  async treeUpdate(commitment: BN, accountTree = null) {
    if (!accountTree) {
      const accountCommitments = await this._fetchAccountCommitments()
      accountTree = new MerkleTree(this.merkleTreeHeight, accountCommitments, {
        hashFunction: poseidonHash2,
      })
    }
    const accountTreeUpdate = this._updateTree(accountTree, commitment)

    const input = {
      oldRoot: accountTreeUpdate.oldRoot,
      newRoot: accountTreeUpdate.newRoot,
      leaf: commitment,
      pathIndices: accountTreeUpdate.pathIndices,
      pathElements: accountTreeUpdate.pathElements,
    }

    const proofData = await websnarkUtils.genWitnessAndProve(
      this.groth16,
      input,
      this.provingKeys.treeUpdateCircuit,
      this.provingKeys.treeUpdateProvingKey,
    )
    const { proof } = websnarkUtils.toSolidityInput(proofData)

    const args = {
      oldRoot: toFixedHex(input.oldRoot),
      newRoot: toFixedHex(input.newRoot),
      leaf: toFixedHex(input.leaf),
      pathIndices: toFixedHex(input.pathIndices),
    }

    return {
      proof,
      args,
    }
  }
}

export default Controller
