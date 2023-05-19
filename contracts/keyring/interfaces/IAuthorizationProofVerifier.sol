// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.14;

interface IAuthorizationProofVerifier {

    function verifyProof(
        uint256[2] calldata a,
        uint256[2][2] calldata b,
        uint256[2] calldata c,
        uint256[5] calldata input
    ) external view returns (bool);
}
