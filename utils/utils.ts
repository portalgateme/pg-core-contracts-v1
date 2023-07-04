// @ts-ignore
import { babyJub, pedersenHash, mimcsponge, poseidon } from 'circomlib'
// @ts-ignore
import { bigInt } from 'snarkjs'
// @ts-ignore
import { getEncryptionPublicKey } from 'eth-sig-util'
import { BigNumber, utils } from 'ethers'
import { toBN, soliditySha3 } from 'web3-utils'
import { randomBytes } from 'crypto'

export const getPubKey = getEncryptionPublicKey

export const ethersBNtoWeb3BN = (bn: BigNumber) => toBN(bn.toString())

export const pedersenHashBuffer = (buffer: Buffer) =>
  toBN(babyJub.unpackPoint(pedersenHash.hash(buffer))[0].toString())

export const poseidonHash = (items: any[]) => toBN(poseidon(items).toString())

export const poseidonHash2 = (a: any, b: any) => poseidonHash([a, b])

/** Generate random number of specified byte length */
export const randomBN = (nbytes = 31) => toBN(bigInt.leBuff2int(randomBytes(nbytes)).toString())

/** BigNumber to hex string of specified length */
export const toFixedHex = (number: any, length = 32) =>
  '0x' +
  (number instanceof Buffer ? number.toString('hex') : bigInt(number).toString(16)).padStart(length * 2, '0')
