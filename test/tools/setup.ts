import {
  deployments,
  ethers,
  getNamedAccounts,
  getUnnamedAccounts,
} from "hardhat";
import {
  PGRouter,
  RelayerRegistry,
  RelayerAggregator,
} from "../../generated-types/ethers";
import { setupUser, setupUsers } from "./users";

export const setup = deployments.createFixture(async () => {
  await deployments.fixture("test");
  const contracts = {
    PGRouter: (await ethers.getContract("PGRouter")) as PGRouter,
    RelayerRegistry: (await ethers.getContract(
      "RelayerRegistry"
    )) as RelayerRegistry,
    RelayerAggregator: (await ethers.getContract(
      "RelayerAggregator"
    )) as RelayerAggregator,
  };

  const { deployer } = await getNamedAccounts();

  const users = await setupUsers(await getUnnamedAccounts(), contracts);
  return {
    ...contracts,
    users,
    deployer: await setupUser(deployer, contracts),
    deployerSigner: await ethers.getSigner(deployer),
  };
});
