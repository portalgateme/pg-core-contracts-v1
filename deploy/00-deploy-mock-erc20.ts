import { DeployFunction } from 'hardhat-deploy/dist/types'
import { HardhatRuntimeEnvironment } from 'hardhat/types'
import { network } from 'hardhat'
import { DeployTags, onlyLocalNetwork, baseDeployOptions } from '../utils/deploy'

const deployInstanceMockERC20: DeployFunction = async ({
  deployments,
  getNamedAccounts,
}: HardhatRuntimeEnvironment) => {
  const { deploy } = deployments
  const { deployer } = await getNamedAccounts()
  const chainId = network.config.chainId!

  onlyLocalNetwork(chainId)

  await deploy('InstanceMockERC20', {
    from: deployer,
    args: [],
    ...baseDeployOptions(chainId),
  })
}

export default deployInstanceMockERC20

deployInstanceMockERC20.tags = [DeployTags.TEST, DeployTags.MockERC20]
