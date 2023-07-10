import { DeployFunction } from 'hardhat-deploy/dist/types'
import { HardhatRuntimeEnvironment } from 'hardhat/types'
import { network, ethers } from 'hardhat'
import {
  Address,
  BaseKeyringTokenConstructorConfig,
  ERC20InstanceConfigItem,
  ERC20KeyringTokenConstructorConfig,
  InstanceConfigItem,
} from '../config/types'
import instanceConfig from '../config/instances'
import keyringConfig, { MAXIMUM_CONSENT_PERIOD } from '../config/keyring'

import { baseDeployOptions, DeployTags, isLocalNetwork } from '../utils/deploy'
import { getUniqueByToken } from '../utils/utils'

const isERC20Item = (item: InstanceConfigItem): item is ERC20InstanceConfigItem => item.isERC20

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
      const Instance = await deployments.get(instance.name)

      const keyringConfig: ERC20KeyringTokenConstructorConfig = {
        ...baseKeyringConfig,
        collateralToken: Instance.address as Address,
      }

      await deploy(instance.currencyName + 'Kyc', {
        contract: 'contracts/portalgate/KycERC20.sol:KycERC20',
        from: deployer,
        args: [
          keyringConfig,
          policyId,
          MAXIMUM_CONSENT_PERIOD,
          instance.currencyName + 'Kyc',
          instance.currencyName + 'Kyc',
        ],
        ...baseDeployOpts,
      })
    }

    for await (const instance of ethInstances) {
      await deploy(instance.name + 'Kyc', {
        contract: 'contracts/portalgate/KycETH.sol:KycETH',
        from: deployer,
        args: [baseKeyringConfig, policyId, MAXIMUM_CONSENT_PERIOD],
        ...baseDeployOpts,
      })
    }
  }
}

export default deployKycTokens

deployKycTokens.tags = [DeployTags.TEST, DeployTags.STAGE, DeployTags.KycTokens]
