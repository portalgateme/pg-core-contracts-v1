// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../interfaces/ENSRegistry.sol";
import "../interfaces/ENSResolver.sol";
import "../interfaces/IRelayerRegistry.sol";

struct Relayer {
  uint256 balance;
  bool isRegistered;
}

contract RelayerAggregator {
  IRelayerRegistry public relayerRegistry;

  constructor(address _relayerRegistry) {
    relayerRegistry = IRelayerRegistry(_relayerRegistry);
  }

  function relayersData(address[] memory _relayers) public view returns (Relayer[] memory) {
    Relayer[] memory relayers = new Relayer[](_relayers.length);

    for (uint256 i = 0; i < _relayers.length; i++) {
      relayers[i].isRegistered = relayerRegistry.isRelayerRegistered(_relayers[i]);
      relayers[i].balance = 0;
    }

    return relayers;
  }
}
