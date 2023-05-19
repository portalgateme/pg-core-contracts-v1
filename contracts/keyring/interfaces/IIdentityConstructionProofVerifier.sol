// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.14;

interface IIdentityConstructionProofVerifier {

    function verifyProof(
        uint[2] memory a,
        uint[2][2] memory b,
        uint[2] memory c,
        uint[3] memory input
    ) external view returns (bool r);

}
