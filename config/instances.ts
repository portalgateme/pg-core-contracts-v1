import { InstanceConfig } from './types'
import { BigNumber } from 'ethers'
import { ethers } from 'hardhat'

export default {
  '5': [
    // goerli config
    {
      // address of the token
      token: '0x2f3A40A3db8a7e3D09B0adfEfbCe4f6F81927557',
      // denomination of the token
      // (make sure to check decimals of the token)
      denomination: 100000,
      // is token ERC20
      isERC20: true,
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
      maxDepositAmount: BigNumber.from(100000000),
      // name of the instance
      // used by deploy script
      // ** and SHOULD BE UNIQUE **
      name: `USDC-100000`,
      // name of the currency
      // (token symbol)
      currencyName: 'USDC',
      // height of the merkle tree
      // * 20 - 2^20 leaves
      markleTreeHeight: 20,
      // mining rate
      // (how many tokens will be mined per block)
      // can be null in case if instance has not enabled mining
      // in example below 100 tokens will be mined per block since token has 18 decimals
      miningRate: ethers.BigNumber.from(100).pow(18),
    },
  ],
} as InstanceConfig
