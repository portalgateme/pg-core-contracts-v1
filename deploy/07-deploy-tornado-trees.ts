import { DeployFunction } from 'hardhat-deploy/dist/types'
import { HardhatRuntimeEnvironment } from 'hardhat/types'
import { ethers, network } from 'hardhat'
import { baseDeployOptions, DeployTags, isLocalNetwork, sleep } from '../utils/deploy'

const deployPGRouter: DeployFunction = async ({
  deployments,
  getNamedAccounts,
}: HardhatRuntimeEnvironment) => {
  const { deploy, execute, read } = deployments
  const { deployer } = await getNamedAccounts()
  const chainId = network.config.chainId!

  const baseDeployOpts = baseDeployOptions(chainId)
  const [hasher3, hasher2, pgRouter] = await Promise.all([
    deployments.get('Hasher3'),
    deployments.get('Hasher2'),
    deployments.get('PGRouter'),
  ])

  const tornadoTrees = await deploy('TornadoTrees', {
    contract: isLocalNetwork(chainId) ? 'MockTornadoTrees' : 'TornadoTrees',
    from: deployer,
    args: [pgRouter.address, hasher2.address, hasher3.address, 20],
    ...baseDeployOpts,
  })

  const existingTornadoTrees = await read('PGRouter', 'tornadoTrees')

  if (existingTornadoTrees != tornadoTrees.address) {
    await execute('PGRouter', { from: deployer, log: true }, 'setTornadoTreesContract', tornadoTrees.address)
  } else {
    console.log('TornadoTrees is already set')
  }
}

export default deployPGRouter

deployPGRouter.tags = [DeployTags.TEST, DeployTags.STAGE, DeployTags.TornadoTrees]
