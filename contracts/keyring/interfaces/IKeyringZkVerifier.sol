// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.14;

interface IKeyringZkVerifier {
    
    error Unacceptable(string reason);

    event Deployed(
        address deployer,         
        address identityConstructionProofVerifier,
        address membershipProofVerifier,
        address authorisationProofVerifier);
    
    function IDENTITY_MEMBERSHIP_PROOF_VERIFIER() external returns (address);

    function IDENTITY_CONSTRUCTION_PROOF_VERIFIER() external returns (address);

    function AUTHORIZATION_PROOF_VERIFIER() external returns (address);

    struct Groth16Proof {
        uint256[2] a;
        uint256[2][2] b;
        uint256[2] c;
    }

    struct IdentityConstructionProof {
        Groth16Proof proof;
        uint256 identity;
        uint256 policyCommitment;
        uint256 maxAddresses;
    }

    struct IdentityMembershipProof {
        Groth16Proof proof;
        uint256 root;
        uint256 nullifierHash;
        uint256 signalHash;
        uint256 externalNullifier;
    }

    struct IdentityAuthorisationProof {
        Groth16Proof proof;
        uint256 externalNullifier;
        uint256 nullifierHash;
        uint256[2] policyDisclosures;
        uint256 tradingAddress;
    }

    function checkClaim(
        IdentityMembershipProof calldata membershipProof,
        IdentityAuthorisationProof calldata authorisationProof
    ) external view returns (bool verified);

    function checkIdentityConstructionProof(IdentityConstructionProof calldata constructionProof)
        external
        view
        returns (bool verified);

    function checkIdentityMembershipProof(IdentityMembershipProof calldata membershipProof)
        external
        view
        returns (bool verified);

    function checkIdentityAuthorisationProof(IdentityAuthorisationProof calldata authorisationProof)
        external
        view
        returns (bool verified);
}
