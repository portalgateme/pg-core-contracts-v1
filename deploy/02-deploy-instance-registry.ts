import { DeployFunction } from 'hardhat-deploy/dist/types'
import { HardhatRuntimeEnvironment } from 'hardhat/types'
import { ethers, network } from 'hardhat'
import { DeployTags } from './utils/tags.enum'

const deployInstanceRegistry: DeployFunction = async ({
  deployments,
  getNamedAccounts,
}: HardhatRuntimeEnvironment) => {
  const { deploy } = deployments
  const { deployer } = await getNamedAccounts()
  const chainId = network.config.chainId!

  const instanceRegistry = await deploy('InstanceRegistry', {
    from: deployer,
    args: [deployer],
    log: true,
    waitConfirmations: chainId === 31337 ? 1 : 6,
    gasLimit: 5000000,
  })
}

export default deployInstanceRegistry

deployInstanceRegistry.tags = [DeployTags.TEST, DeployTags.STAGE, DeployTags.InstanceRegistry]
