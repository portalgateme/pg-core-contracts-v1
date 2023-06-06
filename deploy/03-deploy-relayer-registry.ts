import { DeployFunction } from 'hardhat-deploy/dist/types'
import { HardhatRuntimeEnvironment } from 'hardhat/types'
import { network } from 'hardhat'
import { DeployTags } from './utils/tags.enum'

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
    log: true,
    waitConfirmations: chainId === 31337 ? 1 : 6,
  })
}

export default deployRelayerRegistry

deployRelayerRegistry.tags = [DeployTags.TEST, DeployTags.STAGE, DeployTags.RelayerRegistry]
