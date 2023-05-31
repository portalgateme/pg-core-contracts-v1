import { DeployFunction } from 'hardhat-deploy/dist/types'
import { HardhatRuntimeEnvironment } from 'hardhat/types'
import { network } from 'hardhat'
import { DeployTags } from '../types/tags.enum'

const deployIntermediaryVault: DeployFunction = async ({
  deployments,
  getNamedAccounts,
}: HardhatRuntimeEnvironment) => {
  const { deploy } = deployments
  const { deployer } = await getNamedAccounts()
  const chainId = network.config.chainId!

  const PGRouter = await deployments.get('PGRouter')

  await deploy('IntermediaryVault', {
    from: deployer,
    args: [PGRouter.address],
    log: true,
    waitConfirmations: chainId === 31337 ? 1 : 6,
  })
}

export default deployIntermediaryVault

deployIntermediaryVault.tags = [DeployTags.TEST, DeployTags.STAGE, DeployTags.IntermediaryVault]
