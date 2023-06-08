import { DeployFunction } from 'hardhat-deploy/dist/types'
import { HardhatRuntimeEnvironment } from 'hardhat/types'
import { ethers, network } from 'hardhat'
import { ZERO_ADDRESS } from '../utils/constants'
import { baseDeployOptions, DeployTags } from '../utils/deploy'

const deployPGRouter: DeployFunction = async ({
  deployments,
  getNamedAccounts,
}: HardhatRuntimeEnvironment) => {
  const { deploy } = deployments
  const { deployer } = await getNamedAccounts()
  const chainId = network.config.chainId!

  const instanceRegistry = await deployments.get('InstanceRegistry')
  const relayerRegistry = await deployments.get('RelayerRegistry')

  const pgRouter = await deploy('PGRouter', {
    from: deployer,
    args: [ZERO_ADDRESS, deployer, instanceRegistry.address, relayerRegistry.address],
    ...baseDeployOptions(chainId),
  })

  const InstanceRegistry = await ethers.getContract('InstanceRegistry', deployer)
  await InstanceRegistry.setPGRouter(pgRouter.address)
}

export default deployPGRouter

deployPGRouter.tags = [DeployTags.TEST, DeployTags.STAGE, DeployTags.RelayerAggregator]
