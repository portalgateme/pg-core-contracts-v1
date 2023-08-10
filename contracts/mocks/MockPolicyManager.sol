// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MockPolicyManager {
  bool private _isPolicy;
  bool private _hasRole;
  bytes32 private _policyRuleId;
  uint256 private _policyTtl;
  bool private _policyAllowUserWhitelists;
  address _ruleRegistry;
  address[] _walletChecks;

  function setIsPolicy(bool value) public {
    _isPolicy = value;
  }

  function setHasRole(bool value) public {
    _hasRole = value;
  }

  function setPolicyAllowUserWhitelists(bool value) public {
    _policyAllowUserWhitelists = value;
  }

  function setPolicyRuleId(bytes32 value) public {
    _policyRuleId = value;
  }

  function setPolicyTtl(uint256 value) public {
    _policyTtl = value;
  }

  function setRuleRegistry(address value) public {
    _ruleRegistry = value;
  }

  function setWalletChecks(address[] memory value) public {
    _walletChecks = value;
  }

  function isPolicy() public view returns (bool) {
    return _isPolicy;
  }

  function policyRuleId() public view returns (bytes32) {
    return _policyRuleId;
  }

  function policyTtl() public view returns (uint256) {
    return _policyTtl;
  }

  function policyAllowUserWhitelists() public view returns (bool) {
    return _policyAllowUserWhitelists;
  }

  function policyWalletChecks() public view returns (address[] memory) {
    return _walletChecks;
  }

  function hasRole() public view returns (bool) {
    return _hasRole;
  }

  function ruleRegistry() public view returns (address) {
    return _ruleRegistry;
  }
}
