# pg-core-contracts-v1

---

## Initial setup

1. Install dependencies

```bash
npm install
```

If you are facing dependency issues, try to install dependencies with `npm install --legacy-peer-deps` or `npm install --force`.

2. Prepare environment variables

```bash
cp .env.example .env
```

Make sure to add all the required environment variables.

3. Compile contracts

```bash
npm run compile
```

4. Run tests

```bash
npm run test
```

---

## Deployment

1. Compile contracts

```bash
npm run compile
```

2. Deploy contracts

```bash
npm run deploy:goerli
```

_Contracts may already be deployed on Goerli testnet. If you want to deploy them again, make sure to delete `deployments` folder._

3. Verify contracts

```bash
npm run verify:goerli
```
