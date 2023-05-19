// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.14;

/// @title Verifier interface.
/// @dev Interface of Verifier contract.

interface IIdentityMembershipProofVerifier {

    function verifyProof(
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint256[4] memory input
    ) external view;
}
