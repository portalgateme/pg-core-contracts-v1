import { DeployFunction } from 'hardhat-deploy/dist/types'
import { HardhatRuntimeEnvironment } from 'hardhat/types'
import { network, ethers } from 'hardhat'
import {
  Address,
  BaseKeyringTokenConstructorConfig,
  ERC20KeyringTokenConstructorConfig,
  BaseInstanceConfigItem,
} from '../config/types'
import instanceConfig from '../config/instances'
import keyringConfig, { MAXIMUM_CONSENT_PERIOD } from '../config/keyring'

import { baseDeployOptions, DeployTags, isLocalNetwork } from '../utils/deploy'
import { getUniqueByToken } from '../utils/utils'

const isERC20Item = (item: BaseInstanceConfigItem) => item.isERC20

const deployKycTokens: DeployFunction = async ({
  deployments,
  getNamedAccounts,
}: HardhatRuntimeEnvironment) => {
  const { deploy, execute } = deployments
  const { deployer } = await getNamedAccounts()

  const chainId = network.config.chainId!

  const baseDeployOpts = baseDeployOptions(chainId)

  const { forwarder, keyringCredentials, policyManager, userPolicies, exemptionsManager } =
    keyringConfig[chainId.toString()]

  const baseKeyringConfig: BaseKeyringTokenConstructorConfig = {
    trustedForwarder: forwarder,
    keyringCredentials,
    policyManager,
    userPolicies,
    exemptionsManager,
  }

  if (!isLocalNetwork(chainId)) {
    const policyCount = await new ethers.Contract(
      baseKeyringConfig.policyManager,
      ['function policyCount() view returns (uint256)'],
      ethers.provider.getSigner(deployer),
    ).policyCount()

    const policyId = Number(policyCount) - 1

    const erc20Instances = getUniqueByToken(instanceConfig[chainId.toString()].filter(isERC20Item), 'token')
    const ethInstances = instanceConfig[chainId.toString()].filter((item) => !isERC20Item(item))

    for await (const instance of erc20Instances) {
      const keyringConfig: ERC20KeyringTokenConstructorConfig = {
        ...baseKeyringConfig,
        collateralToken: instance.token as Address,
      }

      const deployed = await deploy(instance.currencyName, {
        contract: 'contracts/portalgate/KycERC20.sol:KycERC20',
        from: deployer,
        args: [
          keyringConfig,
          policyId,
          MAXIMUM_CONSENT_PERIOD,
          instance.currencyName,
          instance.currencyName,
        ],
        ...baseDeployOpts,
      })

      console.log('Deployed KycERC20 for', instance.currencyName)
      console.log(
        `Please, paste the following line into config/instances.ts where token is ${instance.token}: `,
      )
      console.log(`kycToken: "${deployed.address}"`)
    }

    for await (const instance of ethInstances) {
      const keyringConfig: ERC20KeyringTokenConstructorConfig = {
        ...baseKeyringConfig,
        collateralToken: '0x0000000000000000000000000000000000000000',
      }

      const deployed = await deploy(instance.currencyName, {
        contract: 'contracts/portalgate/KycETH.sol:KycETH',
        from: deployer,
        args: [keyringConfig, policyId, MAXIMUM_CONSENT_PERIOD],
        ...baseDeployOpts,
      })

      console.log('Deployed KycETH for', instance.currencyName)
      console.log(
        `Please, paste the following line into config/instances.ts where token is null (native ETH): `,
      )
      console.log(`kycToken: "${deployed.address}"`)
    }
  }
}

export default deployKycTokens

deployKycTokens.tags = [DeployTags.TEST, DeployTags.KycTokens]
