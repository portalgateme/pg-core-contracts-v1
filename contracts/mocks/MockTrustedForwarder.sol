// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

contract MockTrustedForwarder {
  function execute(address to, bytes memory data) external {
    (bool success, ) = to.call(data);
    require(success, "Call failed");
  }

  function isTrustedForwarder(address) external pure returns(bool) {
    return true;
  }
}
