import { DeployFunction } from 'hardhat-deploy/dist/types'
import { HardhatRuntimeEnvironment } from 'hardhat/types'
import { ethers, network } from 'hardhat'
import { DeployTags } from '../types/tags.enum'
import { onlyLocalNetwork } from './utils'

const deployMockKycERC20: DeployFunction = async ({
  deployments,
  getNamedAccounts,
}: HardhatRuntimeEnvironment) => {
  const { deploy } = deployments
  const { deployer } = await getNamedAccounts()
  const chainId = network.config.chainId!

  onlyLocalNetwork(chainId)

  const MockTrustedForwarder = await deployments.get('MockTrustedForwarder')
  const MockKeyringCredentials = await deployments.get('MockKeyringCredentials')
  const MockPolicyManager = await deployments.get('MockPolicyManager')
  const MockUserPolicies = await deployments.get('MockUserPolicies')

  const MockERC20 = await deployments.get('InstanceMockERC20')

  await deploy('KycERC20', {
    contract: 'contracts/portalgate/KycERC20.sol:KycERC20',
    from: deployer,
    args: [
      MockTrustedForwarder.address,
      MockERC20.address,
      MockKeyringCredentials.address,
      MockPolicyManager.address,
      MockUserPolicies.address,
      1,
      'KycERC20',
      'KYC',
    ],
    log: true,
    waitConfirmations: chainId === 31337 ? 1 : 6,
    gasLimit: 5000000,
  })
}

export default deployMockKycERC20

deployMockKycERC20.dependencies = [
  'MockTrustedForwarder',
  'MockKeyringCredentials',
  'MockPolicyManager',
  'MockUserPolicies',
  'InstanceMockERC20',
]

deployMockKycERC20.tags = [DeployTags.TEST, DeployTags.MockKycERC20]
