import { DeployFunction } from 'hardhat-deploy/dist/types'
import { HardhatRuntimeEnvironment } from 'hardhat/types'
import { network } from 'hardhat'
import { baseDeployOptions, DeployTags } from '../utils/deploy'

const genContract2 = require('circomlib/src/poseidon_gencontract.js')
const genContract = require('circomlib/src/mimcsponge_gencontract.js')

const deployHashers: DeployFunction = async ({
  deployments,
  getNamedAccounts,
}: HardhatRuntimeEnvironment) => {
  const { deploy } = deployments
  const { deployer } = await getNamedAccounts()
  const chainId = network.config.chainId!

  const baseDeployOpts = baseDeployOptions(chainId)

  await deploy('Hasher2', {
    contract: {
      abi: genContract2.generateABI(2),
      bytecode: genContract2.createCode(2),
    },
    from: deployer,
    args: [],
    ...baseDeployOpts,
  })

  await deploy('Hasher3', {
    contract: {
      abi: genContract2.generateABI(3),
      bytecode: genContract2.createCode(3),
    },
    from: deployer,
    args: [],
    ...baseDeployOpts,
  })

  await deploy('HasherMimc', {
    contract: {
      abi: genContract.abi,
      bytecode: genContract.createCode('mimcsponge', 220),
    },
    from: deployer,
    args: [],
    ...baseDeployOpts,
  })
}

export default deployHashers

deployHashers.tags = [DeployTags.TEST, DeployTags.STAGE, DeployTags.Hashers]
