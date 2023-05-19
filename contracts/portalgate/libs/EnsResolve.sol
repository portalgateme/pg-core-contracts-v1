// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@ensdomains/ens-contracts/contracts/registry/ENS.sol";
import "@ensdomains/ens-contracts/contracts/resolvers/Resolver.sol";

contract EnsResolve {
    address Registry = 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512;

    address constant MAINNET_REGISTRY_ADDRESS =
        0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e;
    address constant GOERLI_REGISTRY_ADDRESS =
        0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e;
    address constant PRIVATE_REGISTRY_ADDRESS =
        0x5FbDB2315678afecb367f032d93F642f64180aa3;

    function getRegistryAddress() public view returns (address) {
        uint chainId = getChainId();
        if (chainId == 1) {
            return MAINNET_REGISTRY_ADDRESS;
        } else if (chainId == 5) {
            return GOERLI_REGISTRY_ADDRESS;
        }
        return PRIVATE_REGISTRY_ADDRESS;
    }

    function resolve(bytes32 node) public view virtual returns (address) {
        ENS ENSRegistry = ENS(getRegistryAddress());
        Resolver _res = Resolver(ENSRegistry.resolver(node));

        return address(_res.addr(node));
    }

    function bulkResolve(
        bytes32[] memory domains
    ) public view returns (address[] memory result) {
        result = new address[](domains.length);
        for (uint256 i = 0; i < domains.length; i++) {
            result[i] = resolve(domains[i]);
        }
    }

    function getChainId() internal view returns (uint256) {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        return chainId;
    }
}
