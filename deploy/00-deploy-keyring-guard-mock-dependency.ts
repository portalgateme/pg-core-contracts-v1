import { DeployFunction } from 'hardhat-deploy/dist/types'
import { HardhatRuntimeEnvironment } from 'hardhat/types'
import { ethers, network } from 'hardhat'
import { DeployTags } from './utils/tags.enum'
import { onlyLocalNetwork } from './utils'
import { keccak256 } from 'ethers/lib/utils'

const deployKeyringGuardMockDependency: DeployFunction = async ({
  deployments,
  getNamedAccounts,
}: HardhatRuntimeEnvironment) => {
  const { deploy } = deployments
  const { deployer } = await getNamedAccounts()
  const chainId = network.config.chainId!

  onlyLocalNetwork(chainId)

  await deploy('MockRuleRegistry', {
    contract: 'contracts/mocks/MockRuleRegistry.sol:MockRuleRegistry',
    from: deployer,
    args: [],
    log: true,
    waitConfirmations: 1,
  })

  const MockRuleRegistry = await ethers.getContract('MockRuleRegistry', deployer)
  await MockRuleRegistry.setGenesis(
    keccak256(ethers.utils.toUtf8Bytes('UNIVERSAL_RULE')),
    keccak256(ethers.utils.toUtf8Bytes('EMPTY_RULE')),
  )

  await deploy('MockKeyringCredentials', {
    from: deployer,
    args: [],
    log: true,
    waitConfirmations: 1,
  })

  const MockWalletCheck = await deploy('MockWalletCheck', {
    from: deployer,
    args: [],
    log: true,
    waitConfirmations: 1,
  })

  await deploy('MockPolicyManager', {
    from: deployer,
    args: [],
    log: true,
    waitConfirmations: 1,
  })

  const MockPolicyManager = await ethers.getContract('MockPolicyManager', deployer)
  await MockPolicyManager.setIsPolicy(true)
  await MockPolicyManager.setRuleRegistry(MockRuleRegistry.address)
  await MockPolicyManager.setWalletChecks([MockWalletCheck.address])

  await deploy('MockUserPolicies', {
    from: deployer,
    args: [],
    log: true,
    waitConfirmations: 1,
  })

  await deploy('MockTrustedForwarder', {
    from: deployer,
    args: [],
    log: true,
    waitConfirmations: 1,
  })
}

export default deployKeyringGuardMockDependency

deployKeyringGuardMockDependency.tags = [DeployTags.TEST, DeployTags.KeyringDependency]
