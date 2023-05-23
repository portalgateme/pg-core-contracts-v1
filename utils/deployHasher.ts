import { ethers } from "hardhat";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
const genContract = require("circomlib/src/mimcsponge_gencontract.js");

export async function deployHasher(deployer: SignerWithAddress) {
  const Hasher = new ethers.ContractFactory(
    genContract.abi,
    genContract.createCode("mimcsponge", 220),
    deployer
  );

  return Hasher.deploy();
}
