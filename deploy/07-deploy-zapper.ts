import { DeployFunction } from 'hardhat-deploy/dist/types'
import { HardhatRuntimeEnvironment } from 'hardhat/types'
import { network } from 'hardhat'
import { baseDeployOptions, DeployTags } from '../utils/deploy'

const deployZapper: DeployFunction = async ({ deployments, getNamedAccounts }: HardhatRuntimeEnvironment) => {
  const { deploy } = deployments
  const { deployer } = await getNamedAccounts()
  const chainId = network.config.chainId!

  const pgRouter = await deployments.get('PGRouter')
  const instanceRegistry = await deployments.get('InstanceRegistry')

  await deploy('Zapper', {
    from: deployer,
    args: [pgRouter.address, instanceRegistry.address],
    ...baseDeployOptions(chainId),
  })
}

export default deployZapper

deployZapper.tags = [DeployTags.TEST, DeployTags.STAGE, DeployTags.Zapper]
