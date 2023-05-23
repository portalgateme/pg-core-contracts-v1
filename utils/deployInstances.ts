import {
  ERC20Tornado__factory,
  ERC20Tornado,
  ETHTornado,
  ETHTornado__factory,
} from "../generated-types/ethers";
import { ZERO_ADDRESS } from "../utils/constants";
import { ethers } from "hardhat";
import { deployHasher } from "./deployHasher";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { deployVerifier } from "./deployVerifier";

type ETHDenomination = "0.1" | "1" | "10" | "100";
type ERC20Denomination = "10" | "100" | "1000" | "10000";

type Denomination = ETHDenomination | ERC20Denomination;

interface DeployInstance {
  isErc20: boolean;
  denomination: Denomination;
  markleTreeHeight: number;
  tokenAddr?: string;
}

interface DeployInstancesOptions {
  instances: DeployInstance[];
  deployer: SignerWithAddress;
}

interface DeployETHInstanceOptions {
  verifierAddress: string;
  hasherAddress: string;
  denomination: Denomination;
  markleTreeHeight: number;
  factory: ETHTornado__factory;
  deployer: SignerWithAddress;
}

interface DeployERC20InstanceOptions {
  verifierAddress: string;
  hasherAddress: string;
  denomination: Denomination;
  markleTreeHeight: number;
  tokenAddr: string;
  factory: ERC20Tornado__factory;
  deployer: SignerWithAddress;
}

interface DeployedInstance {
  isErc20: boolean;
  denomination: Denomination;
  markleTreeHeight: number;
  tokenAddr?: string;
  deployedInstance: ETHTornado | ERC20Tornado;
}

async function deployETHInstance(
  options: DeployETHInstanceOptions
): Promise<ETHTornado> {
  const {
    verifierAddress,
    hasherAddress,
    denomination,
    markleTreeHeight,
    factory,
  } = options;

  return factory.deploy(
    verifierAddress,
    hasherAddress,
    ethers.utils.parseEther(denomination),
    markleTreeHeight
  ) as Promise<ETHTornado>;
}

async function deployERC20Instance(options: DeployERC20InstanceOptions) {
  const {
    verifierAddress,
    hasherAddress,
    denomination,
    markleTreeHeight,
    factory,
    tokenAddr,
  } = options;

  return factory.deploy(
    verifierAddress,
    hasherAddress,
    ethers.utils.parseEther(denomination),
    markleTreeHeight,
    tokenAddr
  ) as Promise<ERC20Tornado>;
}

export async function deployInstances(options: DeployInstancesOptions) {
  const hasher = await deployHasher(options.deployer);
  const verifier = await deployVerifier(options.deployer);
  const ETHTornado = await ethers.getContractFactory(
    "ETHTornado",
    options.deployer
  );
  const ERC20Tornado = await ethers.getContractFactory(
    "ERC20Tornado",
    options.deployer
  );

  const deployed: DeployedInstance[] = [];

  for await (const instance of options.instances) {
    const base = {
      verifierAddress: verifier.address,
      hasherAddress: hasher.address,
      denomination: instance.denomination || "10",
      markleTreeHeight: instance.markleTreeHeight,
      deployer: options.deployer,
    };

    let deployedInstance: ERC20Tornado | ETHTornado;

    if (instance.isErc20) {
      deployedInstance = await deployERC20Instance({
        ...base,
        tokenAddr: instance.tokenAddr || ZERO_ADDRESS,
        factory: ERC20Tornado,
      });
    } else {
      deployedInstance = await deployETHInstance({
        ...base,
        factory: ETHTornado,
      });
    }
    deployed.push({ ...instance, deployedInstance });
  }

  return {
    deployed,
    hasher,
    verifier,
  };
}

export function formatToContractInput(
  deployed: DeployedInstance[],
  uniswapPoolSwappingFee: number,
  protocolFeePercentage: number,
  maxDepositAmount: number
) {
  return deployed.map((inst) => {
    return {
      addr: inst.deployedInstance.address,
      instance: {
        isERC20: inst.isErc20,
        token: inst.tokenAddr || ZERO_ADDRESS,
        state: 1,
        uniswapPoolSwappingFee,
        protocolFeePercentage,
        maxDepositAmount,
      },
    };
  });
}
