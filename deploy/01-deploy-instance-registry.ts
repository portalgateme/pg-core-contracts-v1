import { DeployFunction } from "hardhat-deploy/dist/types";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import { network } from "hardhat";
import { DeployTags } from "../config/tags.enum";

const deployInstanceRegistry: DeployFunction = async ({
  deployments,
  getNamedAccounts,
}: HardhatRuntimeEnvironment) => {
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();
  const chainId = network.config.chainId!;

  await deploy("InstanceRegistry", {
    from: deployer,
    args: [deployer],
    log: true,
    waitConfirmations: chainId === 31337 ? 1 : 6,
  });
};

export default deployInstanceRegistry;

deployInstanceRegistry.tags = [
  DeployTags.TEST,
  DeployTags.STAGE,
  DeployTags.InstanceRegistry,
];
