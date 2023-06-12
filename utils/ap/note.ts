import { BigNumber, utils } from 'ethers'
import { randomBytes } from 'crypto'
import { pedersenHashBuffer, poseidonHash, randomBN } from '../utils'
import { BN } from 'ethereumjs-util'
import { toBN } from 'web3-utils'

export interface INoteConstructor {
  secret?: string
  nullifier?: string
  netId?: string
  amount?: string
  currency?: string
  depositBlock?: number
  withdrawalBlock?: number
  instance?: any
}

class Note {
  public secret: BN
  public nullifier: BN
  public commitment: BN
  public nullifierHash: BN
  public rewardNullifier: BN
  public netId: string
  public amount: string
  public currency: string
  public depositBlock: BN
  public withdrawalBlock: BN
  public instance: any

  constructor({
    secret,
    nullifier,
    netId,
    amount,
    currency,
    depositBlock,
    withdrawalBlock,
    instance,
  }: INoteConstructor = {}) {
    this.secret = secret ? toBN(secret) : randomBN(31)
    this.nullifier = nullifier ? toBN(nullifier) : randomBN(31)

    this.commitment = pedersenHashBuffer(
      Buffer.concat([this.nullifier.toBuffer('le', 31), this.secret.toBuffer('le', 31)]),
    )
    this.nullifierHash = pedersenHashBuffer(this.nullifier.toBuffer('le', 31))
    this.rewardNullifier = poseidonHash([this.nullifier])

    this.netId = netId
    this.amount = amount
    this.currency = currency
    this.depositBlock = toBN(depositBlock)
    this.withdrawalBlock = toBN(withdrawalBlock)
    this.instance = instance
  }

  static fromString(note, instance, depositBlock, withdrawalBlock) {
    note = note.split('-')
    const [, currency, amount, netId] = note
    const hexNote = note[4].slice(2)
    const nullifier = new BN(hexNote.slice(0, 62), 16, 'le')
    const secret = new BN(hexNote.slice(62), 16, 'le')
    return new Note({
      secret,
      nullifier,
      netId,
      amount,
      currency,
      depositBlock,
      withdrawalBlock,
      instance,
    })
  }
}

export default Note
