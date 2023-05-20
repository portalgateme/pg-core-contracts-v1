import { DeployFunction } from "hardhat-deploy/dist/types";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import { network } from "hardhat";
import { DeployTags } from "../config/tags.enum";

const deployPGRouter: DeployFunction = async ({
  deployments,
  getNamedAccounts,
}: HardhatRuntimeEnvironment) => {
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();
  const chainId = network.config.chainId!;

  const RelayerRegistry = await deployments.get("RelayerRegistry");

  await deploy("PGRouter", {
    from: deployer,
    args: [RelayerRegistry.address],
    log: true,
    waitConfirmations: chainId === 31337 ? 1 : 6,
  });
};

export default deployPGRouter;

deployPGRouter.tags = [
  DeployTags.TEST,
  DeployTags.STAGE,
  DeployTags.RelayerAggregator,
];
