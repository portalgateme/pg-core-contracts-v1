// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.14;

import "../interfaces/IAuthorizationProofVerifier.sol";
import "../interfaces/IIdentityConstructionProofVerifier.sol";
import "../interfaces/IIdentityMembershipProofVerifier.sol";
import "../interfaces/IKeyringZkVerifier.sol";

/**
 @notice Binds the on-chain zero-knowledge verifiers, which are generated from circuits, together and
 applies additional constraints such as requiring that users generate membership proofs and
 authorization proofs from the same identity commitments. Includes a function inspect identity
 commitments and confirm correct construction. This is presumed to occur before identity commitments
 are included in identity trees and is thus a courtesy function in service to the aggregator which is
 required to validate identity commitments submmitted by authorization wallets. 
 */

contract KeyringZkVerifier is IKeyringZkVerifier {

    address private constant NULL_ADDRESS = address(0);
    address public immutable override IDENTITY_MEMBERSHIP_PROOF_VERIFIER;
    address public immutable override IDENTITY_CONSTRUCTION_PROOF_VERIFIER;
    address public immutable override AUTHORIZATION_PROOF_VERIFIER;

    constructor(
        address identityConstructionProofVerifier,
        address membershipProofVerifier,
        address authorisationProofVerifier
    ) {
        if (identityConstructionProofVerifier == NULL_ADDRESS)
            revert Unacceptable({
                reason: "identityConstructionProofVerifier cannot be empty"
            });
        if (membershipProofVerifier == NULL_ADDRESS)
            revert Unacceptable({
                reason: "membershipProofVerifier cannot be empty"
            });
        if (authorisationProofVerifier == NULL_ADDRESS)
            revert Unacceptable({
                reason: "authorisationProofVerifier cannot be empty"
            });
        IDENTITY_CONSTRUCTION_PROOF_VERIFIER = identityConstructionProofVerifier;
        IDENTITY_MEMBERSHIP_PROOF_VERIFIER = membershipProofVerifier;
        AUTHORIZATION_PROOF_VERIFIER = authorisationProofVerifier;
        emit Deployed(
            msg.sender, 
            identityConstructionProofVerifier, 
            membershipProofVerifier, 
            authorisationProofVerifier);
    }

    /**
     @notice Check membership and authorization proofs using circom verifiers. Both proofs must be
     generated from the same identity commitment. 
     @param membershipProof Proof of inclusion in an identity tree.
     @param authorisationProof Proof of policyId inclusions in the identity commitment.
     @return verified True if the claim is valid. 
     */
    function checkClaim(
        IdentityMembershipProof calldata membershipProof,
        IdentityAuthorisationProof calldata authorisationProof
    ) external view override returns (bool verified) {
        if (!(membershipProof.nullifierHash == authorisationProof.nullifierHash)) return false;
        if (!checkIdentityMembershipProof(membershipProof)) return false;
        if (!checkIdentityAuthorisationProof(authorisationProof)) return false;
        return true;
    }

    /**
     @notice Check correct construction of an identity commitment.
     @param constructionProof Proof of correct construction of the identity commitment as defined in 
     IKeyringZkVerifier.
     @return verified True if the construction proof is valid.
     */
    function checkIdentityConstructionProof(IdentityConstructionProof calldata constructionProof)
        external
        view
        override
        returns (bool verified)
    {
        verified = IIdentityConstructionProofVerifier(IDENTITY_CONSTRUCTION_PROOF_VERIFIER).verifyProof(
            constructionProof.proof.a,
            constructionProof.proof.b,
            constructionProof.proof.c,
            [constructionProof.identity, constructionProof.policyCommitment, constructionProof.maxAddresses]
        );
    }

    /**
     @notice Check that the identity commitment is a member of the identity tree.
     @param membershipProof Proof of membership as defined in IKeyringZkVerifier.
     @return verified True if the identity commitment is a member of the identity tree.
     */
    function checkIdentityMembershipProof(IdentityMembershipProof calldata membershipProof)
        public
        view
        override
        returns (bool verified)
    {
        try
            IIdentityMembershipProofVerifier(IDENTITY_MEMBERSHIP_PROOF_VERIFIER).verifyProof(
                membershipProof.proof.a,
                membershipProof.proof.b,
                membershipProof.proof.c,
                [
                    membershipProof.root,
                    membershipProof.nullifierHash,
                    membershipProof.signalHash,
                    membershipProof.externalNullifier
                ]
            )
        {
            verified = true;
        } catch {
            verified = false;
        }
    }

    /**
     @notice Check that the policies disclosed are included in the identity commitment.
     @param authorisationProof Proof of authorisation as defined in IKeyringZkVerifier.
     @return verified True if the trader wallet is authorised for all policies in the disclosure.
     */
    function checkIdentityAuthorisationProof(IdentityAuthorisationProof calldata authorisationProof)
        public
        view
        override
        returns (bool verified)
    {
        verified = IAuthorizationProofVerifier(AUTHORIZATION_PROOF_VERIFIER).verifyProof(
                    authorisationProof.proof.a,
                    authorisationProof.proof.b,
                    authorisationProof.proof.c,
                    [
                        authorisationProof.externalNullifier,
                        authorisationProof.nullifierHash,
                        authorisationProof.policyDisclosures[0],
                        authorisationProof.policyDisclosures[1],
                        authorisationProof.tradingAddress
                    ]
                );
    }
}
