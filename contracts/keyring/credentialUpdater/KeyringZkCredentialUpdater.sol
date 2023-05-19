// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.14;

import "../interfaces/IKeyringZkCredentialUpdater.sol";
import "../interfaces/IPolicyManager.sol";
import "../interfaces/IKeyringCredentials.sol";
import "../interfaces/IIdentityTree.sol";
import "../interfaces/IRuleRegistry.sol";
import "../interfaces/IWalletCheck.sol";
import "../interfaces/IKeyringZkVerifier.sol";
import "../lib/Pack12x20.sol";
import "../access/KeyringAccessControl.sol";

/**
 @notice This contract acts as a credentials cache updater. It needs the ROLE_CREDENTIAL_UPDATER 
 permission in the KeyringCredentials contract in order to record credentials. The contract checks 
 client-generated zero-knowledge proofs of attestations about admission policy eligibility and 
 therefore enforces the protocol.
 */

contract KeyringZkCredentialUpdater is
    IKeyringZkCredentialUpdater,
    KeyringAccessControl
{
    using Pack12x20 for uint32[12];
    using Pack12x20 for uint256;

    address private constant NULL_ADDRESS = address(0);
    IRuleRegistry private immutable RULE_REGISTRY;
    address public immutable override POLICY_MANAGER;
    address public immutable override KEYRING_CREDENTIALS;
    address public immutable override KEYRING_ZK_VERIFIER;

    /**
     * @param trustedForwarder Contract address that is allowed to relay message signers.
     * @param keyringCredentials The address for the deployed KeyringCredentials contract to write to.
     * @param policyManager The address for the deployed PolicyManager contract to read from.
     * @param keyringZkVerifier On-chain instance of the stateless Keyring ZK verifier contract.
     */
    constructor(
        address trustedForwarder,
        address keyringCredentials,
        address policyManager,
        address keyringZkVerifier
    ) KeyringAccessControl(trustedForwarder) {
        if (trustedForwarder == NULL_ADDRESS)
            revert Unacceptable({
                reason: "trustedForwarder cannot be empty"
            });
        if (keyringCredentials == NULL_ADDRESS)
            revert Unacceptable({
                reason: "keyringCredentials cannot be empty"
            });
        if (policyManager == NULL_ADDRESS)
            revert Unacceptable({
                reason: "policyManager cannot be empty"
            });
        if (keyringZkVerifier == NULL_ADDRESS)
            revert Unacceptable({
                reason: "keyringZkVerifier cannot be empty"
            });
        RULE_REGISTRY = IRuleRegistry(IPolicyManager(policyManager).ruleRegistry());
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());

        POLICY_MANAGER = policyManager;
        KEYRING_CREDENTIALS = keyringCredentials;
        KEYRING_ZK_VERIFIER = keyringZkVerifier;
        
        emit CredentialUpdaterDeployed(
            _msgSender(),
            trustedForwarder,
            keyringCredentials,
            policyManager,
            keyringZkVerifier
        );
    }

    /**
     * @notice Updates the credential cache if the request is acceptable.
     * @dev The attestor must be valid for all policy disclosures. For this to be possible, it must have been admitted
     to the system globally before it was selected for a policy. The two zero-knowledge proof share parameters that 
     ensure that both proofs were derived from the same identity commitment. If the root age used to construct proofs
     if older than the policy time to live (ttl), the root will be considered acceptable with an age of zero, provided
     that the number of root successors is less than or equal to the policy acceptRoots (accept most recent n roots).
     Credential updates clear on-chain wallet checks and thus force an off-chain check and update.
     * @param attestor The identityTree contract with a root that contains the user's identity commitment. Must be 
     present in the current attestor list for all policy disclosures in the authorization proof. 
     * @param membershipProof A zero-knowledge proof of identity commitment membership in the identity tree. Contains an
     external nullifier and nullifier hash that must match the parameters of the authorization proof. 
     * @param authorizationProof A zero-knowledge proof of compliance with up to 24 policy disclosures. Contains an
     external nullifier and nullifier hash that must match the parameters of the membershiip proof. 
     */
    function updateCredentials(
        address attestor,
        IKeyringZkVerifier.IdentityMembershipProof calldata membershipProof,
        IKeyringZkVerifier.IdentityAuthorisationProof calldata authorizationProof
    ) external override {

        if (!IPolicyManager(POLICY_MANAGER).isGlobalAttestor(attestor))
            revert Unacceptable({ reason: "attestor unacceptable" });
        
        uint32 policyId;
        address sender = _msgSender();
        address trader = address(uint160(authorizationProof.tradingAddress));
        if (sender != trader)
            revert Unacceptable ({ reason: "only trader can update trader credentials" });
        bytes32 root = bytes32(membershipProof.root);

        uint32[12] memory policyList0 = unpack12x20(authorizationProof.policyDisclosures[0]);
        uint32[12] memory policyList1 = unpack12x20(authorizationProof.policyDisclosures[1]);

        if(!IKeyringZkVerifier(KEYRING_ZK_VERIFIER).checkClaim(
            membershipProof,
            authorizationProof
        )) revert Unacceptable({
                reason: "Proof unacceptable"});

        uint256 rootTime = IIdentityTree(attestor).merkleRootBirthday(root);
        
        for(uint256 i = 0; i < 24; i++) {

            policyId = (i / 12 == 0) ? policyList0[i % 12] : policyList1[i % 12];
            if(policyId == 0) break;
            
            if(!checkPolicy(policyId, attestor))
                revert Unacceptable({
                    reason: "policy or attestor unacceptable"
                });

            if(rootTime + IPolicyManager(POLICY_MANAGER).policyTtl(policyId) < block.timestamp) {
                uint256 ar = IPolicyManager(POLICY_MANAGER).policyAcceptRoots(policyId);
                if(IIdentityTree(attestor).merkleRootSuccessors(bytes32(membershipProof.root)) <= ar && ar > 0) {
                    IKeyringCredentials(KEYRING_CREDENTIALS).setCredential(
                        trader, 
                        policyId,                
                        block.timestamp);
                } else {
                    IKeyringCredentials(KEYRING_CREDENTIALS).setCredential(
                        trader, 
                        policyId,                
                        rootTime);                    
                }
            } else {
                IKeyringCredentials(KEYRING_CREDENTIALS).setCredential(
                    trader, 
                    policyId,                
                    rootTime);
            }
            
        }
        emit AcceptCredentialUpdate(
            sender, 
            trader, 
            membershipProof, 
            authorizationProof, 
            rootTime);
    }

  /**
     * @notice The identity tree must be a policy attestor and the policy rule cannot be toxic.
     * @dev Use static call to inspect response.
     * @param policyId The policy to inspect.
     * @param attestor The identity tree contract address to compare to the policy attestors.
     * @return acceptable True if the policy rule is not toxic and the identity tree is authoritative for the policy.
     */    
    function checkPolicy(
        uint32 policyId, 
        address attestor
    ) public override returns (bool acceptable)
    {
        IPolicyManager p = IPolicyManager(POLICY_MANAGER);
        if(!p.isPolicy(policyId)) return false;

        acceptable = !(RULE_REGISTRY.ruleIsToxic(p.policyRuleId(policyId))) &&
            p.isPolicyAttestor(policyId, attestor);
    }

    /**
     * @notice Packs uint32[12] into uint256 with 20-bit precision.
     * @dev This function will disregard bits greater than 20 bits of magnitude.
     * @param input 20 bit unsigned integers cast as uint32.
     * @return packed Uint256 packed format contained encoding of 12 20-bit uints. 
     */
    function pack12x20(uint32[12] calldata input) public pure override returns (uint256 packed) {
        packed = input.pack();
    }

    /**
     * @notice Unpacks packed elements as 20-bit uint32[12].
     * @param packed Packed format, 12 x 20-bit unsigned integers, tightly packed. 
     * @return unpacked Uint32[12], 20-bit precision.
     */
    function unpack12x20(uint256 packed) public pure override returns (uint32[12] memory unpacked) {
        unpacked = packed.unpack();
    }
}
