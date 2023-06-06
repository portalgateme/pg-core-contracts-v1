import { DeployFunction } from 'hardhat-deploy/dist/types'
import { HardhatRuntimeEnvironment } from 'hardhat/types'
import { ethers, network } from 'hardhat'
import { DeployTags } from './utils/tags.enum'

const genContract = require('circomlib/src/mimcsponge_gencontract.js')

const deployTornadoInstance: DeployFunction = async ({
  deployments,
  getNamedAccounts,
}: HardhatRuntimeEnvironment) => {
  const { deploy } = deployments
  const { deployer } = await getNamedAccounts()
  const chainId = network.config.chainId!

  const MockERC20 = await deployments.get('InstanceMockERC20')

  /* INSTANCES CONFIGURATION */
  const instancesToDeploy = [
    {
      denomination: 100,
      markleTreeHeight: 20,
      token: MockERC20.address,
    },
    {
      denomination: 1000,
      markleTreeHeight: 20,
      token: MockERC20.address,
    },
  ]

  const Hasher = await deploy('Hasher', {
    contract: {
      abi: genContract.abi,
      bytecode: genContract.createCode('mimcsponge', 220),
    },
    from: deployer,
    args: [],
    log: true,
    waitConfirmations: chainId === 31337 ? 1 : 6,
  })

  const Verifier = await deploy('Verifier', {
    contract: 'contracts/tornado-core/Verifier.sol:Verifier',
    from: deployer,
    args: [],
    log: true,
    waitConfirmations: chainId === 31337 ? 1 : 6,
  })

  for await (const instance of instancesToDeploy) {
    await deploy(`ERC20Tornado-${instance.denomination}`, {
      contract: 'ERC20Tornado',
      from: deployer,
      args: [
        Verifier.address,
        Hasher.address,
        instance.denomination,
        instance.markleTreeHeight,
        instance.token,
      ],
      log: true,
      waitConfirmations: chainId === 31337 ? 1 : 6,
    })
  }
}

export default deployTornadoInstance

deployTornadoInstance.tags = [DeployTags.TEST, DeployTags.TornadoInstance]
