import { BigNumber, utils } from 'ethers'
import { randomBytes } from 'crypto'
import { pedersenHashBuffer, poseidonHash } from '../utils'

function randomBN(size: number): BigNumber {
  const buf = randomBytes(size)
  return BigNumber.from(`0x${buf.toString('hex')}`)
}

export interface INoteConstructor {
  secret?: BigNumber
  nullifier?: BigNumber
  netId?: string
  amount?: string
  currency?: string
  depositBlock?: string | number | BigNumber
  withdrawalBlock?: string | number | BigNumber
  instance?: any
}

class Note {
  public secret: BigNumber
  public nullifier: BigNumber
  public commitment: BigNumber
  public nullifierHash: BigNumber
  public rewardNullifier: BigNumber
  public netId: string
  public amount: string
  public currency: string
  public depositBlock: BigNumber
  public withdrawalBlock: BigNumber
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
    this.secret = secret ? BigNumber.from(secret) : randomBN(31)
    this.nullifier = nullifier ? BigNumber.from(nullifier) : randomBN(31)

    const nullifierBytes = utils.hexDataSlice(this.nullifier.toHexString(), 2)
    const secretBytes = utils.hexDataSlice(this.secret.toHexString(), 2)

    this.commitment = pedersenHashBuffer(
      Buffer.concat([
        Buffer.from(utils.hexZeroPad(nullifierBytes, 31)),
        Buffer.from(utils.hexZeroPad(secretBytes, 31)),
      ]),
    )
    this.nullifierHash = pedersenHashBuffer(Buffer.from(utils.hexZeroPad(nullifierBytes, 31)))
    this.rewardNullifier = poseidonHash([this.nullifier.toHexString()])

    this.netId = netId || ''
    this.amount = amount || ''
    this.currency = currency || ''
    this.depositBlock = BigNumber.from(depositBlock || 0)
    this.withdrawalBlock = BigNumber.from(withdrawalBlock || 0)
    this.instance = instance
  }

  static fromString(
    note: string,
    instance: string,
    depositBlock: string | number,
    withdrawalBlock: string | number,
  ): Note {
    const [, currency, amount, netId, noteHex] = note.split('-')
    const noteBuff = Buffer.from(noteHex.slice(2), 'hex')
    const nullifier = BigNumber.from(`0x${noteBuff.slice(0, 31).toString('hex')}`)
    const secret = BigNumber.from(`0x${noteBuff.slice(31).toString('hex')}`)
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
