/* Autogenerated file. Do not edit manually. */
/* tslint:disable */
/* eslint-disable */
import {
  Signer,
  utils,
  Contract,
  ContractFactory,
  BytesLike,
  Overrides,
} from "ethers";
import type { Provider, TransactionRequest } from "@ethersproject/providers";
import type { PromiseOrValue } from "../../../../common";
import type {
  MockRuleRegistry,
  MockRuleRegistryInterface,
} from "../../../../contracts/keyring/mocks/MockRuleRegistry";

const _abi = [
  {
    inputs: [
      {
        internalType: "address",
        name: "trustedForwarder",
        type: "address",
      },
      {
        internalType: "bytes32",
        name: "universeRule",
        type: "bytes32",
      },
      {
        internalType: "bytes32",
        name: "emptyRule",
        type: "bytes32",
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
    name: "SetConsistency",
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
        name: "user",
        type: "address",
      },
      {
        indexed: true,
        internalType: "bytes32",
        name: "ruleId",
        type: "bytes32",
      },
      {
        indexed: false,
        internalType: "string",
        name: "description",
        type: "string",
      },
      {
        indexed: false,
        internalType: "string",
        name: "uri",
        type: "string",
      },
      {
        indexed: false,
        internalType: "bool",
        name: "toxic",
        type: "bool",
      },
      {
        indexed: false,
        internalType: "enum IRuleRegistry.Operator",
        name: "operator",
        type: "uint8",
      },
      {
        indexed: false,
        internalType: "bytes32[]",
        name: "operands",
        type: "bytes32[]",
      },
    ],
    name: "CreateRule",
    type: "event",
  },
  {
    anonymous: false,
    inputs: [
      {
        indexed: false,
        internalType: "uint8",
        name: "version",
        type: "uint8",
      },
    ],
    name: "Initialized",
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
        indexed: false,
        internalType: "address",
        name: "deployer",
        type: "address",
      },
      {
        indexed: false,
        internalType: "address",
        name: "trustedForwarder",
        type: "address",
      },
    ],
    name: "RuleRegistryDeployed",
    type: "event",
  },
  {
    anonymous: false,
    inputs: [
      {
        indexed: false,
        internalType: "address",
        name: "admin",
        type: "address",
      },
      {
        indexed: false,
        internalType: "string",
        name: "universeDescription",
        type: "string",
      },
      {
        indexed: false,
        internalType: "string",
        name: "universeUri",
        type: "string",
      },
      {
        indexed: false,
        internalType: "string",
        name: "emptyDescription",
        type: "string",
      },
      {
        indexed: false,
        internalType: "string",
        name: "emptyUri",
        type: "string",
      },
      {
        indexed: false,
        internalType: "bytes32",
        name: "universeRule",
        type: "bytes32",
      },
      {
        indexed: false,
        internalType: "bytes32",
        name: "emptyRule",
        type: "bytes32",
      },
    ],
    name: "RuleRegistryInitialized",
    type: "event",
  },
  {
    anonymous: false,
    inputs: [
      {
        indexed: false,
        internalType: "address",
        name: "admin",
        type: "address",
      },
      {
        indexed: false,
        internalType: "bytes32",
        name: "ruleId",
        type: "bytes32",
      },
      {
        indexed: false,
        internalType: "bool",
        name: "isToxic",
        type: "bool",
      },
    ],
    name: "SetToxic",
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
    inputs: [],
    name: "ROLE_RULE_ADMIN",
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
        internalType: "string",
        name: "description",
        type: "string",
      },
      {
        internalType: "string",
        name: "uri",
        type: "string",
      },
      {
        internalType: "enum IRuleRegistry.Operator",
        name: "operator",
        type: "uint8",
      },
      {
        internalType: "bytes32[]",
        name: "operands",
        type: "bytes32[]",
      },
    ],
    name: "createRule",
    outputs: [
      {
        internalType: "bytes32",
        name: "ruleId",
        type: "bytes32",
      },
    ],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "string",
        name: "description",
        type: "string",
      },
      {
        internalType: "enum IRuleRegistry.Operator",
        name: "operator",
        type: "uint8",
      },
      {
        internalType: "bytes32[]",
        name: "operands",
        type: "bytes32[]",
      },
    ],
    name: "generateRuleId",
    outputs: [
      {
        internalType: "bytes32",
        name: "ruleId",
        type: "bytes32",
      },
    ],
    stateMutability: "pure",
    type: "function",
  },
  {
    inputs: [],
    name: "genesis",
    outputs: [
      {
        internalType: "bytes32",
        name: "universeRuleId",
        type: "bytes32",
      },
      {
        internalType: "bytes32",
        name: "emptyRuleId",
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
        internalType: "string",
        name: "universeDescription",
        type: "string",
      },
      {
        internalType: "string",
        name: "universeUri",
        type: "string",
      },
      {
        internalType: "string",
        name: "emptyDescription",
        type: "string",
      },
      {
        internalType: "string",
        name: "emptyUri",
        type: "string",
      },
    ],
    name: "init",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "bytes32",
        name: "",
        type: "bytes32",
      },
    ],
    name: "isRule",
    outputs: [
      {
        internalType: "bool",
        name: "isIndeed",
        type: "bool",
      },
    ],
    stateMutability: "pure",
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
        internalType: "bytes32",
        name: "ruleId",
        type: "bytes32",
      },
    ],
    name: "rule",
    outputs: [
      {
        internalType: "string",
        name: "description",
        type: "string",
      },
      {
        internalType: "string",
        name: "uri",
        type: "string",
      },
      {
        internalType: "enum IRuleRegistry.Operator",
        name: "operator",
        type: "uint8",
      },
      {
        internalType: "uint256",
        name: "operandCount",
        type: "uint256",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "uint256",
        name: "index",
        type: "uint256",
      },
    ],
    name: "ruleAtIndex",
    outputs: [
      {
        internalType: "bytes32",
        name: "ruleId",
        type: "bytes32",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [],
    name: "ruleCount",
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
  {
    inputs: [
      {
        internalType: "bytes32",
        name: "ruleId",
        type: "bytes32",
      },
    ],
    name: "ruleDescription",
    outputs: [
      {
        internalType: "string",
        name: "description",
        type: "string",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "bytes32",
        name: "ruleId",
        type: "bytes32",
      },
    ],
    name: "ruleIsToxic",
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
    inputs: [
      {
        internalType: "bytes32",
        name: "ruleId",
        type: "bytes32",
      },
      {
        internalType: "uint256",
        name: "index",
        type: "uint256",
      },
    ],
    name: "ruleOperandAtIndex",
    outputs: [
      {
        internalType: "bytes32",
        name: "operandId",
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
        name: "ruleId",
        type: "bytes32",
      },
    ],
    name: "ruleOperandCount",
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
  {
    inputs: [
      {
        internalType: "bytes32",
        name: "ruleId",
        type: "bytes32",
      },
    ],
    name: "ruleOperator",
    outputs: [
      {
        internalType: "enum IRuleRegistry.Operator",
        name: "operator",
        type: "uint8",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "bytes32",
        name: "ruleId",
        type: "bytes32",
      },
    ],
    name: "ruleUri",
    outputs: [
      {
        internalType: "string",
        name: "uri",
        type: "string",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "bytes32",
        name: "ruleId",
        type: "bytes32",
      },
      {
        internalType: "bool",
        name: "toxic",
        type: "bool",
      },
    ],
    name: "setToxic",
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
] as const;

const _bytecode =
  "0x60a06040523480156200001157600080fd5b50604051620024523803806200245283398101604081905262000034916200014d565b6001600160a01b03831660808190526200009557604051636415329d60e01b815260206004820181905260248201527f74727573746564466f727761726465722063616e6e6f7420626520656d707479604482015260640160405180910390fd5b603482905560358190557f8f65ddb11b939f5c17babddb9f0a549eaec5159f02d51dbc0e913653c4bb569a620000ca620000f5565b604080516001600160a01b03928316815291861660208301520160405180910390a150505062000192565b60006200010c6200011160201b62000ff91760201c565b905090565b6080516000906001600160a01b0316330362000134575060131936013560601c90565b6200010c6200014960201b6200103d1760201c565b3390565b6000806000606084860312156200016357600080fd5b83516001600160a01b03811681146200017b57600080fd5b602085015160409095015190969495509392505050565b60805161229d620001b5600039600081816102760152610ffd015261229d6000f3fe608060405234801561001057600080fd5b50600436106101585760003560e01c806391d14854116100c3578063c77c12d81161007c578063c77c12d81461035d578063d171d13114610370578063d547741f14610390578063d5e22949146103a3578063e491f5c7146103b6578063f6bcf633146103c957600080fd5b806391d14854146102ec578063a217fddf146102ff578063a7f0b3de14610307578063a83ed2b114610322578063b1e6275414610335578063c416f1921461034a57600080fd5b806333081d851161011557806333081d851461022c57806336568abe14610240578063432295db14610253578063572b6c051461026657806368e956ff146102a65780638de12845146102d957600080fd5b806301ffc9a71461015d578063053b12431461018557806314d0cff3146101a65780631856c709146101d1578063248a9ca3146101f45780632f2ff15d14610217575b600080fd5b61017061016b366004611750565b6103d1565b60405190151581526020015b60405180910390f35b61019861019336600461177a565b610408565b60405190815260200161017c565b6101706101b436600461179c565b600090815260386020526040902060040154610100900460ff1690565b6101e46101df36600461179c565b610487565b60405161017c9493929190611845565b61019861020236600461179c565b60009081526020819052604090206001015490565b61022a6102253660046118a5565b6105dd565b005b61017061023a36600461179c565b50600190565b61022a61024e3660046118a5565b610607565b61022a6102613660046118d1565b610695565b610170610274366004611906565b7f00000000000000000000000000000000000000000000000000000000000000006001600160a01b0390811691161490565b6102cc6102b436600461179c565b60009081526038602052604090206004015460ff1690565b60405161017c9190611921565b61022a6102e7366004611978565b610746565b6101706102fa3660046118a5565b610b1c565b610198600081565b6034546035546040805192835260208301919091520161017c565b61019861033036600461179c565b610b45565b61019860008051602061224883398151915281565b610198610358366004611b82565b610b9a565b61019861036b36600461179c565b610eab565b61038361037e36600461179c565b610ec2565b60405161017c9190611c1b565b61022a61039e3660046118a5565b610f64565b6103836103b136600461179c565b610f89565b6101986103c4366004611c2e565b610fa9565b603754610198565b60006001600160e01b03198216637965db0b60e01b148061040257506301ffc9a760e01b6001600160e01b03198316145b92915050565b60008281526038602052604081206003810154831061046457604051636415329d60e01b8152602060048201526012602482015271696e646578206f7574206f662072616e676560701b60448201526064015b60405180910390fd5b600084815260386020526040902061047f9060020184611041565b949350505050565b6000818152603860205260408120600481015460038201546060938493909283928291600183019160ff909116908380546104c190611ca2565b80601f01602080910402602001604051908101604052809291908181526020018280546104ed90611ca2565b801561053a5780601f1061050f5761010080835404028352916020019161053a565b820191906000526020600020905b81548152906001019060200180831161051d57829003601f168201915b5050505050935082805461054d90611ca2565b80601f016020809104026020016040519081016040528092919081815260200182805461057990611ca2565b80156105c65780601f1061059b576101008083540402835291602001916105c6565b820191906000526020600020905b8154815290600101906020018083116105a957829003601f168201915b505050505092509450945094509450509193509193565b6000828152602081905260409020600101546105f88161106b565b610602838361107f565b505050565b61060f611104565b6001600160a01b0316816001600160a01b0316146106875760405162461bcd60e51b815260206004820152602f60248201527f416363657373436f6e74726f6c3a2063616e206f6e6c792072656e6f756e636560448201526e103937b632b9903337b91039b2b63360891b606482015260840161045b565b610691828261110e565b5050565b6106cd6000805160206122488339815191526106af611104565b6040518060600160405280603e81526020016121bd603e9139611191565b6000828152603860205260409020600401805461ff001916610100831515021790557f6d006190d6d91ada31527fd3f12566ada4f8c5d3dc0612d633cbd506415b5c00610718611104565b604080516001600160a01b039092168252602082018590528315159082015260600160405180910390a15050565b603354610100900460ff16158080156107665750603354600160ff909116105b806107805750303b158015610780575060335460ff166001145b6107e35760405162461bcd60e51b815260206004820152602e60248201527f496e697469616c697a61626c653a20636f6e747261637420697320616c72656160448201526d191e481a5b9a5d1a585b1a5e995960921b606482015260840161045b565b6033805460ff191660011790558015610806576033805461ff0019166101001790555b6060600089900361086657604051636415329d60e01b815260206004820152602360248201527f756e6976657273654465736372697074696f6e2063616e6e6f7420626520656d60448201526270747960e81b606482015260840161045b565b60008790036108b857604051636415329d60e01b815260206004820152601b60248201527f756e6976657273655572692063616e6e6f7420626520656d7074790000000000604482015260640161045b565b600085900361090a57604051636415329d60e01b815260206004820181905260248201527f656d7074794465736372697074696f6e2063616e6e6f7420626520656d707479604482015260640161045b565b600083900361095c57604051636415329d60e01b815260206004820152601860248201527f656d7074795572692063616e6e6f7420626520656d7074790000000000000000604482015260640161045b565b61096e6000610969611104565b61107f565b610988600080516020612248833981519152610969611104565b6109fd8a8a8080601f01602080910402602001604051908101604052809392919081815260200183838082843760009201919091525050604080516020601f8e018190048102820181019092528c815292508c91508b908190840183828082843760009201829052509250869150610b9a9050565b603455604080516020601f8801819004810282018101909252868152610a7391889088908190840183828082843760009201919091525050604080516020601f8a01819004810282018101909252888152925088915087908190840183828082843760009201829052509250869150610b9a9050565b6035557f3cfe457c1d4437ed182d8c96078fd62bf83d3084fcedfdc6ecfdda283358fb87610a9f611104565b603454603554604051610ac293928f928f928f928f928f928f928f928f92611d05565b60405180910390a1508015610b11576033805461ff0019169055604051600181527f7f26b83ff96e1f2b6a682f133852f6798a09c465da95921460cefb38474024989060200160405180910390a15b505050505050505050565b6000918252602082815260408084206001600160a01b0393909316845291905290205460ff1690565b6037546000908210610b8f57604051636415329d60e01b8152602060048201526012602482015271696e646578206f7574206f662072616e676560701b604482015260640161045b565b610402603683611041565b600080836003811115610baf57610baf61180d565b03610bec57610bec600080516020612248833981519152610bce611104565b6040518060800160405280604d815260200161209f604d9139611191565b610bf985858585516111be565b610c04858484610fa9565b9050610c2c8160405180606001604052806031815260200161218c60319139603691906113d1565b600081815260386020908152604090912086519091610c4f9183918901906116b7565b5060048101805485919060ff19166001836003811115610c7157610c7161180d565b02179055508451610c8b90600183019060208801906116b7565b50600080805b8551811015610e365782868281518110610cad57610cad611d82565b602002602001015111610d1f57604051636415329d60e01b815260206004820152603360248201527f6f706572616e6473206d757374206265206465636c6172656420696e2061736360448201527232b73234b73390393ab632a4b21037b93232b960691b606482015260840161045b565b610d3c868281518110610d3457610d34611d82565b506001919050565b610d7d57604051636415329d60e01b81526020600482015260116024820152701bdc195c985b99081b9bdd08199bdd5b99607a1b604482015260640161045b565b858181518110610d8f57610d8f611d82565b6020026020010151925081610de357610dd9868281518110610db357610db3611d82565b602002602001015160009081526038602052604090206004015460ff6101009091041690565b15610de357600191505b610e24868281518110610df857610df8611d82565b60200260200101516040518060600160405280602e815260200161215e602e91396002870191906113d1565b80610e2e81611dae565b915050610c91565b508015610e4f5760048301805461ff0019166101001790555b83610e58611104565b6001600160a01b03167fbc948abe89e3a1aa059c52741468a8f33ee3a3fd23a984b2904ff20ba14bc2fc8a8a858b8b604051610e98959493929190611dc7565b60405180910390a3505050949350505050565b600081815260386020526040812060030154610402565b6000818152603860205260409020805460609190610edf90611ca2565b80601f0160208091040260200160405190810160405280929190818152602001828054610f0b90611ca2565b8015610f585780601f10610f2d57610100808354040283529160200191610f58565b820191906000526020600020905b815481529060010190602001808311610f3b57829003601f168201915b50505050509050919050565b600082815260208190526040902060010154610f7f8161106b565b610602838361110e565b6000818152603860205260409020600101805460609190610edf90611ca2565b60008151600003610fc1575082516020840120610fed565b8282604051602001610fd4929190611e47565b6040516020818303038152906040528051906020012090505b9392505050565b905090565b60007f00000000000000000000000000000000000000000000000000000000000000006001600160a01b03163303611038575060131936013560601c90565b503390565b3390565b600082600101828154811061105857611058611d82565b9060005260206000200154905092915050565b61107c81611077611104565b611445565b50565b6110898282610b1c565b610691576000828152602081815260408083206001600160a01b03851684529091529020805460ff191660011790556110c0611104565b6001600160a01b0316816001600160a01b0316837f2f8788117e7eff1d82e926ec794901d17c78024a50270940304540a733656f0d60405160405180910390a45050565b6000610ff4610ff9565b6111188282610b1c565b15610691576000828152602081815260408083206001600160a01b03851684529091529020805460ff1916905561114d611104565b6001600160a01b0316816001600160a01b0316837ff6391f5c32d9c69d2a47ea670b442974b53935d1edc7fd64eb21e047a839171b60405160405180910390a45050565b61119b8383610b1c565b6106025781838260405163e77d8f6160e01b815260040161045b93929190611ea5565b60038260038111156111d2576111d261180d565b036112055780600114611200576112006040518060600160405280602881526020016120ec6028913961149e565b61128b565b60018260038111156112195761121961180d565b036112485760028110156112005761120060405180606001604052806024815260200161213a6024913961149e565b600282600381111561125c5761125c61180d565b0361128b57600281101561128b5761128b6040518060600160405280602b815260200161221d602b913961149e565b600082600381111561129f5761129f61180d565b14611316578351156112cc576112cc6040518060600160405280602681526020016121146026913961149e565b825115611311576113116040518060400160405280601e81526020017f6f6e6c7920626173652072756c65732063616e2068617665206120757269000081525061149e565b6113cb565b801561135a5761135a6040518060400160405280601f81526020017f626173652072756c65732063616e6e6f742068617665206f706572616e64730081525061149e565b8351600003611384576113846040518060600160405280602281526020016121fb6022913961149e565b82516000036113cb576113cb6040518060400160405280601a81526020017f626173652072756c6573206d757374206861766520612075726900000000000081525061149e565b50505050565b6113db83836114b9565b1561141b57604080518082018252600a815269109e5d195ccccc94d95d60b21b60208201529051632c03692760e21b815261045b91908390600401611f6d565b50600180830180546000848152602095865260408120829055928101825590825292902090910155565b61144f8282610b1c565b6106915761145c81611509565b61146783602061151b565b604051602001611478929190611fdb565b60408051601f198184030181529082905262461bcd60e51b825261045b91600401611c1b565b80604051636415329d60e01b815260040161045b9190611c1b565b600182015460009081036114cf57506000610402565b60008281526020849052604090205460018401805484929081106114f5576114f5611d82565b906000526020600020015414905092915050565b60606104026001600160a01b03831660145b6060600061152a836002612050565b61153590600261206f565b67ffffffffffffffff81111561154d5761154d611a3c565b6040519080825280601f01601f191660200182016040528015611577576020820181803683370190505b509050600360fc1b8160008151811061159257611592611d82565b60200101906001600160f81b031916908160001a905350600f60fb1b816001815181106115c1576115c1611d82565b60200101906001600160f81b031916908160001a90535060006115e5846002612050565b6115f090600161206f565b90505b6001811115611668576f181899199a1a9b1b9c1cb0b131b232b360811b85600f166010811061162457611624611d82565b1a60f81b82828151811061163a5761163a611d82565b60200101906001600160f81b031916908160001a90535060049490941c9361166181612087565b90506115f3565b508315610fed5760405162461bcd60e51b815260206004820181905260248201527f537472696e67733a20686578206c656e67746820696e73756666696369656e74604482015260640161045b565b8280546116c390611ca2565b90600052602060002090601f0160209004810192826116e5576000855561172b565b82601f106116fe57805160ff191683800117855561172b565b8280016001018555821561172b579182015b8281111561172b578251825591602001919060010190611710565b5061173792915061173b565b5090565b5b80821115611737576000815560010161173c565b60006020828403121561176257600080fd5b81356001600160e01b031981168114610fed57600080fd5b6000806040838503121561178d57600080fd5b50508035926020909101359150565b6000602082840312156117ae57600080fd5b5035919050565b60005b838110156117d05781810151838201526020016117b8565b838111156113cb5750506000910152565b600081518084526117f98160208601602086016117b5565b601f01601f19169290920160200192915050565b634e487b7160e01b600052602160045260246000fd5b6004811061184157634e487b7160e01b600052602160045260246000fd5b9052565b60808152600061185860808301876117e1565b828103602084015261186a81876117e1565b91505061187a6040830185611823565b82606083015295945050505050565b80356001600160a01b03811681146118a057600080fd5b919050565b600080604083850312156118b857600080fd5b823591506118c860208401611889565b90509250929050565b600080604083850312156118e457600080fd5b82359150602083013580151581146118fb57600080fd5b809150509250929050565b60006020828403121561191857600080fd5b610fed82611889565b602081016104028284611823565b60008083601f84011261194157600080fd5b50813567ffffffffffffffff81111561195957600080fd5b60208301915083602082850101111561197157600080fd5b9250929050565b6000806000806000806000806080898b03121561199457600080fd5b883567ffffffffffffffff808211156119ac57600080fd5b6119b88c838d0161192f565b909a50985060208b01359150808211156119d157600080fd5b6119dd8c838d0161192f565b909850965060408b01359150808211156119f657600080fd5b611a028c838d0161192f565b909650945060608b0135915080821115611a1b57600080fd5b50611a288b828c0161192f565b999c989b5096995094979396929594505050565b634e487b7160e01b600052604160045260246000fd5b604051601f8201601f1916810167ffffffffffffffff81118282101715611a7b57611a7b611a3c565b604052919050565b600082601f830112611a9457600080fd5b813567ffffffffffffffff811115611aae57611aae611a3c565b611ac1601f8201601f1916602001611a52565b818152846020838601011115611ad657600080fd5b816020850160208301376000918101602001919091529392505050565b8035600481106118a057600080fd5b600082601f830112611b1357600080fd5b8135602067ffffffffffffffff821115611b2f57611b2f611a3c565b8160051b611b3e828201611a52565b9283528481018201928281019087851115611b5857600080fd5b83870192505b84831015611b7757823582529183019190830190611b5e565b979650505050505050565b60008060008060808587031215611b9857600080fd5b843567ffffffffffffffff80821115611bb057600080fd5b611bbc88838901611a83565b95506020870135915080821115611bd257600080fd5b611bde88838901611a83565b9450611bec60408801611af3565b93506060870135915080821115611c0257600080fd5b50611c0f87828801611b02565b91505092959194509250565b602081526000610fed60208301846117e1565b600080600060608486031215611c4357600080fd5b833567ffffffffffffffff80821115611c5b57600080fd5b611c6787838801611a83565b9450611c7560208701611af3565b93506040860135915080821115611c8b57600080fd5b50611c9886828701611b02565b9150509250925092565b600181811c90821680611cb657607f821691505b602082108103611cd657634e487b7160e01b600052602260045260246000fd5b50919050565b81835281816020850137506000828201602090810191909152601f909101601f19169091010190565b6001600160a01b038c16815260e060208201819052600090611d2a9083018c8e611cdc565b8281036040840152611d3d818b8d611cdc565b90508281036060840152611d5281898b611cdc565b90508281036080840152611d67818789611cdc565b60a0840195909552505060c001529998505050505050505050565b634e487b7160e01b600052603260045260246000fd5b634e487b7160e01b600052601160045260246000fd5b600060018201611dc057611dc0611d98565b5060010190565b60a081526000611dda60a08301886117e1565b602083820381850152611ded82896117e1565b91508615156040850152611e046060850187611823565b838203608085015284518083528186019282019060005b81811015611e3757845183529383019391830191600101611e1b565b50909a9950505050505050505050565b600060048410611e6757634e487b7160e01b600052602160045260246000fd5b8360f81b825260018083018451602080870160005b83811015611e97578151855293820193908201908501611e7c565b509298975050505050505050565b60018060a01b038416815260c06020820152601460c08201527312d95e5c9a5b99d058d8d95cdcd0dbdb9d1c9bdb60621b60e08201526000610100806040840152600a8184015250695f636865636b526f6c6560b01b610120830152610140846060840152806080840152602681840152507f73656e64657220646f6573206e6f742068617665207468652072657175697265610160830152656420726f6c6560d01b6101808301526101a08060a0840152611f63818401856117e1565b9695505050505050565b608081526000611f8060808301856117e1565b82810380602085015260068252651a5b9cd95c9d60d21b6020830152604081016040850152600660408301526565786973747360d01b606083015260808101606085015250611fd260808201856117e1565b95945050505050565b7f416363657373436f6e74726f6c3a206163636f756e74200000000000000000008152600083516120138160178501602088016117b5565b7001034b99036b4b9b9b4b733903937b6329607d1b60179184019182015283516120448160288401602088016117b5565b01602801949350505050565b600081600019048311821515161561206a5761206a611d98565b500290565b6000821982111561208257612082611d98565b500190565b60008161209657612096611d98565b50600019019056fe52756c6552656769737472793a63726561746552756c653a206f6e6c79207468652052756c6541646d696e20726f6c652063616e20637265617465206f72206564697420626173652073657473636f6d706c656d656e74206d75737420686176652065786163746c79206f6e65206f706572616e646f6e6c7920626173652072756c65732063616e20686176652061206465736372697074696f6e756e696f6e206d75737420686176652074776f206f72206d6f7265206f706572616e647352756c6552656769737472793a63726561746552756c653a20353030206475706c6963617465206f706572616e6452756c6552656769737472793a63726561746552756c653a2067656e657261746564206475706c6963617465642069642e52756c6552656769737472793a736574546f7869633a206f6e6c79207468652052756c6541646d696e20726f6c652063616e20736574206973546f786963626173652072756c6573206d75737420686176652061206465736372697074696f6e696e74657273656374696f6e206d75737420686176652074776f206f72206d6f7265206f706572616e6473422fdaf494df115262347bf152b59ce2e4e0d0d8baa9f828fa6d6500f25a0aaca2646970667358221220656844007ec861fee9c6c11096ca6a6d746a0b758850fb550ac6faeed6b9149564736f6c634300080e0033";

type MockRuleRegistryConstructorParams =
  | [signer?: Signer]
  | ConstructorParameters<typeof ContractFactory>;

const isSuperArgs = (
  xs: MockRuleRegistryConstructorParams
): xs is ConstructorParameters<typeof ContractFactory> => xs.length > 1;

export class MockRuleRegistry__factory extends ContractFactory {
  constructor(...args: MockRuleRegistryConstructorParams) {
    if (isSuperArgs(args)) {
      super(...args);
    } else {
      super(_abi, _bytecode, args[0]);
    }
    this.contractName = "MockRuleRegistry";
  }

  override deploy(
    trustedForwarder: PromiseOrValue<string>,
    universeRule: PromiseOrValue<BytesLike>,
    emptyRule: PromiseOrValue<BytesLike>,
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): Promise<MockRuleRegistry> {
    return super.deploy(
      trustedForwarder,
      universeRule,
      emptyRule,
      overrides || {}
    ) as Promise<MockRuleRegistry>;
  }
  override getDeployTransaction(
    trustedForwarder: PromiseOrValue<string>,
    universeRule: PromiseOrValue<BytesLike>,
    emptyRule: PromiseOrValue<BytesLike>,
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): TransactionRequest {
    return super.getDeployTransaction(
      trustedForwarder,
      universeRule,
      emptyRule,
      overrides || {}
    );
  }
  override attach(address: string): MockRuleRegistry {
    return super.attach(address) as MockRuleRegistry;
  }
  override connect(signer: Signer): MockRuleRegistry__factory {
    return super.connect(signer) as MockRuleRegistry__factory;
  }
  static readonly contractName: "MockRuleRegistry";

  public readonly contractName: "MockRuleRegistry";

  static readonly bytecode = _bytecode;
  static readonly abi = _abi;
  static createInterface(): MockRuleRegistryInterface {
    return new utils.Interface(_abi) as MockRuleRegistryInterface;
  }
  static connect(
    address: string,
    signerOrProvider: Signer | Provider
  ): MockRuleRegistry {
    return new Contract(address, _abi, signerOrProvider) as MockRuleRegistry;
  }
}
