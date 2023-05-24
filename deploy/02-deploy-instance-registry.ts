import { DeployFunction } from "hardhat-deploy/dist/types";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import { ethers, network } from "hardhat";
import { DeployTags } from "../config/tags.enum";

let instances: any[] = [
  {
    addr: "instance_address",
    instance: {
      isERC20: true,
      token: "kyc_address",
      state: 1,
      uniswapPoolSwappingFee: 0,
      protocolFeePercentage: 0,
      maxDepositAmount: 0,
    },
  },
  {
    addr: "instance_address",
    instance: {
      isERC20: true,
      token: "kyc_address",
      state: 1,
      uniswapPoolSwappingFee: 0,
      protocolFeePercentage: 0,
      maxDepositAmount: 0,
    },
  }
]

const deployInstanceRegistry: DeployFunction = async ({
  deployments,
  getNamedAccounts,
}: HardhatRuntimeEnvironment) => {
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();
  const chainId = network.config.chainId!;

  const instanceRegistry = await deploy("InstanceRegistry", {
    from: deployer,
    args: [deployer],
    log: true,
    waitConfirmations: chainId === 31337 ? 1 : 6,
  });

  const instanceRegistryContract = await ethers.getContractAt(
    "InstanceRegistry",
    instanceRegistry.address
  );

  await instanceRegistryContract.initInstances(instances);
};

export default deployInstanceRegistry;

deployInstanceRegistry.tags = [
  DeployTags.TEST,
  DeployTags.STAGE,
  DeployTags.InstanceRegistry,
];
