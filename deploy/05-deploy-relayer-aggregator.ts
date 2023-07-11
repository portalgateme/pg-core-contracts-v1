import { DeployFunction } from 'hardhat-deploy/dist/types'
import { HardhatRuntimeEnvironment } from 'hardhat/types'
import { network } from 'hardhat'
import { baseDeployOptions, DeployTags } from '../utils/deploy'

const deployRelayerAggregator: DeployFunction = async ({
  deployments,
  getNamedAccounts,
}: HardhatRuntimeEnvironment) => {
  const { deploy } = deployments
  const { deployer } = await getNamedAccounts()
  const chainId = network.config.chainId!

  const relayerRegistry = await deployments.get('RelayerRegistry')

  await deploy('RelayerAggregator', {
    from: deployer,
    args: [relayerRegistry.address],
    ...baseDeployOptions(chainId),
  })
}

export default deployRelayerAggregator

deployRelayerAggregator.tags = [DeployTags.TEST, DeployTags.STAGE, DeployTags.RelayerAggregator]
