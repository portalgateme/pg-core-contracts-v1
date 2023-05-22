/* Autogenerated file. Do not edit manually. */
/* tslint:disable */
/* eslint-disable */
import { Signer, utils, Contract, ContractFactory, Overrides } from "ethers";
import type { Provider, TransactionRequest } from "@ethersproject/providers";
import type { PromiseOrValue } from "../../../../common";
import type {
  UserPolicies,
  UserPoliciesInterface,
} from "../../../../contracts/keyring/userPolicies/UserPolicies";

const _abi = [
  {
    inputs: [
      {
        internalType: "address",
        name: "trustedForwarder",
        type: "address",
      },
      {
        internalType: "address",
        name: "policyManager_",
        type: "address",
      },
    ],
    stateMutability: "nonpayable",
    type: "constructor",
  },
  {
    inputs: [
      {
        internalType: "string",
        name: "module",
        type: "string",
      },
      {
        internalType: "string",
        name: "method",
        type: "string",
      },
      {
        internalType: "string",
        name: "reason",
        type: "string",
      },
      {
        internalType: "string",
        name: "context",
        type: "string",
      },
    ],
    name: "AddressSetConsistency",
    type: "error",
  },
  {
    inputs: [
      {
        internalType: "string",
        name: "reason",
        type: "string",
      },
    ],
    name: "Unacceptable",
    type: "error",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "sender",
        type: "address",
      },
      {
        internalType: "string",
        name: "module",
        type: "string",
      },
      {
        internalType: "string",
        name: "method",
        type: "string",
      },
      {
        internalType: "bytes32",
        name: "role",
        type: "bytes32",
      },
      {
        internalType: "string",
        name: "reason",
        type: "string",
      },
      {
        internalType: "string",
        name: "context",
        type: "string",
      },
    ],
    name: "Unauthorized",
    type: "error",
  },
  {
    anonymous: false,
    inputs: [
      {
        indexed: true,
        internalType: "address",
        name: "",
        type: "address",
      },
      {
        indexed: true,
        internalType: "address",
        name: "whitelisted",
        type: "address",
      },
    ],
    name: "AddTraderWhitelisted",
    type: "event",
  },
  {
    anonymous: false,
    inputs: [
      {
        indexed: false,
        internalType: "address",
        name: "trustedForwarder",
        type: "address",
      },
      {
        indexed: false,
        internalType: "address",
        name: "policyManager",
        type: "address",
      },
    ],
    name: "Deployed",
    type: "event",
  },
  {
    anonymous: false,
    inputs: [
      {
        indexed: true,
        internalType: "address",
        name: "",
        type: "address",
      },
      {
        indexed: true,
        internalType: "address",
        name: "whitelisted",
        type: "address",
      },
    ],
    name: "RemoveTraderWhitelisted",
    type: "event",
  },
  {
    anonymous: false,
    inputs: [
      {
        indexed: true,
        internalType: "bytes32",
        name: "role",
        type: "bytes32",
      },
      {
        indexed: true,
        internalType: "bytes32",
        name: "previousAdminRole",
        type: "bytes32",
      },
      {
        indexed: true,
        internalType: "bytes32",
        name: "newAdminRole",
        type: "bytes32",
      },
    ],
    name: "RoleAdminChanged",
    type: "event",
  },
  {
    anonymous: false,
    inputs: [
      {
        indexed: true,
        internalType: "bytes32",
        name: "role",
        type: "bytes32",
      },
      {
        indexed: true,
        internalType: "address",
        name: "account",
        type: "address",
      },
      {
        indexed: true,
        internalType: "address",
        name: "sender",
        type: "address",
      },
    ],
    name: "RoleGranted",
    type: "event",
  },
  {
    anonymous: false,
    inputs: [
      {
        indexed: true,
        internalType: "bytes32",
        name: "role",
        type: "bytes32",
      },
      {
        indexed: true,
        internalType: "address",
        name: "account",
        type: "address",
      },
      {
        indexed: true,
        internalType: "address",
        name: "sender",
        type: "address",
      },
    ],
    name: "RoleRevoked",
    type: "event",
  },
  {
    anonymous: false,
    inputs: [
      {
        indexed: true,
        internalType: "address",
        name: "trader",
        type: "address",
      },
      {
        indexed: true,
        internalType: "uint32",
        name: "policyId",
        type: "uint32",
      },
    ],
    name: "SetUserPolicy",
    type: "event",
  },
  {
    inputs: [],
    name: "DEFAULT_ADMIN_ROLE",
    outputs: [
      {
        internalType: "bytes32",
        name: "",
        type: "bytes32",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "whitelisted",
        type: "address",
      },
    ],
    name: "addWhitelistedTrader",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "bytes32",
        name: "role",
        type: "bytes32",
      },
    ],
    name: "getRoleAdmin",
    outputs: [
      {
        internalType: "bytes32",
        name: "",
        type: "bytes32",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "bytes32",
        name: "role",
        type: "bytes32",
      },
      {
        internalType: "address",
        name: "account",
        type: "address",
      },
    ],
    name: "grantRole",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "bytes32",
        name: "role",
        type: "bytes32",
      },
      {
        internalType: "address",
        name: "account",
        type: "address",
      },
    ],
    name: "hasRole",
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
  {
    inputs: [
      {
        internalType: "address",
        name: "forwarder",
        type: "address",
      },
    ],
    name: "isTrustedForwarder",
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
  {
    inputs: [
      {
        internalType: "address",
        name: "trader",
        type: "address",
      },
      {
        internalType: "address",
        name: "counterparty",
        type: "address",
      },
    ],
    name: "isWhitelisted",
    outputs: [
      {
        internalType: "bool",
        name: "isIndeed",
        type: "bool",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [],
    name: "policyManager",
    outputs: [
      {
        internalType: "address",
        name: "",
        type: "address",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "whitelisted",
        type: "address",
      },
    ],
    name: "removeWhitelistedTrader",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "bytes32",
        name: "role",
        type: "bytes32",
      },
      {
        internalType: "address",
        name: "account",
        type: "address",
      },
    ],
    name: "renounceRole",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "bytes32",
        name: "role",
        type: "bytes32",
      },
      {
        internalType: "address",
        name: "account",
        type: "address",
      },
    ],
    name: "revokeRole",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "uint32",
        name: "policyId",
        type: "uint32",
      },
    ],
    name: "setUserPolicy",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "bytes4",
        name: "interfaceId",
        type: "bytes4",
      },
    ],
    name: "supportsInterface",
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
  {
    inputs: [
      {
        internalType: "address",
        name: "",
        type: "address",
      },
    ],
    name: "userPolicies",
    outputs: [
      {
        internalType: "uint32",
        name: "",
        type: "uint32",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "trader",
        type: "address",
      },
      {
        internalType: "uint256",
        name: "index",
        type: "uint256",
      },
    ],
    name: "whitelistedTraderAtIndex",
    outputs: [
      {
        internalType: "address",
        name: "whitelisted",
        type: "address",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "trader",
        type: "address",
      },
    ],
    name: "whitelistedTraderCount",
    outputs: [
      {
        internalType: "uint256",
        name: "count",
        type: "uint256",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
] as const;

const _bytecode =
  "0x60c060405234801561001057600080fd5b506040516200133e3803806200133e83398101604081905261003191610158565b6001600160a01b038216608081905261009257604051636415329d60e01b815260206004820181905260248201527f74727573746564466f727761726465722063616e6e6f7420626520656d70747960448201526064015b60405180910390fd5b6001600160a01b0381166100e957604051636415329d60e01b815260206004820152601d60248201527f706f6c6963794d616e616765722063616e6e6f7420626520656d7074790000006044820152606401610089565b6001600160a01b0381811660a081905260408051928516835260208301919091527f09e48df7857bd0c1e0d31bb8a85d42cf1874817895f171c917f6ee2cea73ec20910160405180910390a1505061018b565b80516001600160a01b038116811461015357600080fd5b919050565b6000806040838503121561016b57600080fd5b6101748361013c565b91506101826020840161013c565b90509250929050565b60805160a05161117f620001bf6000396000818161028501526104d90152600081816101bc0152610b23015261117f6000f3fe608060405234801561001057600080fd5b50600436106101005760003560e01c80637b91778f11610097578063ab3dbf3b11610066578063ab3dbf3b14610280578063b6b35272146102a7578063d547741f146102ba578063e37715af146102cd57600080fd5b80637b91778f1461021757806387a229441461022a57806391d1485414610265578063a217fddf1461027857600080fd5b806336568abe116100d357806336568abe1461018657806354ba738614610199578063572b6c05146101ac57806368bd140c146101ec57600080fd5b806301ffc9a71461010557806321a845f51461012d578063248a9ca3146101425780632f2ff15d14610173575b600080fd5b610118610113366004610d6a565b6102e0565b60405190151581526020015b60405180910390f35b61014061013b366004610db0565b610317565b005b610165610150366004610dcb565b60009081526020819052604090206001015490565b604051908152602001610124565b610140610181366004610de4565b6103b7565b610140610194366004610de4565b6103e1565b6101656101a7366004610db0565b610474565b6101186101ba366004610db0565b7f00000000000000000000000000000000000000000000000000000000000000006001600160a01b0390811691161490565b6101ff6101fa366004610e10565b610495565b6040516001600160a01b039091168152602001610124565b610140610225366004610e3a565b6104be565b610250610238366004610db0565b60336020526000908152604090205463ffffffff1681565b60405163ffffffff9091168152602001610124565b610118610273366004610de4565b61060a565b610165600081565b6101ff7f000000000000000000000000000000000000000000000000000000000000000081565b6101186102b5366004610e60565b610633565b6101406102c8366004610de4565b610655565b6101406102db366004610db0565b61067a565b60006001600160e01b03198216637965db0b60e01b148061031157506301ffc9a760e01b6001600160e01b03198316145b92915050565b60006034600061032561078e565b6001600160a01b03166001600160a01b03168152602001908152602001600020905061036c826040518060600160405280602181526020016111296021913983919061079d565b816001600160a01b031661037e61078e565b6001600160a01b03167fa6bf9a1db4ea3a7d8f2dad0e11ad036f24955deea904e59f5566d959dc6697e460405160405180910390a35050565b6000828152602081905260409020600101546103d2816108ca565b6103dc83836108de565b505050565b6103e961078e565b6001600160a01b0316816001600160a01b0316146104665760405162461bcd60e51b815260206004820152602f60248201527f416363657373436f6e74726f6c3a2063616e206f6e6c792072656e6f756e636560448201526e103937b632b9903337b91039b2b63360891b60648201526084015b60405180910390fd5b6104708282610963565b5050565b6001600160a01b038116600090815260346020526040812060010154610311565b6001600160a01b03821660009081526034602052604081206104b790836109e6565b9392505050565b604051632a9c5ced60e21b815263ffffffff821660048201527f00000000000000000000000000000000000000000000000000000000000000006001600160a01b03169063aa7173b490602401602060405180830381865afa158015610528573d6000803e3d6000fd5b505050506040513d601f19601f8201168201806040525081019061054c9190610e8a565b61058e57604051636415329d60e01b81526020600482015260126024820152711c1bdb1a58de5259081b9bdd08199bdd5b9960721b604482015260640161045d565b806033600061059b61078e565b6001600160a01b031681526020810191909152604001600020805463ffffffff191663ffffffff92831617905581166105d261078e565b6001600160a01b03167f0c2ad99eddbe858b0351335d3dfeec17d1251134a726428f2924bef71e3dedaf60405160405180910390a350565b6000918252602082815260408084206001600160a01b0393909316845291905290205460ff1690565b6001600160a01b03821660009081526034602052604081206104b79083610a19565b600082815260208190526040902060010154610670816108ca565b6103dc8383610963565b61068261078e565b6001600160a01b0316816001600160a01b0316036106ee57604051636415329d60e01b815260206004820152602260248201527f73656c662077686974656c697374696e67206973206e6f74207065726d697474604482015261195960f21b606482015260840161045d565b6000603460006106fc61078e565b6001600160a01b03166001600160a01b0316815260200190815260200160002090506107438260405180606001604052806021815260200161112960219139839190610a7c565b816001600160a01b031661075561078e565b6001600160a01b03167fa314ae17b87269d8761114d3ec07e80b793270798d44d5a9e5753cd37aa50ddf60405160405180910390a35050565b6000610798610b1f565b905090565b6107a78383610a19565b6107e657604080518082018252600a8152691059191c995cdcd4d95d60b21b60208201529051633bce1ae360e01b815261045d91908390600401610f08565b600183810180546000926107f991610f94565b8154811061080957610809610fab565b60009182526020808320909101546001600160a01b0386811684529187905260408084205492909116808452922081905560018601805492935090918391908390811061085857610858610fab565b600091825260208083209190910180546001600160a01b0319166001600160a01b039485161790559186168152908690526040812055600185018054806108a1576108a1610fc1565b600082815260209020810160001990810180546001600160a01b03191690550190555050505050565b6108db816108d661078e565b610b63565b50565b6108e8828261060a565b610470576000828152602081815260408083206001600160a01b03851684529091529020805460ff1916600117905561091f61078e565b6001600160a01b0316816001600160a01b0316837f2f8788117e7eff1d82e926ec794901d17c78024a50270940304540a733656f0d60405160405180910390a45050565b61096d828261060a565b15610470576000828152602081815260408083206001600160a01b03851684529091529020805460ff191690556109a261078e565b6001600160a01b0316816001600160a01b0316837ff6391f5c32d9c69d2a47ea670b442974b53935d1edc7fd64eb21e047a839171b60405160405180910390a45050565b60008260010182815481106109fd576109fd610fab565b6000918252602090912001546001600160a01b03169392505050565b60018201546000908103610a2f57506000610311565b6001600160a01b0382166000818152602085905260409020546001850180549091908110610a5f57610a5f610fab565b6000918252602090912001546001600160a01b0316149392505050565b610a868383610a19565b15610ac657604080518082018252600a8152691059191c995cdcd4d95d60b21b60208201529051633bce1ae360e01b815261045d91908390600401610fd7565b6001838101805480830182556000828152602090200180546001600160a01b0319166001600160a01b03861617905554610b009190610f94565b6001600160a01b03909216600090815260209390935250604090912055565b60007f00000000000000000000000000000000000000000000000000000000000000006001600160a01b03163303610b5e575060131936013560601c90565b503390565b610b6d828261060a565b61047057610b7a81610bbc565b610b85836020610bce565b604051602001610b9692919061103c565b60408051601f198184030181529082905262461bcd60e51b825261045d916004016110b1565b60606103116001600160a01b03831660145b60606000610bdd8360026110c4565b610be89060026110e3565b67ffffffffffffffff811115610c0057610c006110fb565b6040519080825280601f01601f191660200182016040528015610c2a576020820181803683370190505b509050600360fc1b81600081518110610c4557610c45610fab565b60200101906001600160f81b031916908160001a905350600f60fb1b81600181518110610c7457610c74610fab565b60200101906001600160f81b031916908160001a9053506000610c988460026110c4565b610ca39060016110e3565b90505b6001811115610d1b576f181899199a1a9b1b9c1cb0b131b232b360811b85600f1660108110610cd757610cd7610fab565b1a60f81b828281518110610ced57610ced610fab565b60200101906001600160f81b031916908160001a90535060049490941c93610d1481611111565b9050610ca6565b5083156104b75760405162461bcd60e51b815260206004820181905260248201527f537472696e67733a20686578206c656e67746820696e73756666696369656e74604482015260640161045d565b600060208284031215610d7c57600080fd5b81356001600160e01b0319811681146104b757600080fd5b80356001600160a01b0381168114610dab57600080fd5b919050565b600060208284031215610dc257600080fd5b6104b782610d94565b600060208284031215610ddd57600080fd5b5035919050565b60008060408385031215610df757600080fd5b82359150610e0760208401610d94565b90509250929050565b60008060408385031215610e2357600080fd5b610e2c83610d94565b946020939093013593505050565b600060208284031215610e4c57600080fd5b813563ffffffff811681146104b757600080fd5b60008060408385031215610e7357600080fd5b610e7c83610d94565b9150610e0760208401610d94565b600060208284031215610e9c57600080fd5b815180151581146104b757600080fd5b60005b83811015610ec7578181015183820152602001610eaf565b83811115610ed6576000848401525b50505050565b60008151808452610ef4816020860160208601610eac565b601f01601f19169290920160200192915050565b608081526000610f1b6080830185610edc565b828103806020850152600682526572656d6f766560d01b6020830152604081016040850152600e60408301526d191bd95cc81b9bdd08195e1a5cdd60921b606083015260808101606085015250610f756080820185610edc565b95945050505050565b634e487b7160e01b600052601160045260246000fd5b600082821015610fa657610fa6610f7e565b500390565b634e487b7160e01b600052603260045260246000fd5b634e487b7160e01b600052603160045260246000fd5b608081526000610fea6080830185610edc565b82810380602085015260068252651a5b9cd95c9d60d21b6020830152604081016040850152600660408301526565786973747360d01b606083015260808101606085015250610f756080820185610edc565b7f416363657373436f6e74726f6c3a206163636f756e7420000000000000000000815260008351611074816017850160208801610eac565b7001034b99036b4b9b9b4b733903937b6329607d1b60179184019182015283516110a5816028840160208801610eac565b01602801949350505050565b6020815260006104b76020830184610edc565b60008160001904831182151516156110de576110de610f7e565b500290565b600082198211156110f6576110f6610f7e565b500190565b634e487b7160e01b600052604160045260246000fd5b60008161112057611120610f7e565b50600019019056fe55736572506f6c69636965733a61646454726164657257686974656c6973746564a26469706673582212207603a0aeae000b1348aa057371ec71a9d8c146322d1bb7035879829b5f36daab64736f6c634300080e0033";

type UserPoliciesConstructorParams =
  | [signer?: Signer]
  | ConstructorParameters<typeof ContractFactory>;

const isSuperArgs = (
  xs: UserPoliciesConstructorParams
): xs is ConstructorParameters<typeof ContractFactory> => xs.length > 1;

export class UserPolicies__factory extends ContractFactory {
  constructor(...args: UserPoliciesConstructorParams) {
    if (isSuperArgs(args)) {
      super(...args);
    } else {
      super(_abi, _bytecode, args[0]);
    }
    this.contractName = "UserPolicies";
  }

  override deploy(
    trustedForwarder: PromiseOrValue<string>,
    policyManager_: PromiseOrValue<string>,
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): Promise<UserPolicies> {
    return super.deploy(
      trustedForwarder,
      policyManager_,
      overrides || {}
    ) as Promise<UserPolicies>;
  }
  override getDeployTransaction(
    trustedForwarder: PromiseOrValue<string>,
    policyManager_: PromiseOrValue<string>,
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): TransactionRequest {
    return super.getDeployTransaction(
      trustedForwarder,
      policyManager_,
      overrides || {}
    );
  }
  override attach(address: string): UserPolicies {
    return super.attach(address) as UserPolicies;
  }
  override connect(signer: Signer): UserPolicies__factory {
    return super.connect(signer) as UserPolicies__factory;
  }
  static readonly contractName: "UserPolicies";

  public readonly contractName: "UserPolicies";

  static readonly bytecode = _bytecode;
  static readonly abi = _abi;
  static createInterface(): UserPoliciesInterface {
    return new utils.Interface(_abi) as UserPoliciesInterface;
  }
  static connect(
    address: string,
    signerOrProvider: Signer | Provider
  ): UserPolicies {
    return new Contract(address, _abi, signerOrProvider) as UserPolicies;
  }
}