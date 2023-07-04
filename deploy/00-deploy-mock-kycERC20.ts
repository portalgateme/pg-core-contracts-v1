import { DeployFunction } from 'hardhat-deploy/dist/types'
import { HardhatRuntimeEnvironment } from 'hardhat/types'
import { ethers, network } from 'hardhat'
import { DeployTags, onlyLocalNetwork, baseDeployOptions } from '../utils/deploy'

const deployMockKycERC20: DeployFunction = async ({
  deployments,
  getNamedAccounts,
}: HardhatRuntimeEnvironment) => {
  const { deploy } = deployments
  const { deployer } = await getNamedAccounts()
  const chainId = network.config.chainId!

  onlyLocalNetwork(chainId)

  const mockTrustedForwarder = await deployments.get('MockTrustedForwarder')
  const mockKeyringCredentials = await deployments.get('MockKeyringCredentials')
  const mockPolicyManager = await deployments.get('MockPolicyManager')
  const mockUserPolicies = await deployments.get('MockUserPolicies')

  const mockERC20 = await deployments.get('InstanceMockERC20')

  await deploy('KycERC20', {
    contract: 'contracts/portalgate/KycERC20.sol:KycERC20',
    from: deployer,
    args: [
      mockTrustedForwarder.address,
      mockERC20.address,
      mockKeyringCredentials.address,
      mockPolicyManager.address,
      mockUserPolicies.address,
      1,
      'KycERC20',
      'KYC',
    ],
    gasLimit: 5000000,
    ...baseDeployOptions(chainId),
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
