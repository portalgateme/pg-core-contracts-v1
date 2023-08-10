// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MockUserPolicies {
  uint32 private _userPolicyId;
  bool private _isWhitelisted = true;

  function setUserPolicyId(uint32 id) public {
    _userPolicyId = id;
  }

  function setIsWhitelisted(bool value) public {
    _isWhitelisted = value;
  }

  function userPolicies() public view returns (uint32) {
    return _userPolicyId;
  }

  function isWhitelisted() public view returns (bool) {
    return _isWhitelisted;
  }
}
