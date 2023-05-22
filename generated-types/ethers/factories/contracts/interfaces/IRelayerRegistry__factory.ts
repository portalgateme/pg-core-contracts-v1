/* Autogenerated file. Do not edit manually. */
/* tslint:disable */
/* eslint-disable */

import { Contract, Signer, utils } from "ethers";
import type { Provider } from "@ethersproject/providers";
import type {
  IRelayerRegistry,
  IRelayerRegistryInterface,
} from "../../../contracts/interfaces/IRelayerRegistry";

const _abi = [
  {
    inputs: [
      {
        internalType: "address",
        name: "relayer",
        type: "address",
      },
    ],
    name: "getRelayerBalance",
    outputs: [
      {
        internalType: "uint256",
        name: "",
        type: "uint256",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "relayer",
        type: "address",
      },
    ],
    name: "isRelayerRegistered",
    outputs: [
      {
        internalType: "bool",
        name: "",
        type: "bool",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
] as const;

export class IRelayerRegistry__factory {
  static readonly abi = _abi;
  static createInterface(): IRelayerRegistryInterface {
    return new utils.Interface(_abi) as IRelayerRegistryInterface;
  }
  static connect(
    address: string,
    signerOrProvider: Signer | Provider
  ): IRelayerRegistry {
    return new Contract(address, _abi, signerOrProvider) as IRelayerRegistry;
  }
}