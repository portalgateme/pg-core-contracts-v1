import { DeployFunction } from 'hardhat-deploy/dist/types'
import { HardhatRuntimeEnvironment } from 'hardhat/types'
import { ethers, network } from 'hardhat'
import { DeployTags } from '../types/tags.enum'

const deployMockKycETH: DeployFunction = async ({
  deployments,
  getNamedAccounts,
}: HardhatRuntimeEnvironment) => {
  const { deploy } = deployments
  const { deployer } = await getNamedAccounts()
  const chainId = network.config.chainId!

  const MockTrustedForwarder = await deployments.get('MockTrustedForwarder')
  const MockKeyringCredentials = await deployments.get('MockKeyringCredentials')
  const MockPolicyManager = await deployments.get('MockPolicyManager')
  const MockUserPolicies = await deployments.get('MockUserPolicies')

  await deploy('KycETH', {
    contract: 'contracts/portalgate/KycETH.sol:KycETH',
    from: deployer,
    args: [
      MockTrustedForwarder.address,
      MockKeyringCredentials.address,
      MockPolicyManager.address,
      MockUserPolicies.address,
      1,
    ],
    log: true,
    waitConfirmations: chainId === 31337 ? 1 : 6,
    gasLimit: 5000000,
  })
}

export default deployMockKycETH

deployMockKycETH.tags = [DeployTags.TEST, DeployTags.MockKycETH]
