// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./interfaces/ENSRegistry.sol";
import "./interfaces/ENSResolver.sol";
import "./interfaces/IRelayerRegistry.sol";

struct Relayer {
    address owner;
    uint256 balance;
    bool isRegistered;
    string[20] records;
}

contract RelayerAggregator {
    ENSRegistry public ensRegistry =
        ENSRegistry(0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e);
    IRelayerRegistry public relayerRegistry =
        IRelayerRegistry(0x099BAAEb4DA81Ef5719A95046690C8303F2d164C);

    function relayersData(
        bytes32[] memory _relayers,
        string[] memory _subdomains
    ) public view returns (Relayer[] memory) {
        Relayer[] memory relayers = new Relayer[](_relayers.length);

        for (uint256 i = 0; i < _relayers.length; i++) {
            relayers[i].owner = ensRegistry.owner(_relayers[i]);
            ENSResolver resolver = ENSResolver(
                ensRegistry.resolver(_relayers[i])
            );

            for (uint256 j = 0; j < _subdomains.length; j++) {
                bytes32 subdomainHash = keccak256(
                    abi.encodePacked(
                        _relayers[i],
                        keccak256(abi.encodePacked(_subdomains[j]))
                    )
                );
                relayers[i].records[j] = resolver.text(subdomainHash, "url");
            }

            relayers[i].isRegistered = relayerRegistry.isRelayerRegistered(_relayers[i]);
            relayers[i].balance = 0;
        }
        return relayers;
    }
}
