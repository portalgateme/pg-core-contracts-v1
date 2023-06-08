// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../tornado-core/TornadoTrees.sol";

import "hardhat/console.sol";

contract MockTornadoTrees is TornadoTrees {
  uint256 public timestamp;
  uint256 public currentBlock;

  constructor(
    address _pgRouter,
    address _hasher2,
    address _hasher3,
    uint32 _levels
  ) TornadoTrees(_pgRouter, _hasher2, _hasher3, _levels) {}

  function setBlockNumber(uint256 _blockNumber) public {
    console.log("setBlockNumber", _blockNumber);
    currentBlock = _blockNumber;
  }

  function blockNumber() public view override returns (uint256) {
    return currentBlock == 0 ? block.number : currentBlock;
  }
}
