import { RewardExtData, WithdrawExtData } from './types'
import { toFixedHex } from '../utils'
import { soliditySha3, toBN } from 'web3-utils'
import Web3 from 'web3'
import Decimal from 'decimal.js'

import { babyJub, pedersenHash, mimcsponge, poseidon } from 'circomlib'
import { BigNumber } from 'ethers'

const web3 = new Web3()

export function getExtRewardArgsHash({ relayer, encryptedAccount }) {
  const encodedData = web3.eth.abi.encodeParameters(
    [RewardExtData],
    [{ relayer: toFixedHex(relayer, 20), encryptedAccount }],
  )
  const hash = soliditySha3({ t: 'bytes', v: encodedData })
  return '0x00' + hash.slice(4) // cut last byte to make it 31 byte long to fit the snark field
}

export function getExtWithdrawArgsHash({ fee, recipient, relayer, encryptedAccount }) {
  const encodedData = web3.eth.abi.encodeParameters(
    [WithdrawExtData],
    [
      {
        fee: toFixedHex(fee, 32),
        recipient: toFixedHex(recipient, 20),
        relayer: toFixedHex(relayer, 20),
        encryptedAccount,
      },
    ],
  )
  const hash = soliditySha3({ t: 'bytes', v: encodedData })
  return '0x00' + hash.slice(4) // cut first byte to make it 31 byte long to fit the snark field
}

export function packEncryptedMessage(encryptedMessage) {
  const nonceBuf = Buffer.from(encryptedMessage.nonce, 'base64')
  const ephemPublicKeyBuf = Buffer.from(encryptedMessage.ephemPublicKey, 'base64')
  const ciphertextBuf = Buffer.from(encryptedMessage.ciphertext, 'base64')
  const messageBuff = Buffer.concat([
    Buffer.alloc(24 - nonceBuf.length),
    nonceBuf,
    Buffer.alloc(32 - ephemPublicKeyBuf.length),
    ephemPublicKeyBuf,
    ciphertextBuf,
  ])
  return '0x' + messageBuff.toString('hex')
}

export function unpackEncryptedMessage(encryptedMessage) {
  if (encryptedMessage.slice(0, 2) === '0x') {
    encryptedMessage = encryptedMessage.slice(2)
  }
  const messageBuff = Buffer.from(encryptedMessage, 'hex')
  const nonceBuf = messageBuff.slice(0, 24)
  const ephemPublicKeyBuf = messageBuff.slice(24, 56)
  const ciphertextBuf = messageBuff.slice(56)
  return {
    version: 'x25519-xsalsa20-poly1305',
    nonce: nonceBuf.toString('base64'),
    ephemPublicKey: ephemPublicKeyBuf.toString('base64'),
    ciphertext: ciphertextBuf.toString('base64'),
  }
}

export function bitsToNumber(bits) {
  let result = 0
  for (const item of bits.slice().reverse()) {
    result = (result << 1) + item
  }
  return result
}

// a = floor(10**18 * e^(-0.0000000001 * amount))
// yield = BalBefore - (BalBefore * a)/10**18
export function tornadoFormula({ balance, amount, poolWeight = 1e10 }) {
  const decimals = new Decimal(10 ** 18)
  balance = new Decimal(balance.toString())
  amount = new Decimal(amount.toString())
  poolWeight = new Decimal(poolWeight.toString())

  const power = amount.div(poolWeight).negated()
  const exponent = Decimal.exp(power).mul(decimals)
  const newBalance = balance.mul(exponent).div(decimals)
  return toBN(balance.sub(newBalance).toFixed(0))
}

export function reverseTornadoFormula({ balance, tokens, poolWeight = 1e10 }) {
  balance = new Decimal(balance.toString())
  tokens = new Decimal(tokens.toString())
  poolWeight = new Decimal(poolWeight.toString())

  return toBN(poolWeight.times(Decimal.ln(balance.div(balance.sub(tokens)))).toFixed(0))
}
