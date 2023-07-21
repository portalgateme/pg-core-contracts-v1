import { DeployFunction } from 'hardhat-deploy/dist/types'
import { HardhatRuntimeEnvironment } from 'hardhat/types'
import { network } from 'hardhat'

import { baseDeployOptions, DeployTags } from '../utils/deploy'

const deployEchoer: DeployFunction = async ({ deployments, getNamedAccounts }: HardhatRuntimeEnvironment) => {
  const { deploy, execute } = deployments
  const { deployer } = await getNamedAccounts()
  const chainId = network.config.chainId!

  const baseDeployOpts = baseDeployOptions(chainId)

  const pgap = await deploy('Echoer', {
    from: deployer,
    args: [],
    ...baseDeployOpts,
  })
}

export default deployEchoer

deployEchoer.tags = [DeployTags.STAGE, DeployTags.APToken]
