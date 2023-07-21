import { DeployFunction } from 'hardhat-deploy/dist/types'
import { HardhatRuntimeEnvironment } from 'hardhat/types'
import { ethers, network } from 'hardhat'

import { toFixedHex } from '../utils/utils'
import { baseDeployOptions, DeployTags, isLocalNetwork, sleep } from '../utils/deploy'
import { generateTree } from '../utils/merkleTree'

import instancesConfig from '../config/instances'

const deployMiner: DeployFunction = async ({ deployments, getNamedAccounts }: HardhatRuntimeEnvironment) => {
  const { deploy, execute, read } = deployments
  const { deployer } = await getNamedAccounts()
  const chainId = network.config.chainId!

  const baseDeployOpts = baseDeployOptions(chainId)

  const treeLevels = 20

  const emptyTree = generateTree(treeLevels)

  const tornadoTrees = await deployments.get('TornadoTrees')

  const rewardVerifier = await deploy('RewardVerifier', {
    from: deployer,
    args: [],
    ...baseDeployOpts,
  })

  const withdrawVerifier = await deploy('WithdrawVerifier', {
    from: deployer,
    args: [],
    ...baseDeployOpts,
  })

  const treeUpdateVerifier = await deploy('TreeUpdateVerifier', {
    from: deployer,
    args: [],
    ...baseDeployOpts,
  })

  const verifiers = [rewardVerifier.address, withdrawVerifier.address, treeUpdateVerifier.address]

  const rates: { instance: string; value: string }[] = []

  if (isLocalNetwork(chainId)) {
    const [erc20Tornado100Instance, erc20Tornado1000Instance] = await Promise.all([
      deployments.get('ERC20Tornado-100'),
      deployments.get('ERC20Tornado-1000'),
    ])

    const testRates = [
      {
        instance: erc20Tornado100Instance.address,
        value: ethers.BigNumber.from(10).toString(),
      },
      {
        instance: erc20Tornado1000Instance.address,
        value: ethers.BigNumber.from(100).toString(),
      },
    ]

    rates.push(...testRates)
  } else {
    const instances = instancesConfig[chainId.toString()]
    const deployRates = []

    for await (const instance of instances) {
      if (!instance.miningRate) {
        continue
      }

      const Instance = await deployments.get(instance.name)
      const value = ethers.BigNumber.from(instance.miningRate).toString()

      deployRates.push({
        instance: Instance.address,
        value,
      })
    }

    rates.push(...deployRates)
  }

  const accountRoot = toFixedHex(emptyTree.root())

  const rewardSwap = await deployments.get('RewardSwap')

  const miner = await deploy('Miner', {
    from: deployer,
    args: [rewardSwap.address, deployer, tornadoTrees.address, verifiers, accountRoot, rates],
    ...baseDeployOpts,
  })

  const existingMiner = await read('RewardSwap', 'miner')

  if (existingMiner !== miner.address) {
    await execute(
      'RewardSwap',
      {
        from: deployer,
        log: true,
      },
      'setMiner',
      miner.address,
    )
  } else {
    console.log('Miner is already set')
  }
}

export default deployMiner

deployMiner.tags = [DeployTags.TEST, DeployTags.STAGE, DeployTags.Miner]
