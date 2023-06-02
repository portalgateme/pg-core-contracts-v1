import { deployments, ethers, getNamedAccounts, getUnnamedAccounts } from 'hardhat'
import {
  PGRouter,
  RelayerRegistry,
  RelayerAggregator,
  InstanceRegistry,
  InstanceMockERC20,
} from '../../generated-types/ethers'
import { setupUser, setupUsers } from './users'
import { deployInstances } from '../../utils/deployInstances'
import { KycERC20, KycETH } from '../../generated-types/ethers/contracts/portalgate'

export const setup = deployments.createFixture(async () => {
  await deployments.fixture('test')
  const contracts = {
    PGRouter: (await ethers.getContract('PGRouter')) as PGRouter,
    RelayerRegistry: (await ethers.getContract('RelayerRegistry')) as RelayerRegistry,
    RelayerAggregator: (await ethers.getContract('RelayerAggregator')) as RelayerAggregator,
    InstanceRegistry: (await ethers.getContract('InstanceRegistry')) as InstanceRegistry,
    InstanceMockERC20: (await ethers.getContract('InstanceMockERC20')) as InstanceMockERC20,
    KycERC20: (await ethers.getContract('KycERC20')) as KycERC20,
    KycETH: (await ethers.getContract('KycETH')) as KycETH,
    MockTrustedForwarder: (await ethers.getContract('MockTrustedForwarder')) as any,
    MockKeyringCredentials: (await ethers.getContract('MockKeyringCredentials')) as any,
    MockPolicyManager: (await ethers.getContract('MockPolicyManager')) as any,
    MockUserPolicies: (await ethers.getContract('MockUserPolicies')) as any,
  }

  const { deployer } = await getNamedAccounts()

  const deployerSigner = await ethers.getSigner(deployer)

  const instances = await deployInstances({
    instances: [
      {
        isErc20: true,
        denomination: '100',
        markleTreeHeight: 20,
        tokenAddr: contracts.InstanceMockERC20.address, // needs to be replaced with some other token
      },
    ],
    deployer: deployerSigner,
  })

  const users = await setupUsers(await getUnnamedAccounts(), contracts)
  return {
    ...contracts,
    users,
    deployer: await setupUser(deployer, contracts),
    deployerSigner,
    instances,
  }
})
