import { deployments, ethers, getNamedAccounts, getUnnamedAccounts } from 'hardhat'
import {
  PGRouter,
  RelayerRegistry,
  RelayerAggregator,
  InstanceRegistry,
  InstanceMockERC20,
  Miner,
  ERC20Tornado,
  Verifier,
  TornadoTrees,
  RewardVerifier,
  WithdrawVerifier,
  TreeUpdateVerifier,
  MockTornadoTrees,
  PortalGateAnonymityPoints,
} from '../../generated-types/ethers'
import { setupUser, setupUsers } from './users'
import { KycERC20, KycETH } from '../../generated-types/ethers/contracts/portalgate'
import { Denomination } from '../../utils/instances'

export const setup = deployments.createFixture(async () => {
  await deployments.fixture('test')
  const contracts = {
    PGRouter: (await ethers.getContract('PGRouter')) as PGRouter,
    RelayerRegistry: (await ethers.getContract('RelayerRegistry')) as RelayerRegistry,
    RelayerAggregator: (await ethers.getContract('RelayerAggregator')) as RelayerAggregator,
    InstanceRegistry: (await ethers.getContract('InstanceRegistry')) as InstanceRegistry,
    InstanceMockERC20: (await ethers.getContract('InstanceMockERC20')) as InstanceMockERC20,
    MockTrustedForwarder: (await ethers.getContract('MockTrustedForwarder')) as any,
    MockKeyringCredentials: (await ethers.getContract('MockKeyringCredentials')) as any,
    MockPolicyManager: (await ethers.getContract('MockPolicyManager')) as any,
    MockUserPolicies: (await ethers.getContract('MockUserPolicies')) as any,
    Miner: (await ethers.getContract('Miner')) as Miner,
    TornadoTrees: (await ethers.getContract('TornadoTrees')) as MockTornadoTrees,
    PGAP: (await ethers.getContract('PortalGateAnonymityPoints')) as PortalGateAnonymityPoints,

    Hasher2: (await ethers.getContract('Hasher2')) as any,
    Hasher3: (await ethers.getContract('Hasher3')) as any,

    Verifier: (await ethers.getContract('Verifier')) as Verifier,

    RewardVerifier: (await ethers.getContract('RewardVerifier')) as RewardVerifier,
    WithdrawVerifier: (await ethers.getContract('WithdrawVerifier')) as WithdrawVerifier,
    TreeUpdateVerifier: (await ethers.getContract('TreeUpdateVerifier')) as TreeUpdateVerifier,
  }

  const { deployer } = await getNamedAccounts()

  const deployerSigner = await ethers.getSigner(deployer)

  const [erc20_100, erc20_1000] = (await Promise.all([
    ethers.getContract('ERC20Tornado-100'),
    ethers.getContract('ERC20Tornado-1000'),
  ])) as [ERC20Tornado, ERC20Tornado]

  const instances = {
    deployed: [
      {
        deployedInstance: erc20_100,
        isErc20: true,
        denomination: '100' as Denomination,
        markleTreeHeight: 20,
        tokenAddr: await erc20_100.token(),
      },
      {
        deployedInstance: erc20_1000,
        isErc20: true,
        denomination: '1000' as Denomination,
        markleTreeHeight: 20,
        tokenAddr: await erc20_1000.token(),
      },
    ],

    hasher: contracts.Hasher2,
    verifier: contracts.Verifier,
  }

  const users = await setupUsers(await getUnnamedAccounts(), contracts)
  return {
    ...contracts,
    users,
    deployer: await setupUser(deployer, contracts),
    deployerSigner,
    instances,
  }
})

export type SetupFunction = () => ReturnType<typeof setup>
