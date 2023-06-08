import { DeployFunction } from 'hardhat-deploy/dist/types'
import { HardhatRuntimeEnvironment } from 'hardhat/types'
import { ethers, network } from 'hardhat'
import { baseDeployOptions, DeployTags, isLocalNetwork } from '../utils/deploy'

const genContract2 = require('circomlib/src/poseidon_gencontract.js')

const deployPGRouter: DeployFunction = async ({
  deployments,
  getNamedAccounts,
}: HardhatRuntimeEnvironment) => {
  const { deploy } = deployments
  const { deployer } = await getNamedAccounts()
  const chainId = network.config.chainId!

  const baseDeployOpts = baseDeployOptions(chainId)

  const hasher3 = await deploy('Hasher3', {
    contract: {
      abi: genContract2.generateABI(3),
      bytecode: genContract2.createCode(3),
    },
    from: deployer,
    args: [],
    ...baseDeployOpts,
  })
  const hasher2 = await deployments.get('Hasher2')

  const pgRouter = await deployments.get('PGRouter')

  const tornadoTrees = await deploy('TornadoTrees', {
    contract: isLocalNetwork(chainId) ? 'MockTornadoTrees' : 'TornadoTrees',
    from: deployer,
    args: [pgRouter.address, hasher2.address, hasher3.address, 20],
    ...baseDeployOpts,
  })

  const PGRouter = await ethers.getContract('PGRouter', deployer)
  await PGRouter.setTornadoTreesContract(tornadoTrees.address)
}

export default deployPGRouter

deployPGRouter.dependencies = ['PGRouter', 'Hasher2']
deployPGRouter.tags = [DeployTags.TEST, DeployTags.STAGE, DeployTags.TornadoTrees]
