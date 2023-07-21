import { DeployFunction } from 'hardhat-deploy/dist/types'
import { HardhatRuntimeEnvironment } from 'hardhat/types'
import { network } from 'hardhat'

import { baseDeployOptions, DeployTags } from '../utils/deploy'
import { ZERO_ADDRESS } from '../utils/constants'

const deployAPToken: DeployFunction = async ({
  deployments,
  getNamedAccounts,
}: HardhatRuntimeEnvironment) => {
  const { deploy, execute, read } = deployments
  const { deployer } = await getNamedAccounts()
  const chainId = network.config.chainId!

  const baseDeployOpts = baseDeployOptions(chainId)

  const rewardSwap = await deployments.get('RewardSwap')

  const pgap = await deploy('PortalGateAnonymityPoints', {
    from: deployer,
    args: [rewardSwap.address],
    ...baseDeployOpts,
  })

  const existingAPToken = await read('RewardSwap', 'apToken')

  if (existingAPToken != pgap.address) {
    await execute('RewardSwap', { from: deployer, log: true }, 'setAPToken', pgap.address)
  } else {
    console.log('APToken is already set')
  }
}

export default deployAPToken

deployAPToken.tags = [DeployTags.TEST, DeployTags.STAGE, DeployTags.APToken]
