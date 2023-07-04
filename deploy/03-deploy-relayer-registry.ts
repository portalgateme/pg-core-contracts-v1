import { DeployFunction } from 'hardhat-deploy/dist/types'
import { HardhatRuntimeEnvironment } from 'hardhat/types'
import { network } from 'hardhat'
import { DeployTags, baseDeployOptions } from '../utils/deploy'

const deployRelayerRegistry: DeployFunction = async ({
  deployments,
  getNamedAccounts,
}: HardhatRuntimeEnvironment) => {
  const { deploy } = deployments
  const { deployer } = await getNamedAccounts()
  const chainId = network.config.chainId!

  await deploy('RelayerRegistry', {
    from: deployer,
    args: [],
    ...baseDeployOptions(chainId),
  })
}

export default deployRelayerRegistry

deployRelayerRegistry.tags = [DeployTags.TEST, DeployTags.STAGE, DeployTags.RelayerRegistry]
