import { DeployFunction } from 'hardhat-deploy/dist/types'
import { HardhatRuntimeEnvironment } from 'hardhat/types'
import { ethers, network } from 'hardhat'
import { DeployTags } from '../types/tags.enum'

const deployPGRouter: DeployFunction = async ({
  deployments,
  getNamedAccounts,
}: HardhatRuntimeEnvironment) => {
  const { deploy } = deployments
  const { deployer } = await getNamedAccounts()
  const chainId = network.config.chainId!

  const InstanceRegistry = await deployments.get('InstanceRegistry')
  const RelayerRegistry = await deployments.get('RelayerRegistry')

  const pgRouter = await deploy('PGRouter', {
    from: deployer,
    args: [deployer, InstanceRegistry.address, RelayerRegistry.address],
    log: true,
    waitConfirmations: chainId === 31337 ? 1 : 6,
  })

  const instanceRegistryContract = await ethers.getContract('InstanceRegistry', deployer)
  await instanceRegistryContract.setPGRouter(pgRouter.address)
}

export default deployPGRouter

deployPGRouter.tags = [DeployTags.TEST, DeployTags.STAGE, DeployTags.RelayerAggregator]
