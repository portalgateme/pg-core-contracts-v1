import { DeployFunction } from 'hardhat-deploy/dist/types'
import { HardhatRuntimeEnvironment } from 'hardhat/types'
import { ethers, network } from 'hardhat'
import { DeployTags, isLocalNetwork } from '../utils/deploy'
import { BigNumber } from 'ethers'

const setupInstances: DeployFunction = async ({
  deployments,
  getNamedAccounts,
}: HardhatRuntimeEnvironment) => {
  const chainId = network.config.chainId!

  const { execute } = deployments
  const { deployer } = await getNamedAccounts()

  let instances = []

  if (isLocalNetwork(chainId)) {
    const instanceRegistry = await deployments.get('InstanceRegistry')
    const deployedInstancesNames = ['ERC20Tornado-100', 'ERC20Tornado-1000']
    const deployedInstances = await Promise.all(
      deployedInstancesNames.map((name) => deployments.getOrNull(name)),
    )
    const deployedInstancesAddresses = deployedInstances
      .filter((instance) => instance !== null)
      .map((instance) => instance!.address)

    const InstanceRegistry = await ethers.getContractAt('InstanceRegistry', instanceRegistry.address)

    const instanceMockERC20 = await deployments.get('InstanceMockERC20')

    instances = deployedInstancesAddresses.map((addr, index) => {
      return {
        addr,
        instance: {
          isERC20: true,
          token: instanceMockERC20.address,
          state: 1,
          uniswapPoolSwappingFee: 0,
          protocolFeePercentage: 0,
          maxDepositAmount: 100000,
        },
      }
    })
  } else {
    instances = [
      {
        addr: '0x34317E92C6AFFF78865aC68CAE7BE415c55fA09b',
        instance: {
          isERC20: true,
          token: '0xaF21bf4CaD882a01ee94399932d359EDA4f2b960',
          state: 1,
          uniswapPoolSwappingFee: 0,
          protocolFeePercentage: 0,
          maxDepositAmount: BigNumber.from('10000').pow('18'),
        },
      },
      {
        addr: '0x1f5c4316aED284F8348a2663BAef4EE35b308E51',
        instance: {
          isERC20: true,
          token: '0x5DEFB82285503d613D5Bf191B28B6d59EA67142f',
          state: 1,
          uniswapPoolSwappingFee: 0,
          protocolFeePercentage: 0,
          maxDepositAmount: BigNumber.from('100000000000'),
        },
      },
    ]
  }

  await execute('InstanceRegistry', { from: deployer, log: true }, 'initInstances', instances)
}

export default setupInstances

setupInstances.tags = [DeployTags.TEST, DeployTags.SetupInstances]
