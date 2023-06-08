// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "../tornado-core/MerkleTreeWithHistory.sol";

contract OwnableMerkleTree is Ownable, MerkleTreeWithHistory {
  constructor(uint32 _treeLevels, IHasher _hasher) MerkleTreeWithHistory(_treeLevels, _hasher) {}

  function insert(bytes32 _leaf) external onlyOwner returns (uint32 index) {
    return _insert(_leaf);
  }

  function bulkInsert(bytes32[] calldata _leaves) external onlyOwner {
    _bulkInsert(_leaves);
  }
}
