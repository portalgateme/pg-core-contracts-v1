export function onlyLocalNetwork(chainId: number) {
  if (chainId != 31337) {
    throw new Error('This script should only be used on local network')
  }
}
