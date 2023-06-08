// @ts-ignore
import { poseidon, unpackPoint, babyJub, pedersenHash } from 'circomlib'
// @ts-ignore
import { bigInt } from 'snarkjs'
// @ts-ignore
import { getEncryptionPublicKey } from 'eth-sig-util'
import { BigNumber, utils } from 'ethers'

export const poseidonHash = (items: any) => BigNumber.from(poseidon(items).toString())

export const pedersenHashBuffer = (buffer: Buffer): BigNumber =>
  BigNumber.from(babyJub.unpackPoint(pedersenHash.hash(buffer))[0].toString())

export const poseidonHash2 = (a: any, b: any) => poseidonHash([a, b])

export const toFixedHex = (number: any, length = 32) =>
  '0x' +
  (number instanceof Buffer ? number.toString('hex') : bigInt(number).toString(16)).padStart(length * 2, '0')

export const randomBN = (nBytes = 32) => BigNumber.from(utils.randomBytes(nBytes)).abs()

export const getPubKey = getEncryptionPublicKey
