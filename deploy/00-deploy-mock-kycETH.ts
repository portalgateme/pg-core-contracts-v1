import { DeployFunction } from 'hardhat-deploy/dist/types'
import { HardhatRuntimeEnvironment } from 'hardhat/types'
import { network } from 'hardhat'
import { DeployTags, onlyLocalNetwork, baseDeployOptions } from '../utils/deploy'

const deployMockKycETH: DeployFunction = async ({
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

  await deploy('KycETH', {
    contract: 'contracts/portalgate/KycETH.sol:KycETH',
    from: deployer,
    args: [
      mockTrustedForwarder.address,
      mockKeyringCredentials.address,
      mockPolicyManager.address,
      mockUserPolicies.address,
      1,
    ],
    gasLimit: 5000000,
    ...baseDeployOptions(chainId),
  })
}

export default deployMockKycETH

deployMockKycETH.tags = [DeployTags.TEST, DeployTags.MockKycETH]
