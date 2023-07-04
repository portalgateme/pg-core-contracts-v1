import { ERC20Tornado, ETHTornado } from '../generated-types/ethers'
import { ZERO_ADDRESS } from '../utils/constants'
import { BigNumber } from 'ethers'

type ETHDenomination = '0.1' | '1' | '10' | '100'
type ERC20Denomination = '10' | '100' | '1000' | '10000'

export type Denomination = ETHDenomination | ERC20Denomination

export interface DeployedInstance {
  isErc20: boolean
  denomination: Denomination
  markleTreeHeight: number
  tokenAddr?: string
  deployedInstance: ETHTornado | ERC20Tornado
}

export function formatToContractInput(
  deployed: DeployedInstance[],
  uniswapPoolSwappingFee: number,
  protocolFeePercentage: number,
  maxDepositAmount: number | BigNumber,
) {
  return deployed.map((inst) => {
    return {
      addr: inst.deployedInstance.address,
      instance: {
        isERC20: inst.isErc20,
        token: inst.tokenAddr || ZERO_ADDRESS,
        state: 1,
        uniswapPoolSwappingFee,
        protocolFeePercentage,
        maxDepositAmount,
      },
    }
  })
}
