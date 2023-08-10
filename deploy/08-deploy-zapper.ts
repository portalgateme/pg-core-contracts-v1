import { DeployFunction } from 'hardhat-deploy/dist/types'
import { HardhatRuntimeEnvironment } from 'hardhat/types'
import { network } from 'hardhat'
import { baseDeployOptions, DeployTags, isLocalNetwork, sleep } from '../utils/deploy'

const deployZapper: DeployFunction = async ({ deployments, getNamedAccounts }: HardhatRuntimeEnvironment) => {
  const { deploy } = deployments
  const { deployer } = await getNamedAccounts()
  const chainId = network.config.chainId!

  const [pgRouter, instanceRegistry] = await Promise.all([
    deployments.get('PGRouter'),
    deployments.get('InstanceRegistry'),
  ])

  await deploy('Zapper', {
    from: deployer,
    args: [pgRouter.address, instanceRegistry.address, deployer],
    ...baseDeployOptions(chainId),
  })
}

export default deployZapper

deployZapper.tags = [DeployTags.TEST, DeployTags.STAGE, DeployTags.Zapper]
