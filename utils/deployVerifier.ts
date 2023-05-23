import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { ethers } from "hardhat";

export async function deployVerifier(deployer: SignerWithAddress) {
  const Verifier = await ethers.getContractFactory(
    "contracts/tornado-core/Verifier.sol:Verifier",
    deployer
  );
  return Verifier.deploy();
}
