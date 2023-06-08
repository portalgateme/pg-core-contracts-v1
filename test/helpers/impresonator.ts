import { ethers, network } from 'hardhat'

export async function impresonate(address: string) {
  await network.provider.request({
    method: 'hardhat_impersonateAccount',
    params: [address],
  })

  await network.provider.request({
    method: 'hardhat_setBalance',
    params: [address, '0x100000000000000000000'],
  })

  return ethers.provider.getSigner(address)
}

export async function deimpresonate(address: string) {
  await network.provider.request({
    method: 'hardhat_stopImpersonatingAccount',
    params: [address],
  })
}
