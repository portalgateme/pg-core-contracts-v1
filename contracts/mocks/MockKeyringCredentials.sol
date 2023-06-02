// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MockKeyringCredentials {
  uint256 private _credentialTimestamp;

  function setCredentialTimestamp(uint256 timestamp) public {
    _credentialTimestamp = timestamp;
  }

  function getCredential(uint8 version, address user, uint32 policyId)
  public
  view
  returns (uint256 timestamp)
  {
    return _credentialTimestamp;
  }
}
