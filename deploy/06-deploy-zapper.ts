import { DeployFunction } from 'hardhat-deploy/dist/types'
import { HardhatRuntimeEnvironment } from 'hardhat/types'
import { network } from 'hardhat'
import { DeployTags } from './utils/tags.enum'

const deployZapper: DeployFunction = async ({ deployments, getNamedAccounts }: HardhatRuntimeEnvironment) => {
  const { deploy } = deployments
  const { deployer } = await getNamedAccounts()
  const chainId = network.config.chainId!

  const PGRouter = await deployments.get('PGRouter')
  const InstanceRegistry = await deployments.get('InstanceRegistry')

  await deploy('Zapper', {
    from: deployer,
    args: [PGRouter.address, InstanceRegistry.address],
    log: true,
    waitConfirmations: chainId === 31337 ? 1 : 6,
  })
}

export default deployZapper

deployZapper.tags = [DeployTags.TEST, DeployTags.STAGE, DeployTags.Zapper]
