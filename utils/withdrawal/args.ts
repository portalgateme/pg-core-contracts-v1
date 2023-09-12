import Web3 from 'web3'
import { soliditySha3 } from 'web3-utils'
import { pedersenHashBuffer, toFixedHex } from '../utils'
import { rbigint } from './utils'

const web3 = new Web3()

const WithdrawAssetExtData = {
  WithdrawAssetExtData: {
    recipient: 'address',
    relayer: 'address',
    fee: 'uint256',
    refund: 'uint256',
  },
}
export function getExtWithdrawAssetArgsHash({
  recipient,
  relayer,
  fee,
  refund,
}: {
  recipient: string
  relayer: string
  fee: number
  refund: number
}) {
  const encodedData = web3.eth.abi.encodeParameters(
    [WithdrawAssetExtData],
    [
      {
        recipient: toFixedHex(recipient, 20),
        relayer: toFixedHex(relayer, 20),
        fee: toFixedHex(fee, 32),
        refund: toFixedHex(refund, 32),
      },
    ],
  )
  const hash = soliditySha3({ t: 'bytes', v: encodedData })
  return '0x00' + hash!.slice(4)
}

export function generateDepositArgs() {
  let deposit = {
    secret: rbigint(31),
    nullifier: rbigint(31),
    commitment: rbigint(31),
  }
  const preimage = Buffer.concat([deposit.nullifier.leInt2Buff(31), deposit.secret.leInt2Buff(31)])
  deposit.commitment = pedersenHashBuffer(preimage)
  return deposit
}
