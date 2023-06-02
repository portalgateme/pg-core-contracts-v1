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

  function userPolicies(address user) public view returns (uint32) {
    return _userPolicyId;
  }

  function isWhitelisted(address owner, address who) public view returns (bool) {
    return _isWhitelisted;
  }
}
