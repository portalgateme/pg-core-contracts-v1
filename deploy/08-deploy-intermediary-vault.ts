import { DeployFunction } from 'hardhat-deploy/dist/types'
import { HardhatRuntimeEnvironment } from 'hardhat/types'
import { network } from 'hardhat'
import { baseDeployOptions, DeployTags, isLocalNetwork, sleep } from '../utils/deploy'

const deployIntermediaryVault: DeployFunction = async ({
  deployments,
  getNamedAccounts,
}: HardhatRuntimeEnvironment) => {
  const { deploy } = deployments
  const { deployer } = await getNamedAccounts()
  const chainId = network.config.chainId!

  const pgRouter = await deployments.get('PGRouter')

  await deploy('IntermediaryVault', {
    from: deployer,
    args: [pgRouter.address],
    ...baseDeployOptions(chainId),
  })
}

export default deployIntermediaryVault

deployIntermediaryVault.tags = [DeployTags.TEST, DeployTags.STAGE, DeployTags.IntermediaryVault]
