import { DeployFunction } from 'hardhat-deploy/dist/types'
import { HardhatRuntimeEnvironment } from 'hardhat/types'
import { network } from 'hardhat'

import { baseDeployOptions, DeployTags } from '../utils/deploy'
import { ZERO_ADDRESS } from '../utils/constants'

const deployRewardSwap: DeployFunction = async ({
  deployments,
  getNamedAccounts,
}: HardhatRuntimeEnvironment) => {
  const { deploy } = deployments
  const { deployer } = await getNamedAccounts()
  const chainId = network.config.chainId!

  const baseDeployOpts = baseDeployOptions(chainId)

  await deploy('RewardSwap', {
    from: deployer,
    args: [ZERO_ADDRESS, ZERO_ADDRESS],
    ...baseDeployOpts,
  })
}

export default deployRewardSwap

deployRewardSwap.tags = [DeployTags.TEST, DeployTags.STAGE, DeployTags.RewardSwap]
