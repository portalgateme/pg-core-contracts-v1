# pg-core-contracts-v1

---

## Initial setup

1. Install dependencies

```bash
yarn
```
Its strongly recommended to use `yarn` instead of `npm` for package management.

2. Prepare environment variables

```bash
cp .env.example .env
```

Make sure to add all the required environment variables.

3. Compile contracts

```bash
yarn compile
```

4. Run the build circuit script

```bash
yarn circuit
```

5. Replace contracts in `contracts/verifiers` with the ones generated in `build/circuits`


6. Run tests

```bash
yarn test
```

---

## Deployment

### Goerli testnet

1. Compile contracts

```bash
yarn compile
```

2. Deploy Kyc tokens

```bash
yarn deploy-kyc:goerli
yarn deploy-kyc:mainnet
```

__Make sure to follow the output of the script and update all related configs. It is required to deploy all contracts correctly.__

3. Deploy contracts

```bash
yarn deploy-core:goerli
yarn deploy-core:mainnet
```

_Contracts may have already been deployed on Goerli testnet. Normally, hardhat-deploy will check if contracts with same bytecode is already deployed and will not re-deploy contract but instead will reuse deployed one. If you want to have a fresh deploy, make sure to delete `deployments` folder._

4. Setup instances

```bash
yarn setup-instances:goerli
yarn setup-instances:mainnet
```

5. Verify contracts

```bash
yarn verify:goerli
yarn verify:mainnet
```

_This will verify contracts on Etherscan._

### Local network

1. Compile contracts

```bash
yarn compile
```

2. Run local network

```bash
yarn private-network
```

3. Deploy contracts

```bash
yarn deploy:localhost
```

_Steps **2** and **3** can be combined into one step with command `yarn private-network-deploy` that will run local node and also deploy contracts_

### Separate contracts deployment

Deploy scripts also support separate deployment of contracts. For example, if you want to deploy only `PGRouter` contract, you can run:

```bash
npx hardhat deploy --network goerli --tags pg-router
```

Important part in this script is **pg-router**.
The tags that tou can use to specify what contracts will be deployed are listed below:

```
TEST = 'test', // used by the tests
STAGE = 'stage', // set if contracts that are deployed for the staging environment

RelayerRegistry = 'relayer-registry',
RelayerAggregator = 'relayer-aggregator',
PGRouter = 'pg-router',
InstanceRegistry = 'instance-registry',
TornadoInstance = 'tornado-instance',
Zapper = 'zapper',
IntermediaryVault = 'intermediary-vault',
RewardSwap = 'reward-swap',
APToken = 'ap-token',
Echoer = 'echoer',
TornadoTrees = 'tornado-trees',
Miner = 'miner',

Hashers = 'hashers',
KycTokens = 'kyc-tokens',

MockERC20 = 'mock-erc20', // used by the tests
KeyringDependency = 'keyring-dependency', // used by the tests

SetupInstances = 'setup-instances'
```

Some of the tags *(tests related)* are protected to not be deployed on the mainnet. So even if you specify the mainnet network, they will not be deployed.

## Instance configuration

In order to proceed with the instance configuration, you need to have the following configuration file: `config/instances.ts`.
The schema is already defined in this file.

The instance configuration object has the following properties:

| Property name          | Optional         | Description                                                                                                                  | Example                                              |
| ---------------------- | ---------------- | ---------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------- |
| token                  | false (nullable) | Address of the instance token. If null value is provided then considered that it is ETH instance                             | 0xbB0E2855Ac05d26Bd9E567B8b50c98EF2b889Ad2           |
| kycToken               | true             | Address of the instance KYC token.                                                                                           | 0xc8079E6AA1d7785dC57AfC178211314164B5B138           |
| denomination           | false            | Denomination of the token. (make sure to check decimals of the token)                                                        | 100000 ^ 6 (or BigNumber.from(100000).pow(6))        |
| state                  | false            | State of the instance <br>0 - instance disabled <br>1 - instance enabled <br>2 - instance enabled and mining enabled         | 1                                                    |  |
| uniswapPoolSwappingFee | false            | Fee for swapping tokens in the Uniswap pool                                                                                  | 0                                                    |
| protocolFeePercentage  | false            | Fee for the protocol                                                                                                         | 0                                                    |
| maxDepositAmount       | false            | Max deposit amount. (make sure to check decimals of the token)                                                               | 1000000000 ^ 6 (or BigNumber.from(1000000000).pow(6) |
| name                   | false            | Name of the instance. Used by deploy script. SHOULD BE UNIQUE                                                                | kycUSDC-100000                                       |
| currencyName           | false            | Name of the currency or token symbol.                                                                                        | kycUSDC                                              |
| markleTreeHeight       | true             | Height of the merkle tree. (20 - 2^20 leaves)                                                                                | 20                                                   |
| miningRate             | false (nullable) | How many tokens will be mined per block. If null value is provided then considered that mining is disabled.                  | 100 ^ 18 (or BigNumber.from(100).pow(18))            |
| isERC20                | false            | Whether the token is ERC20                                                                                                   | true                                                 |
| poolAddress            | true             | Address of already deployed pool. (useful in cases when the pool is already deployed and needs to be used in other scripts). | 0xe6419fE674Dc53BB6cC19460A6f229b72db9Ac40           |
