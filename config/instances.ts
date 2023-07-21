import { InstanceConfig } from './types'
import { BigNumber } from 'ethers'
import { ethers } from 'hardhat'

export default {
  '5': [
    // goerli config
    {
      // address of the token
      token: '0xbB0E2855Ac05d26Bd9E567B8b50c98EF2b889Ad2',
      // address of kyced token
      kycToken: '0xc8079E6AA1d7785dC57AfC178211314164B5B138',
      // denomination of the token
      // (make sure to check decimals of the token)
      denomination: BigNumber.from(100000).pow(6),
      // state of the instance
      // * 0 - instance disabled,
      // * 1 - instance enabled,
      // * 2 - instance enabled and mining enabled
      state: 1,
      // fee for swapping tokens in the pool
      uniswapPoolSwappingFee: 0,
      // fee for the protocol
      protocolFeePercentage: 0,
      // max deposit amount
      // (make sure to check decimals of the token)
      maxDepositAmount: BigNumber.from(1000000000).pow(6),
      // name of the instance
      // used by deploy script
      // ** and SHOULD BE UNIQUE **
      name: `kycUSDC-100000`,
      // name of the currency
      // (token symbol)
      currencyName: 'kycUSDC',
      // height of the merkle tree
      // * 20 - 2^20 leaves
      markleTreeHeight: 20,
      // mining rate
      // (how many tokens will be mined per block)
      // can be null in case if instance has not enabled mining
      // in example below 100 tokens will be mined per block since token has 18 decimals
      miningRate: ethers.BigNumber.from(100).pow(18),
      // is token ERC20
      isERC20: true,
      // poolAddress: '0xe6419fE674Dc53BB6cC19460A6f229b72db9Ac40',
    },
  ],
} as InstanceConfig
