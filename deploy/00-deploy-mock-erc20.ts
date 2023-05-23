import { DeployFunction } from "hardhat-deploy/dist/types";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import { network } from "hardhat";
import { DeployTags } from "../config/tags.enum";

const deployInstanceMockERC20: DeployFunction = async ({
  deployments,
  getNamedAccounts,
}: HardhatRuntimeEnvironment) => {
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();
  const chainId = network.config.chainId!;

  await deploy("InstanceMockERC20", {
    from: deployer,
    args: [],
    log: true,
    waitConfirmations: chainId === 31337 ? 1 : 6,
  });
};

export default deployInstanceMockERC20;

deployInstanceMockERC20.tags = [
  DeployTags.TEST,
  DeployTags.STAGE,
  DeployTags.MockERC20,
];
