import crypto from 'crypto'
import snarkjs from 'snarkjs'
import circomlib from 'circomlib'

export const rbigint = (nbytes: number) => snarkjs.bigInt.leBuff2int(crypto.randomBytes(nbytes))
export const pedersenHash = (data: any) => circomlib.babyJub.unpackPoint(circomlib.pedersenHash.hash(data))[0]
