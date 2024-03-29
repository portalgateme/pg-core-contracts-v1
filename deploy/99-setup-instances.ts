import { DeployFunction } from 'hardhat-deploy/dist/types'
import { HardhatRuntimeEnvironment } from 'hardhat/types'
import { ethers, network } from 'hardhat'
import { DeployTags, isLocalNetwork } from '../utils/deploy'
import instancesConfig from '../config/instances'

const setupInstances: DeployFunction = async ({
  deployments,
  getNamedAccounts,
}: HardhatRuntimeEnvironment) => {
  const chainId = network.config.chainId!

  const { execute } = deployments
  const { deployer } = await getNamedAccounts()

  let instances = []

  if (isLocalNetwork(chainId)) {
    const deployedInstancesNames = ['ERC20Tornado-100', 'ERC20Tornado-1000']
    const deployedInstances = await Promise.all(
      deployedInstancesNames.map((name) => deployments.getOrNull(name)),
    )
    const deployedInstancesAddresses = deployedInstances
      .filter((instance) => instance !== null)
      .map((instance) => instance!.address)

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
    const _instances = instancesConfig[chainId.toString()]

    for await (const instance of _instances) {
      const deployedPoolAddress = instance.poolAddress || (await deployments.get(instance.name)).address

      instances.push({
        addr: deployedPoolAddress,
        instance: {
          isERC20: true,
          state: instance.state,
          token: instance.kycToken,
          uniswapPoolSwappingFee: instance.uniswapPoolSwappingFee,
          protocolFeePercentage: instance.protocolFeePercentage,
          maxDepositAmount: instance.maxDepositAmount.toString(),
        },
      })
    }
  }

  await execute('InstanceRegistry', { from: deployer, log: true }, 'initInstances', instances)
}

export default setupInstances

setupInstances.tags = [DeployTags.TEST, DeployTags.SetupInstances]
