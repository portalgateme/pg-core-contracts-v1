// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MockRuleRegistry {
  bytes32 private _genesisRule1;
  bytes32 private _genesisRule2;

  function setGenesis(bytes32 rule1, bytes32 rule2) public {
    _genesisRule1 = rule1;
    _genesisRule2 = rule2;
  }

  function genesis() public view returns (bytes32, bytes32) {
    return (_genesisRule1, _genesisRule2);
  }
}
