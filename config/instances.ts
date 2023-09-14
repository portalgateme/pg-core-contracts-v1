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
      kycToken: '0x',
      // denomination of the token
      // (make sure to check decimals of the token)
      denomination: BigNumber.from(100000).mul(BigNumber.from(10).pow(6)),
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
      maxDepositAmount: BigNumber.from(10000000).mul(BigNumber.from(10).pow(6)),
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
      miningRate: BigNumber.from(100).mul(BigNumber.from(10).pow(6)),
      // is token ERC20
      isERC20: true,
      // poolAddress: '0xe6419fE674Dc53BB6cC19460A6f229b72db9Ac40',
    },
    {
      // address of the token
      token: '0x3d3d561f40A925acB252Df8420eCba2b6Ba1Af89',
      kycToken: '',
      denomination: BigNumber.from(100).mul(BigNumber.from(10).pow(6)),
      state: 1,
      uniswapPoolSwappingFee: 0,
      protocolFeePercentage: 0,
      maxDepositAmount: BigNumber.from(100000).mul(BigNumber.from(10).pow(6)),
      name: `kycUSDT-100`,
      currencyName: 'kycUSDT',
      markleTreeHeight: 20,
      miningRate: BigNumber.from(1).mul(BigNumber.from(10).pow(5)),
      isERC20: true,
    },
    {
      // address of the token
      token: null,
      kycToken: '0xED47B26eD9137c41Ba89936E62A51cD2cc6Ece80',
      denomination: BigNumber.from(1).mul(BigNumber.from(10).pow(16)),
      state: 1,
      uniswapPoolSwappingFee: 0,
      protocolFeePercentage: 0,
      maxDepositAmount: BigNumber.from(100).mul(BigNumber.from(10).pow(18)),
      name: 'kycETH-0.01',
      currencyName: 'kycETH',
      markleTreeHeight: 20,
      isERC20: false,
    },
  ],
} as InstanceConfig
