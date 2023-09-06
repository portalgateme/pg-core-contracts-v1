import { HardhatUserConfig, task } from 'hardhat/config'

import '@typechain/hardhat'
import '@nomiclabs/hardhat-ethers'
import '@nomiclabs/hardhat-ganache'
import '@nomicfoundation/hardhat-toolbox'
import 'hardhat-deploy'

import * as dotenv from 'dotenv'
dotenv.config()

function typechainTarget() {
  const target = process.env.TYPECHAIN_TARGET
  return target == '' || target == undefined ? 'ethers-v5' : target
}

function forceTypechain() {
  return process.env.TYPECHAIN_FORCE == 'true'
}

function privateKey() {
  return process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : []
}

const SOL_COMPILER_VERSIONS = ['0.6.11', '0.6.12', '0.7.6', '0.8.6', '0.8.7', '0.8.14', '0.8.19']

const config: HardhatUserConfig = {
  networks: {
    hardhat: {
      initialDate: '1970-01-01T00:00:00Z',
      chainId: 31337,
      allowUnlimitedContractSize: false,
      accounts: {
        count: 10,
      },
    },
    localhost: {
      url: 'http://127.0.0.1:8545',
      initialDate: '1970-01-01T00:00:00Z',
      gasMultiplier: 1.2,
      chainId: 31337,
      allowUnlimitedContractSize: false,
    },
    goerli: {
      url: `https://chaotic-fittest-dew.ethereum-goerli.quiknode.pro/8ee65fa950c98ed30ec92ccd7d67639c13822af0/`,
      accounts: privateKey(),
      gasMultiplier: 1.2,
      chainId: 5,
      saveDeployments: true,
      tags: ['stage'],
      verify: {
        etherscan: {
          apiUrl: 'https://api-goerli.etherscan.io/',
        },
      },
    },
    mainnet: {
      url: `https://frequent-radial-valley.quiknode.pro/a7927e7f7fe9ee09b44a51c8407c0359462e6e52/`,
      accounts: privateKey(),
      chainId: 1,
      saveDeployments: true,
      tags: ['stage'],
      verify: {
        etherscan: {
          apiUrl: 'https://api.etherscan.io/',
        },
      },
    },
  },
  verify: {
    etherscan: {
      apiKey: process.env.ETHERSCAN_API_KEY,
    },
  },
  solidity: {
    compilers: SOL_COMPILER_VERSIONS.map((version) => ({
      version,
      settings: {
        optimizer: {
          enabled: true,
          runs: 200,
        },
      },
    })),
  },
  typechain: {
    outDir: `generated-types/${typechainTarget().split('-')[0]}`,
    target: typechainTarget(),
    alwaysGenerateOverloads: true,
    discriminateTypes: true,
    dontOverrideCompile: !forceTypechain(),
  },
  namedAccounts: {
    deployer: {
      default: 0,
    },
  },
  mocha: {
    timeout: 90000,
    color: true,
  },
}

task('accounts', 'Prints the list of accounts', async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners()

  for (const account of accounts) {
    console.log(account.address)
  }
})

export default config
