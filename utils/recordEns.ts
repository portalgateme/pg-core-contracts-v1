import { Contract } from "ethers";
import { ZERO_ADDRESS } from "./constants";

export enum ENSHostedContract {
  RelayerRegistry = "relayer-registry",
  InstanceRegistry = "instance-registry",
}

const namehash = require("@ensdomains/eth-ens-namehash");

export const ensManager = (ens: Contract, publicResolver: Contract) => {
  return {
    init: async (contract: ENSHostedContract) => {
      const node = namehash.hash(`${contract}.portalgate.eth`);

      await ens.setResolver(node, publicResolver.address);
      await publicResolver["setAddr(bytes32,address)"](node, ZERO_ADDRESS);

      return node;
    },
    register: async (contract: ENSHostedContract, address: string) => {
      const node = namehash.hash(`${contract}.portalgate.eth`);

      await ens.setResolver(node, publicResolver.address);
      await publicResolver["setAddr(bytes32,address)"](node, address);

      return node;
    },
  };
};
