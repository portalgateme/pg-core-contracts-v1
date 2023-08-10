// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MockWalletCheck {
  uint256 private _birthday;

  function setBirthday(uint256 value) public {
    _birthday = value;
  }

  function birthday() public view returns (uint256) {
    return _birthday;
  }
}
