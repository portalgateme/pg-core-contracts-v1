// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.14;

import "../interfaces/IIdentityTree.sol";
import "../access/KeyringAccessControl.sol";
import "../lib/Bytes32Set.sol";

/**
 @notice This contract holds the history of identity tree merkle roots announced by the aggregator. 
 Each root has an associated birthday that records when it was created. Zero-knowledge proofs rely
 on these roots. Claims supported by proofs are considered to be of the same age as the roots they
 rely on for validity. 
 */

contract IdentityTree is IIdentityTree, KeyringAccessControl { 

    using Bytes32Set for Bytes32Set.Set;

    uint256 private constant INFINITY = ~uint256(0);
    address private constant NULL_ADDRESS = address(0);
    bytes32 private constant NULL_BYTES32 = bytes32(0);
    bytes32 public constant override ROLE_AGGREGATOR = keccak256("aggregator role");

    mapping(bytes32 => uint256) public override merkleRootBirthday;
    Bytes32Set.Set merkleRootSet;

    modifier onlyAggregator() {
        _checkRole(ROLE_AGGREGATOR, _msgSender(), "IdentityTree::onlyAggregator");
        _;
    }

    /**
     @param trustedForwarder Contract address that is allowed to relay message signers.
     */
    constructor(address trustedForwarder) KeyringAccessControl(trustedForwarder) {
        if(trustedForwarder == NULL_ADDRESS)
            revert Unacceptable("trustedForwarder cannot be empty");
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /**
     * @notice The aggregator can set roots with non-zero birthdays.
     * @dev Explicit birthday declaration ensures that root age is not extended by mining delays. 
     * @param merkleRoot The merkleRoot to set.
     * @param birthday The timestamp of the merkleRoot. 0 to invalidate the root.
     */
    function setMerkleRootBirthday(bytes32 merkleRoot, uint256 birthday) external override onlyAggregator {
        if (birthday > block.timestamp)
            revert Unacceptable({
                reason: "birthday cannot be in the future"
            });
        if (merkleRoot == NULL_BYTES32)
            revert Unacceptable({
                reason: "merkle root cannot be empty"
            });
        if (birthday < latestBirthday()) 
            revert Unacceptable({
                reason: "birthday precedes previously recorded birthday"
            });
        merkleRootBirthday[merkleRoot] = birthday;
        merkleRootSet.insert(merkleRoot, "IdentityTree::setMerkleRoot");
        emit SetMerkleRootBirthday(merkleRoot, birthday);
    }

    /**
     * @return count The number of merkle roots recorded since the beginning
     */
    function merkleRootCount() public view override returns (uint256 count) {
        count = merkleRootSet.count();
    }

    /**
     * @notice Enumerate the recorded merkle roots.
     * @param index Row to return.
     * @return merkleRoot The root stored at the row.
     */
    function merkleRootAtIndex(uint256 index) external view override returns (bytes32 merkleRoot) {
        if (index >= merkleRootSet.count())
            revert Unacceptable({
                reason: "index"
            });
        merkleRoot = merkleRootSet.keyAtIndex(index);
    }

    /**
     * @notice Check for existence in history.
     * @param merkleRoot The root to check.
     * @return isIndeed True if the root has been recorded.
     */
    function isMerkleRoot(bytes32 merkleRoot) external view override returns (bool isIndeed) {
        isIndeed = merkleRootSet.exists(merkleRoot);
    }

    /**
     * @notice Returns the count of roots recorded after the root to inspect.
     * @dev Returns 2 ^ 256 - 1 if merkle root is not recorded.
     * @param merkleRoot The root to inspect.
     * @return successors The count of roots recorded after the root to inspect.
     */
    function merkleRootSuccessors(bytes32 merkleRoot) external view override returns (uint256 successors) {
        if (!merkleRootSet.exists(merkleRoot)) return INFINITY;
        successors = merkleRootSet.count() - merkleRootSet.keyPointers[merkleRoot] - 1;
    }

    /**
     @notice Return the latest birthday recorded.
     @return birthday The birthday of the latest root recorded.
     */
    function latestBirthday() public view override returns (uint256 birthday) {
        if (merkleRootSet.count() > 0) {
            birthday = merkleRootBirthday[merkleRootSet.keyAtIndex(merkleRootSet.count() - 1)];
        }
    }

    /**
     @notice Return the lastest merkle root recorded. 
     @return root The latest merkle root recorded.
     */
    function latestRoot() external view override returns (bytes32 root) {
        if (merkleRootSet.count() > 0) {
            root= merkleRootSet.keyAtIndex(merkleRootSet.count() - 1);
        }
    }
}
