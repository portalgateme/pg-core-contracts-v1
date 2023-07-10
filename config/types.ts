import { BigNumber } from 'ethers'

export type Address = `0x${string}`

export type InstanceDenomination = 100 | 1000 | 10000 | 100000 | 1000000
export type InstanceState = 0 | 1 | 2

interface BaseInstanceConfigItem {
  denomination: InstanceDenomination
  isERC20: boolean
  state: InstanceState
  uniswapPoolSwappingFee: number
  protocolFeePercentage: number
  maxDepositAmount: BigNumber
  name: string
  markleTreeHeight?: number
  currencyName: string
  miningRate: BigNumber | null
}

export interface ERC20InstanceConfigItem extends BaseInstanceConfigItem {
  isERC20: true
  token: Address
}

export interface NonERC20InstanceConfigItem extends BaseInstanceConfigItem {
  isERC20: false
}

export type InstanceConfigItem = ERC20InstanceConfigItem | NonERC20InstanceConfigItem

export interface InstanceConfig {
  [chainId: string]: InstanceConfigItem[]
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
