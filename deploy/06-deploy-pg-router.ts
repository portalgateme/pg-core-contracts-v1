import { DeployFunction } from 'hardhat-deploy/dist/types'
import { HardhatRuntimeEnvironment } from 'hardhat/types'
import { ethers, network } from 'hardhat'
import { ZERO_ADDRESS } from '../utils/constants'
import { baseDeployOptions, DeployTags } from '../utils/deploy'

const deployPGRouter: DeployFunction = async ({
  deployments,
  getNamedAccounts,
}: HardhatRuntimeEnvironment) => {
  const { deploy, execute, read } = deployments
  const { deployer } = await getNamedAccounts()
  const chainId = network.config.chainId!

  const [instanceRegistry, relayerRegistry] = await Promise.all([
    deployments.get('InstanceRegistry'),
    deployments.get('RelayerRegistry'),
  ])

  const pgRouter = await deploy('PGRouter', {
    from: deployer,
    args: [ZERO_ADDRESS, deployer, instanceRegistry.address, relayerRegistry.address],
    ...baseDeployOptions(chainId),
  })

  const existingPGRouter = await read('InstanceRegistry', 'router')

  if (existingPGRouter != pgRouter.address) {
    await execute('InstanceRegistry', { from: deployer, log: true }, 'setPGRouter', pgRouter.address)
  } else {
    console.log('PGRouter is already set')
  }
}

export default deployPGRouter

deployPGRouter.tags = [DeployTags.TEST, DeployTags.STAGE, DeployTags.PGRouter]
