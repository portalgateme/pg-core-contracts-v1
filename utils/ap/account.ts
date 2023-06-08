import { BigNumber, utils } from 'ethers'
import { encrypt, decrypt } from 'eth-sig-util'
import { randomBN, poseidonHash } from '../utils'

type AccountParams = {
  amount?: string | BigNumber
  secret?: string | BigNumber
  nullifier?: string | BigNumber
}

class Account {
  amount: BigNumber
  secret: BigNumber
  nullifier: BigNumber
  commitment: BigNumber
  nullifierHash: BigNumber

  constructor({ amount, secret, nullifier }: AccountParams = {}) {
    this.amount = amount ? BigNumber.from(amount) : BigNumber.from('0')
    this.secret = secret ? BigNumber.from(secret) : randomBN()
    this.nullifier = nullifier ? BigNumber.from(nullifier) : randomBN()

    this.commitment = poseidonHash([this.amount, this.secret, this.nullifier])
    this.nullifierHash = poseidonHash([this.nullifier])

    if (this.amount.lt(BigNumber.from(0))) {
      throw new Error('Cannot create an account with negative amount')
    }
  }

  encrypt(pubkey: string): string {
    const bytes = Buffer.concat([
      Buffer.from(this.amount.toBigInt().toString(16), 'hex'),
      Buffer.from(this.secret.toBigInt().toString(16), 'hex'),
      Buffer.from(this.nullifier.toBigInt().toString(16), 'hex'),
    ])
    return encrypt(pubkey, { data: bytes.toString('base64') }, 'x25519-xsalsa20-poly1305')
  }

  static decrypt(privkey: string, data: string): Account {
    const decryptedMessage = decrypt(data, privkey)
    const buf = Buffer.from(decryptedMessage, 'base64')

    return new Account({
      amount: BigNumber.from('0x' + buf.slice(0, 31).toString('hex')),
      secret: BigNumber.from('0x' + buf.slice(31, 62).toString('hex')),
      nullifier: BigNumber.from('0x' + buf.slice(62, 93).toString('hex')),
    })
  }
}

export default Account
