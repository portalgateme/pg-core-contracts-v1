import { DeployFunction } from 'hardhat-deploy/dist/types'
import { HardhatRuntimeEnvironment } from 'hardhat/types'
import { network } from 'hardhat'
import { DeployTags, baseDeployOptions } from '../utils/deploy'

const deployTornadoInstance: DeployFunction = async ({
  deployments,
  getNamedAccounts,
}: HardhatRuntimeEnvironment) => {
  const { deploy } = deployments
  const { deployer } = await getNamedAccounts()
  const chainId = network.config.chainId!

  const mockERC20 = await deployments.get('InstanceMockERC20')

  /* INSTANCES CONFIGURATION */
  const instancesToDeploy = [
    {
      denomination: 100,
      markleTreeHeight: 20,
      token: mockERC20.address,
    },
    {
      denomination: 1000,
      markleTreeHeight: 20,
      token: mockERC20.address,
    },
  ]

  const baseDeployOpts = baseDeployOptions(chainId)

  const verifier = await deploy('Verifier', {
    contract: 'contracts/tornado-core/Verifier.sol:Verifier',
    from: deployer,
    args: [],
    ...baseDeployOpts,
  })

  const hasher2 = await deployments.get('Hasher2')

  for await (const instance of instancesToDeploy) {
    await deploy(`ERC20Tornado-${instance.denomination}`, {
      contract: 'ERC20Tornado',
      from: deployer,
      args: [
        verifier.address,
        hasher2.address,
        instance.denomination,
        instance.markleTreeHeight,
        instance.token,
      ],
      ...baseDeployOpts,
    })
  }
}

export default deployTornadoInstance

deployTornadoInstance.tags = [DeployTags.TEST, DeployTags.TornadoInstance]
