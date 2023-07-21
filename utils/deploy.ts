import { DeployOptions } from 'hardhat-deploy/dist/types'

export function isLocalNetwork(chainId: number) {
  return chainId == 31337
}

export const baseDeployOptions = (chainId: number): Partial<DeployOptions> => ({
  autoMine: true,
  waitConfirmations: isLocalNetwork(chainId) ? 1 : 6,
  log: true,
})

export function onlyLocalNetwork(chainId: number) {
  if (!isLocalNetwork(chainId)) {
    throw new Error('This script should only be used on local network')
  }
}

export function sleep(ms: number) {
  return new Promise((resolve) => setTimeout(resolve, ms))
}

export enum DeployTags {
  TEST = 'test',
  STAGE = 'stage',

  RelayerRegistry = 'relayer-registry',
  RelayerAggregator = 'relayer-aggregator',
  PGRouter = 'pg-router',
  InstanceRegistry = 'instance-registry',
  TornadoInstance = 'tornado-instance',
  Zapper = 'zapper',
  IntermediaryVault = 'intermediary-vault',
  RewardSwap = 'reward-swap',
  APToken = 'ap-token',
  Echoer = 'echoer',
  TornadoTrees = 'tornado-trees',
  Miner = 'miner',

  Hashers = 'hashers',
  KycTokens = 'kyc-tokens',

  MockERC20 = 'mock-erc20',
  KeyringDependency = 'keyring-dependency',

  SetupInstances = 'setup-instances',
}
