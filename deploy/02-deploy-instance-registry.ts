import { DeployFunction } from 'hardhat-deploy/dist/types'
import { HardhatRuntimeEnvironment } from 'hardhat/types'
import { network } from 'hardhat'
import { baseDeployOptions, DeployTags } from '../utils/deploy'

const deployInstanceRegistry: DeployFunction = async ({
  deployments,
  getNamedAccounts,
}: HardhatRuntimeEnvironment) => {
  const { deploy } = deployments
  const { deployer } = await getNamedAccounts()
  const chainId = network.config.chainId!

  await deploy('InstanceRegistry', {
    from: deployer,
    args: [deployer],
    gasLimit: 5000000,
    ...baseDeployOptions(chainId),
  })
}

export default deployInstanceRegistry

deployInstanceRegistry.tags = [DeployTags.TEST, DeployTags.STAGE, DeployTags.InstanceRegistry]
