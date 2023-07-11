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
```

__Make sure to follow the output of the script and update all related configs. It is required to deploy all contracts correctly.__

3. Deploy contracts

```bash
yarn deploy-core:goerli
```

_Contracts may have already been deployed on Goerli testnet. Normally, hardhat-deploy will check if contracts with same bytecode is already deployed and will not re-deploy contract but instead will reuse deployed one. If you want to have a fresh deploy, make sure to delete `deployments` folder._

4. Setup instances

```bash
yarn setup-instances:goerli
```

5. Verify contracts

```bash
yarn verify:goerli
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

