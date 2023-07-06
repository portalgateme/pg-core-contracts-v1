import { InstanceConfig } from './types'
import { BigNumber } from 'ethers'

export default {
  // goerli config
  '5': [
    // USDC
    {
      token: '0x2f3A40A3db8a7e3D09B0adfEfbCe4f6F81927557',
      denomination: 100000,
      isERC20: true,
      state: 1,
      uniswapPoolSwappingFee: 0,
      protocolFeePercentage: 0,
      maxDepositAmount: BigNumber.from('100000000'),
      name: `USDC-100000`,
      currencyName: 'USDC',
    },
  ],
} as InstanceConfig
