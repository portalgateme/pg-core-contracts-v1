import { DeployFunction } from 'hardhat-deploy/dist/types'
import { HardhatRuntimeEnvironment } from 'hardhat/types'
import { ethers, network } from 'hardhat'
import { baseDeployOptions, DeployTags, isLocalNetwork, sleep } from '../utils/deploy'

const deployPGRouter: DeployFunction = async ({
  deployments,
  getNamedAccounts,
}: HardhatRuntimeEnvironment) => {
  const { deploy, execute } = deployments
  const { deployer } = await getNamedAccounts()
  const chainId = network.config.chainId!

  const baseDeployOpts = baseDeployOptions(chainId)

  const hasher3 = await deployments.get('Hasher3')

  const hasher2 = await deployments.get('Hasher2')

  const pgRouter = await deployments.get('PGRouter')

  const tornadoTrees = await deploy('TornadoTrees', {
    contract: isLocalNetwork(chainId) ? 'MockTornadoTrees' : 'TornadoTrees',
    from: deployer,
    args: [pgRouter.address, hasher2.address, hasher3.address, 20],
    ...baseDeployOpts,
  })

  await execute('PGRouter', { from: deployer, log: true }, 'setTornadoTreesContract', tornadoTrees.address)
}

export default deployPGRouter

// deployPGRouter.dependencies = ['PGRouter', 'Hasher2']
deployPGRouter.tags = [DeployTags.TEST, DeployTags.STAGE, DeployTags.TornadoTrees]
