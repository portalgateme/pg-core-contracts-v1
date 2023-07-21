import { BigNumber } from 'ethers'

export type Address = `0x${string}`

export type InstanceState = 0 | 1 | 2

export interface BaseInstanceConfigItem {
  token: Address | null
  kycToken?: Address
  denomination: BigNumber
  state: InstanceState
  uniswapPoolSwappingFee: number
  protocolFeePercentage: number
  maxDepositAmount: BigNumber
  name: string
  markleTreeHeight?: number
  currencyName: string
  miningRate: BigNumber | null
  isERC20: boolean
  poolAddress?: Address
}

export interface InstanceConfig {
  [chainId: string]: BaseInstanceConfigItem[]
}

/** Keyring config */

interface KeyringConfigItem {
  ruleRegistry: Address
  policyManager: Address
  identityTree: Address
  walletCheck: Address
  forwarder: Address
  keyringCredentials: Address
  userPolicies: Address
  exemptionsManager: Address
}

export interface KeyringConfig {
  [chainId: string]: KeyringConfigItem
}

export interface BaseKeyringTokenConstructorConfig {
  trustedForwarder: Address
  keyringCredentials: Address
  policyManager: Address
  userPolicies: Address
  exemptionsManager: Address
}

export interface ERC20KeyringTokenConstructorConfig extends BaseKeyringTokenConstructorConfig {
  collateralToken: Address
}

export interface ETHKeyringTokenConstructorConfig extends BaseKeyringTokenConstructorConfig {}
