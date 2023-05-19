// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.14;

interface IIdentityTree {

    error Unacceptable(string reason);

    event SetMerkleRootBirthday(bytes32 merkleRoot, uint256 birthday);

    function ROLE_AGGREGATOR() external view returns (bytes32);

    function merkleRootBirthday(bytes32 root) external view returns (uint);
    
    function setMerkleRootBirthday(bytes32 root, uint256 birthday) external;

    function merkleRootCount() external view returns (uint256 count);

    function merkleRootAtIndex(uint256 index) external view returns (bytes32 merkleRoot);

    function isMerkleRoot(bytes32 merkleRoot) external view returns (bool isIndeed);

    function merkleRootSuccessors(bytes32 merkleRoot) external view returns (uint256 successors);

    function latestBirthday() external view returns (uint256 birthday);

    function latestRoot() external view returns (bytes32 root);
}
