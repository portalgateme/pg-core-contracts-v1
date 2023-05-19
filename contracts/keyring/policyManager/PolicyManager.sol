// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.14;

import "../interfaces/IPolicyManager.sol";
import "../interfaces/IKeyringCredentials.sol";
import "../access/KeyringAccessControl.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

/**
 * @notice PolicyManager holds the policies managed by DeFi Protocol Operators and users. 
 When used by a KeyringGuard, policies describe admission policies that will be enforced. 
 When used by a user, policies describe the rules that compliant DeFi Protocol Operators 
 must enforce in order for their contracts to be compatible with the user policy. 
 */

contract PolicyManager is IPolicyManager, KeyringAccessControl, Initializable {
    
    using PolicyStorage for PolicyStorage.App;
    using PolicyStorage for PolicyStorage.Policy;
    using AddressSet for AddressSet.Set;

    uint32 private constant DEFAULT_TTL = 1 days; 
    address private constant NULL_ADDRESS = address(0);
    bytes32 private constant SEED_POLICY_OWNER = keccak256("spo");

    bytes32 public constant override ROLE_POLICY_CREATOR = keccak256("rpc");
    bytes32 public constant override ROLE_GLOBAL_ATTESTOR_ADMIN = keccak256("rgaa");
    bytes32 public constant override ROLE_GLOBAL_WALLETCHECK_ADMIN = keccak256("rgwca");

    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    address public immutable override ruleRegistry;

    PolicyStorage.App policyStorage;

    /**
     * @notice The policy admin role is initially granted during createPolicy.
     * @dev Reverts if the msg signer doesn't have the policy admin role.
     * @param policyId The unique identifier of a Policy.
     */
    modifier onlyPolicyAdmin(uint32 policyId) {
        _checkRole(bytes32(uint256(policyId)), _msgSender(), "pm:opa");
        _;
    }

    /**
     * @notice Only policy creators can create new policies. 
     * @dev Reverts if the user doesn't have the policy creator role.
     */
    modifier onlyPolicyCreator() {
        _checkRole(ROLE_POLICY_CREATOR, _msgSender(), "pm:opc");
        _;
    }

    /**
     * @notice Keyring Governance has exclusive control of the global whitelist of Attestors.
     * @dev Reverts if the user doesn't have the global attestor admin role.
     */
    modifier onlyAttestorAdmin() {
        _checkRole(ROLE_GLOBAL_ATTESTOR_ADMIN, _msgSender(), "pm:oaa");
        _;
    }

    /**
     * @notice Keyring Governance has exclusive access to the global whitelist of Wallet Checks.
     * @dev Reverts if the user doesn't have the global wallet check admin role.
     */
    modifier onlyWalletCheckAdmin() {
        _checkRole(ROLE_GLOBAL_WALLETCHECK_ADMIN, _msgSender(), "pm:owca");
        _;
    }

    /**
     * @param trustedForwarder Contract address that is allowed to relay message signers.
     * @param ruleRegistryAddr The address of the deployed RuleRegistry contract.
     */
    constructor(
        address trustedForwarder, 
        address ruleRegistryAddr)
        KeyringAccessControl(trustedForwarder)
    {
        if (trustedForwarder == NULL_ADDRESS)
            revert Unacceptable({
                reason: "trustedForwarder cannot be empty"
            });
        if (ruleRegistryAddr == NULL_ADDRESS)
            revert Unacceptable({
                reason: "ruleRegistry cannot be empty"
            });
        ruleRegistry = ruleRegistryAddr;
        emit PolicyManagerDeployed(_msgSender(), trustedForwarder, ruleRegistryAddr);
    }

    /**
     * @notice This upgradeable contract must be initialized.
     * @dev Initializer function MUST be called directly after deployment.
     because anyone can call it but overall only once.
     */
    function init() external override initializer {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        address[] memory emptyList;
        (bytes32 universeRule, ) = IRuleRegistry(ruleRegistry).genesis();
        // no one owns the default, permissive user policy, which is always policy 0
        PolicyStorage.PolicyScalar memory policyScalar = PolicyStorage.PolicyScalar({
            ruleId: universeRule,
            descriptionUtf8: "default user policy",
            ttl: DEFAULT_TTL,
            gracePeriod: 0,
            acceptRoots: 0,
            allowUserWhitelists: true,
            locked: true
        });
        policyStorage.newPolicy(
            policyScalar,
            emptyList,
            emptyList,
            ruleRegistry
        );
        emit PolicyManagerInitialized(_msgSender());
    }

    /**
     * @notice A policy creater can create a policy and is granted the admin and user admin roles.
     * @param policyScalar The non-indexed values in a policy configuration as defined in PolicyStorage.
     * @param attestors Acceptable attestors correspond to identity trees that will be used in
     zero-knowledge proofs. Proofs cannot be generated, and therefore credentials cannot be
     generated using roots that do not originate in an identity tree that is not explicitly
     acceptable. 
     * @param walletChecks Trader wallets are optionally checked againt on-chain wallet checks on
     a just-in-time basis. 
     * @return policyId The unique identifier of a new Policy.
     */
    function createPolicy(
        PolicyStorage.PolicyScalar calldata policyScalar,
        address[] calldata attestors,
        address[] calldata walletChecks
    ) 
        external 
        override
        onlyPolicyCreator 
        returns 
    (
        uint32 policyId, 
        bytes32 policyOwnerRoleId, 
        bytes32 policyUserAdminRoleId) 
    {
        policyId = policyStorage.newPolicy(
            policyScalar,
            attestors,
            walletChecks,
            ruleRegistry
        );

        (policyOwnerRoleId, policyUserAdminRoleId) = grantPolicyRoles(policyId);

        emit CreatePolicy(
            _msgSender(), 
            policyId, 
            policyScalar, 
            attestors, 
            walletChecks, 
            policyOwnerRoleId, 
            policyUserAdminRoleId);
    }

    function grantPolicyRoles(uint32 policyId) private returns (
        bytes32 policyOwnerRoleId, 
        bytes32 policyUserAdminRoleId)
    {
        policyOwnerRoleId = policyOwnerRole(policyId);
        policyUserAdminRoleId = keccak256(abi.encodePacked(policyId, SEED_POLICY_OWNER));

        _grantRole(policyOwnerRoleId, _msgSender());
        _grantRole(policyUserAdminRoleId, _msgSender());
        _setRoleAdmin(policyOwnerRoleId, policyUserAdminRoleId);
    }

    /**
     * @notice The Policy admin role can update a policy's scalar values one step.
     * @dev Deadlines must always be >= the active policy grace period. 
     * @param policyId The unique identifier of a Policy.
     * @param policyScalar The non-indexed values in a policy configuration as defined in PolicyStorage.
     * @param deadline The timestamp when the staged changes will take effect. Overrides previous deadline.
     */
    function updatePolicyScalar(
        uint32 policyId,
        PolicyStorage.PolicyScalar calldata policyScalar,
        uint256 deadline
    ) external override onlyPolicyAdmin(policyId) {
        policyStorage.writePolicyScalar(
            policyId,
            policyScalar,
            ruleRegistry,
            deadline
        );
        emit UpdatePolicyScalar(_msgSender(), policyId, policyScalar, deadline);
    }

    /**
     * @notice Policy admins can update policy descriptions.
     * @dev Deadlines must always be >= the active policy grace period. 
     * @param policyId The policy to update.
     * @param descriptionUtf8 The new policy description.
     * @param deadline The timestamp when the staged changes will take effect. Overrides previous deadline.
     */
    function updatePolicyDescription(
        uint32 policyId, 
        string calldata descriptionUtf8, 
        uint256 deadline
    )
        external
        override
        onlyPolicyAdmin(policyId)
    {
        PolicyStorage.Policy storage policyObj = policyStorage.policyRawData(policyId);
        policyStorage.processStaged(policyId);
        policyObj.writeDescription(descriptionUtf8);
        policyStorage.setDeadline(policyId, deadline);
        emit UpdatePolicyDescription(_msgSender(), policyId, descriptionUtf8, deadline);
    }

    /**
     * @notice Policy admins can update policy rules.
     * @dev Deadlines must always be >= the active policy grace period. 
     * @param policyId The policy to update.
     * @param ruleId The new policy rule.
     * @param deadline The timestamp when the staged changes will take effect. Overrides previous deadline.
     */
     function updatePolicyRuleId(uint32 policyId, bytes32 ruleId, uint256 deadline)
        external
        override
        onlyPolicyAdmin(policyId)
    {
        PolicyStorage.Policy storage policyObj = policyStorage.policyRawData(policyId);
        policyStorage.processStaged(policyId);
        policyObj.writeRuleId(ruleId, ruleRegistry);
        policyStorage.setDeadline(policyId, deadline);
        emit UpdatePolicyRuleId(_msgSender(), policyId, ruleId, deadline);
    }

    /**
     * @notice Policy admins can update policy credential expiry times.
     * @dev Deadlines must always be >= the active policy grace period. 
     * @param policyId The policy to update.
     * @param ttl The maximum acceptable credential age in seconds.
     * @param deadline The timestamp when the staged changes will take effect. Overrides previous deadline. 
     */
    function updatePolicyTtl(uint32 policyId, uint32 ttl, uint256 deadline)
        external
        override
        onlyPolicyAdmin(policyId)
    {
        PolicyStorage.Policy storage policyObj = policyStorage.policyRawData(policyId);
        policyStorage.processStaged(policyId);
        policyObj.writeTtl(ttl);
        policyStorage.setDeadline(policyId, deadline);
        emit UpdatePolicyTtl(_msgSender(), policyId, ttl, deadline);
    }

    /**
     * @notice Policy admins can change the gracePeriod with delayed effect.
     * @dev Deadlines must always be >= the active policy grace period. 
     * @param policyId The policy to update.
     * @param gracePeriod The minimum acceptable deadline.
     * @param deadline The timestamp when the staged changes will take effect. Overrides previous deadline.
     */
    function updatePolicyGracePeriod(uint32 policyId, uint32 gracePeriod, uint256 deadline) 
        external
        override
        onlyPolicyAdmin(policyId) 
    {
        PolicyStorage.Policy storage policyObj = policyStorage.policyRawData(policyId);
        policyStorage.processStaged(policyId);
        policyObj.writeGracePeriod(gracePeriod);
        policyStorage.setDeadline(policyId, deadline);
        emit UpdatePolicyGracePeriod(_msgSender(), policyId, gracePeriod, deadline);
    }

    /**
     * @notice Policy admins can force acceptance of the last n identity tree roots. This facility
     provides protection for traders in the event that circumstances prevent the publication of 
     new identity tree roots.
     * @dev Deadlines must always be >= the active policy grace period. 
     * @param policyId The policy to update.
     * @param acceptRoots The depth of most recent roots to always accept.
     * @param deadline The timestamp when the staged changes will take effect. Overrides previous deadline.
     */
    function updatePolicyAcceptRoots(uint32 policyId, uint16 acceptRoots, uint256 deadline) 
        external
        override 
        onlyPolicyAdmin(policyId) 
    {
        PolicyStorage.Policy storage policyObj = policyStorage.policyRawData(policyId);
        policyStorage.processStaged(policyId);
        policyObj.writeAcceptRoots(acceptRoots);
        policyStorage.setDeadline(policyId, deadline);
        emit UpdatePolicyAcceptRoots(_msgSender(), policyId, acceptRoots, deadline);
    }

    /**
     * @notice Policy owners can allow users to set whitelists of counterparties to exempt from
     compliance checks.
     * @param policyId The policy to update.
     * @param allowUserWhitelists True if whitelists are allowed, otherwise false.
     * @param deadline The timestamp when the staged changes will take effect. Overrides previous deadline.
     */
    function updatePolicyAllowUserWhitelists(uint32 policyId, bool allowUserWhitelists,uint256 deadline) 
        external 
        override 
        onlyPolicyAdmin(policyId) 
    {
        PolicyStorage.Policy storage policyObj = policyStorage.policyRawData(policyId);
        policyStorage.processStaged(policyId);
        policyObj.writeAllowUserWhitelists(allowUserWhitelists);
        policyStorage.setDeadline(policyId, deadline);
        emit UpdatePolicyAllowUserWhitelists(_msgSender(), policyId, allowUserWhitelists, deadline);
    }

    /**
     * @notice Schedules policy locking if the policy is not already scheduled to be locked.
     * @dev Deadlines must always be >= the active policy grace period. 
     * @param policyId The policy to lock.
     * @param locked True if the policy is to be locked. False if the scheduled lock is to be cancelled.
     * @param deadline The timestamp when the staged changes will take effect. Overrides previous deadline.
     */
    function updatePolicyLock(uint32 policyId, bool locked, uint256 deadline) 
        external
        override
        onlyPolicyAdmin(policyId)
    {
        PolicyStorage.Policy storage policyObj = policyStorage.policyRawData(policyId);
        policyStorage.processStaged(policyId);
        if(policyObj.scalarPending.locked != locked) {
            policyObj.writePolicyLock(locked);
            policyStorage.setDeadline(policyId, deadline);
            emit UpdatePolicyLock(_msgSender(), policyId, locked, deadline);
        }
    }

    /**
     * @notice Update the deadline for staged policy changes to take effect.
     * @dev Deadlines must always be >= the active policy grace period. 
     * @param policyId The policyId to update.
     * @param deadline Must be >= graceTime seconds past block time or 0 to unschedule staged policy changes.
     */
    function setDeadline(uint32 policyId, uint256 deadline) 
        external 
        override 
        onlyPolicyAdmin(policyId) 
    {
        policyStorage.processStaged(policyId);
        policyStorage.setDeadline(policyId, deadline);
        emit UpdatePolicyDeadline(_msgSender(), policyId, deadline);
    }

    /**
     * @notice The Policy admin selects whitelisted Attestors that are acceptable for their Policy.
     * @dev Deadlines must always be >= the active policy grace period. Attestors must be absent from
     the active attestors set, or present in the staged removals. 
     * @param policyId The policy to update.
     * @param attestors The address of one or more Attestors to add to the Policy.
     * @param deadline The timestamp when the staged changes will take effect. Overrides previous deadline.
     */
    function addPolicyAttestors(uint32 policyId, address[] calldata attestors, uint256 deadline)
        external
        override
        onlyPolicyAdmin(policyId)
    {
        PolicyStorage.Policy storage policyObj = policyStorage.policyRawData(policyId);
        policyStorage.processStaged(policyId);
        policyStorage.writeAttestorAdditions(policyObj, attestors);
        policyStorage.setDeadline(policyId, deadline);
        emit AddPolicyAttestors(_msgSender(), policyId, attestors, deadline);
    }

    /**
     * @notice The Policy admin selects whitelisted Attestors that are acceptable for their Policy.
     * @dev Deadlines must always be >= the active policy grace period. The attestors must be present
     in the active attestor set or staged updates. 
     * @param policyId The policy to update.
     * @param attestors The address of one or more Attestors to remove from the Policy.
     * @param deadline The timestamp when the staged changes will take effect. Overrides previous deadline.
     */
    function removePolicyAttestors(uint32 policyId, address[] calldata attestors, uint256 deadline)
        external
        override
        onlyPolicyAdmin(policyId)
    {
        PolicyStorage.Policy storage policyObj = policyStorage.policyRawData(policyId);
        policyStorage.processStaged(policyId);
        policyObj.writeAttestorRemovals(attestors);
        policyStorage.setDeadline(policyId, deadline);
        emit RemovePolicyAttestors(_msgSender(), policyId, attestors, deadline);
    }

    /**
     * @notice The Policy admin selects whitelisted Attestors that are acceptable for their Policy.
     * @dev Deadlines must always be >= the active policy grace period. The wallet checks must be absent
     from the active wallet check set, or present in the staged removals. 
     * @param policyId The policy to update.
     * @param walletChecks The address of one or more Wallet Checks to add to the Policy.
     * @param deadline The timestamp when the staged changes will take effect. Overrides previous deadline.
     */
    function addPolicyWalletChecks(uint32 policyId, address[] calldata walletChecks, uint256 deadline)
        external
        override
        onlyPolicyAdmin(policyId)
    {
        PolicyStorage.Policy storage policyObj = policyStorage.policyRawData(policyId);
        policyStorage.processStaged(policyId);
        policyStorage.writeWalletCheckAdditions(policyObj, walletChecks);
        policyStorage.setDeadline(policyId, deadline);
        emit AddPolicyWalletChecks(_msgSender(), policyId, walletChecks, deadline);
    }

    /**
     * @notice The Policy admin selects whitelisted Attestors that are acceptable for their Policy.
     * @dev Deadlines must always be >= the active policy grace period. The wallet checks must be present
     in the active wallet checks set or staged additions. 
     * @param policyId The policy to update.
     * @param walletChecks The address of one or more Attestors to remove from the Policy.
     * @param deadline The timestamp when the staged changes will take effect. Overrides previous deadline.
     */
    function removePolicyWalletChecks(uint32 policyId, address[] calldata walletChecks, uint256 deadline)
        external
        override
        onlyPolicyAdmin(policyId)
    {
        PolicyStorage.Policy storage policyObj = policyStorage.policyRawData(policyId);
        policyStorage.processStaged(policyId);
        policyObj.writeWalletCheckRemovals(walletChecks);
        policyStorage.setDeadline(policyId, deadline);
        emit RemovePolicyWalletChecks(_msgSender(), policyId, walletChecks, deadline);
    }

    /***************************************************
     Global Governance
     ***************************************************/

    /**
     * @notice The Global Attestor Admin can admit Attestors to the global whitelist.
     * @param attestor The address of a Attestor to admit into the global whitelist.
     * @param uri The URI refers to detailed information about the attestor.
     */
    function admitAttestor(address attestor, string calldata uri)
        external
        override
        onlyAttestorAdmin
    {
        policyStorage.insertGlobalAttestor(attestor, uri);
        emit AdmitAttestor(_msgSender(), attestor, uri);
    }

    /**
     * @notice The Global Attestor Admin can update the uris for Attestors on the global whitelist.
     * @param attestor The address of a Attestor in the global whitelist.
     * @param uri The new uri for the Attestor.
     */

    function updateAttestorUri(address attestor, string calldata uri)
        external
        override
        onlyAttestorAdmin
    {
        policyStorage.updateGlobalAttestorUri(attestor, uri);
        emit UpdateAttestorUri(_msgSender(), attestor, uri);
    }

    /**
     * @notice The Global Attestor Admin can remove Attestors from the global whitelist.
     * @dev Does not automatically remove Attestors from affected Policies.
     * @param attestor The address of an Attestor on the global whitelist.
     */
    function removeAttestor(address attestor) 
        external 
        override 
        onlyAttestorAdmin 
    {
        policyStorage.removeGlobalAttestor(attestor);
        emit RemoveAttestor(_msgSender(), attestor);
    }

    /**
     * @notice The Global Wallet Check Admin can admit Wallet Checks to the global whitelist.
     * @param walletCheck The address of a Wallet Check to admit into the global whitelist.
     */
    function admitWalletCheck(address walletCheck)
        external
        override
        onlyWalletCheckAdmin
    {
        policyStorage.insertGlobalWalletCheck(walletCheck);
        emit AdmitWalletCheck(_msgSender(), walletCheck);
    }

    /**
     * @notice The Global Wallet Check Admin can remove Wallet Checks from the global whitelist.
     * @dev Does not automatically remove Wallet Checks from affected Policies.
     * @param walletCheck The address of a Wallet Check contract in the global whitelist.
     */
    function removeWalletCheck(address walletCheck) 
        external 
        override 
        onlyWalletCheckAdmin 
    {
        policyStorage.removeGlobalWalletCheck(walletCheck);
        emit RemoveWalletCheck(_msgSender(), walletCheck);
    }

    /**********************************************************
     Inspection
     **********************************************************/

    /**
     * @param policyId The unique identifier of a Policy.
     * @dev Use static calls to inspect current information.
     * @return config The scalar values that form part of the policy definition.
     * @return attestors The authorized attestors for the policy.
     * @return walletChecks The policy trader wallet checks that will be performed on a just-in-time basis.
     * @return deadline The timestamp when staged changes will take effect.
     */
    function policy(uint32 policyId)
        public
        override
        returns (
            PolicyStorage.PolicyScalar memory config,
            address[] memory attestors,
            address[] memory walletChecks,
            uint256 deadline
        )
    {
        PolicyStorage.Policy storage policyObj = policyStorage.policyRawData(policyId);
        policyStorage.processStaged(policyId);
        config = policyObj.scalarActive;
        attestors = policyObj.attestors.activeSet.keyList;
        walletChecks = policyObj.walletChecks.activeSet.keyList;
        deadline = policyObj.deadline;
    }

    /**
     * @notice Reveals the internal state of the policy object without processing staged changes.
     * @dev A non-zero deadline in the past indicates that staged updates are already in effect.
     * @param policyId The policy to inspect.
     * @param deadline Timestamp for staged changes to take effect, or 0 if unscheduled.
     * @param scalarActive The active scalar variables object.
     * @param scalarPending The staged scalar variables object.
     * @param attestorsActive The active policy attestors.
     * @param attestorsPendingAdditions Attestors staged to add to the policy.
     * @param attestorsPendingRemovals Attestors staged to remove from the policy.
     */
    function policyRawData(uint32 policyId)
        external
        view
        override 
        returns(
            uint256 deadline,
            PolicyStorage.PolicyScalar memory scalarActive,
            PolicyStorage.PolicyScalar memory scalarPending,
            address[] memory attestorsActive,
            address[] memory attestorsPendingAdditions,
            address[] memory attestorsPendingRemovals,
            address[] memory walletChecksActive,
            address[] memory walletChecksPendingAdditions,
            address[] memory walletChecksPendingRemovals)
    {
        PolicyStorage.Policy storage p = policyStorage.policyRawData(policyId);
        deadline = p.deadline;
        scalarActive = p.scalarActive;
        scalarPending = p.scalarPending;
        attestorsActive = p.attestors.activeSet.keyList;
        attestorsPendingAdditions = p.attestors.pendingAdditionSet.keyList;
        attestorsPendingRemovals = p.attestors.pendingRemovalSet.keyList;
        walletChecksActive = p.walletChecks.activeSet.keyList;
        walletChecksPendingAdditions = p.walletChecks.pendingAdditionSet.keyList;
        walletChecksPendingRemovals = p.walletChecks.pendingRemovalSet.keyList;
    }

    /**
     * @notice Generate the corresponding admin/owner role for a policyId
     * @param policyId The policyId
     * @return ownerRole The bytes32 owner role that corresponds to the policyId
      */
    function policyOwnerRole(uint32 policyId) public pure override returns (bytes32 ownerRole) {
        ownerRole = bytes32(uint256(uint32(policyId)));
    }

    /**
     * @param policyId The unique identifier of a Policy.
     * @dev Use static calls to inspect current information.
     * @return descriptionUtf8 Not used for any on-chain logic.
     */
    function policyDescription(uint32 policyId)
        external
        override
        returns (string memory descriptionUtf8)
    {
        PolicyStorage.Policy storage policyObj = policyStorage.policyRawData(policyId);
        policyStorage.processStaged(policyId);
        descriptionUtf8 = policyObj.scalarActive.descriptionUtf8;
    }

    /**
     * @param policyId The unique identifier of a Policy.
     * @dev Use static calls to inspect current information.
     * @return ruleId Rule to enforce, defined in the RuleRegistry.
     */
    function policyRuleId(uint32 policyId) external override returns (bytes32 ruleId) {
        PolicyStorage.Policy storage policyObj = policyStorage.policyRawData(policyId);
        policyStorage.processStaged(policyId);
        ruleId = policyObj.scalarActive.ruleId;
    }

    /**
     * @param policyId The unique identifier of a Policy.
     * @dev Use static calls to inspect current information.
     * @return ttl The maximum age of acceptable credentials.
     */
    function policyTtl(uint32 policyId) external override returns (uint128 ttl) {
        PolicyStorage.Policy storage policyObj = policyStorage.policyRawData(policyId);
        policyStorage.processStaged(policyId);
        ttl = policyObj.scalarActive.ttl;
    }

    /**
     * @notice Inspect a policy grace period.
     * @dev Use static calls to inspect current information.
     * @return gracePeriod Seconds until policy changes take effect.
     */
    function policyGracePeriod(uint32 policyId) external override returns(uint128 gracePeriod) {
        PolicyStorage.Policy storage policyObj = policyStorage.policyRawData(policyId);
        policyStorage.processStaged(policyId);
        gracePeriod = policyObj.scalarActive.gracePeriod;
    }

    /**
     * @notice Check the number of latest identity roots to accept, regardless of age.
     * @param policyId The policy to inspect.
     * @return acceptRoots The number of latest identity roots to accept unconditionally for the construction
     of zero-knowledge proofs.
     */
    function policyAcceptRoots(uint32 policyId)
        external
        override
        returns (uint16 acceptRoots)
    {
        PolicyStorage.Policy storage policyObj = policyStorage.policyRawData(policyId);
        policyStorage.processStaged(policyId);
        acceptRoots = policyObj.scalarActive.acceptRoots;
    }

    /**
     * @notice Check if the policy allows user whitelisting.
     * @param policyId The policy to inspect. 
     * @return isAllowed True if whitelists can be used to override compliance checks. 
     */
    function policyAllowUserWhitelists(uint32 policyId) external returns (bool isAllowed){
        PolicyStorage.Policy storage policyObj = policyStorage.policyRawData(policyId);
        policyStorage.processStaged(policyId);
        isAllowed = policyObj.scalarActive.allowUserWhitelists;
    }

    /**
     * @notice Check if the policy is locked.
     * @dev Use static calls to inspect current information.
     * @return isLocked True if the policy cannot be changed
     */
    function policyLocked(uint32 policyId) external override returns (bool isLocked) {
        PolicyStorage.Policy storage policyObj = policyStorage.policyRawData(policyId);
        policyStorage.processStaged(policyId);
        isLocked = policyObj.scalarActive.locked;
    }

    /**
     * @notice Inspect the schedule to implementing staged policy updates. 
     * @dev Use static calls to inspect current information.
     * @param policyId The policy to inspect.
     * @return deadline The scheduled time to active the pending policy update. 
     */
    function policyDeadline(uint32 policyId) external override returns (uint256 deadline) {
        PolicyStorage.Policy storage policyObj = policyStorage.policyRawData(policyId);
        policyStorage.processStaged(policyId);
        deadline = policyObj.deadline;
    }

    /**
     * @param policyId The policy to inspect.
     * @dev Use static calls to inspect current information.
     * @return count The count of acceptable Attestors for the Policy.
     */
    function policyAttestorCount(uint32 policyId) public override returns (uint256 count) {
        PolicyStorage.Policy storage policyObj = policyStorage.policyRawData(policyId);
        policyStorage.processStaged(policyId);
        count = policyObj.attestors.activeSet.count();
    }

    /**
     * @param policyId The Policy to inspect.
     * @dev Use static calls to inspect current information.
     * @param index The list index to inspect.
     * @return attestor The address of a Attestor that is acceptable for the Policy.
     */
    function policyAttestorAtIndex(uint32 policyId, uint256 index)
        external
        override
        returns (address attestor)
    {
        PolicyStorage.Policy storage policyObj = policyStorage.policyRawData(policyId);
        policyStorage.processStaged(policyId);
        if (index >= policyObj.attestors.activeSet.count())
            revert Unacceptable({
                reason: "index"
            });
        attestor = policyObj.attestors.activeSet.keyAtIndex(index);
    }

    /**
     * @param policyId The policy to inspect.
     * @dev Use static calls to inspect current information.
     * @return attestors The list of attestors that are authoritative for the policy.
     */
    function policyAttestors(uint32 policyId) external override returns (address[] memory attestors) {
        PolicyStorage.Policy storage policyObj = policyStorage.policyRawData(policyId);
        policyStorage.processStaged(policyId);
        attestors = policyObj.attestors.activeSet.keyList;
    }

    /**
     * @param policyId The Policy to inspect.
     * @param attestor The address to inspect.
     * @dev Use static calls to inspect current information.
     * @return isIndeed True if attestor is acceptable for the Policy, otherwise false.
     */
    function isPolicyAttestor(uint32 policyId, address attestor)
        external
        override
        returns (bool isIndeed)
    {
        PolicyStorage.Policy storage policyObj = policyStorage.policyRawData(policyId);
        policyStorage.processStaged(policyId);
        isIndeed = policyObj.attestors.activeSet.exists(attestor);
    }    

    /**
     * @param policyId The policy to inspect.
     * @dev Use static calls to inspect current information.
     * @return count The count of wallet checks for the Policy.
     */
    function policyWalletCheckCount(uint32 policyId) public override returns (uint256 count) {
        PolicyStorage.Policy storage policyObj = policyStorage.policyRawData(policyId);
        policyStorage.processStaged(policyId);
        count = policyObj.walletChecks.activeSet.count();
    }

    /**
     * @param policyId The Policy to inspect.
     * @dev Use static calls to inspect current information.
     * @param index The list index to inspect.
     * @return walletCheck The address of a wallet check for the policy.
     */
    function policyWalletCheckAtIndex(uint32 policyId, uint256 index)
        external
        override
        returns (address walletCheck)
    {
        PolicyStorage.Policy storage policyObj = policyStorage.policyRawData(policyId);
        policyStorage.processStaged(policyId);
        if (index >= policyObj.walletChecks.activeSet.count())
            revert Unacceptable({
                reason: "index"
            });
        walletCheck = policyObj.walletChecks.activeSet.keyAtIndex(index);
    }

    /**
     * @param policyId The policy to inspect.
     * @dev Use static calls to inspect current information.
     * @return walletChecks The list of walletCheck contracts that apply to the policy.
     */
    function policyWalletChecks(uint32 policyId) external override returns (address[] memory walletChecks) {
        PolicyStorage.Policy storage policyObj = policyStorage.policyRawData(policyId);
        policyStorage.processStaged(policyId);
        walletChecks = policyObj.walletChecks.activeSet.keyList;
    }

    /**
     * @dev Use static calls to inspect current information.
     * @param policyId The Policy to inspect.
     * @param walletCheck The address to inspect.
     * @return isIndeed True if wallet check applies to the Policy, otherwise false.
     */
    function isPolicyWalletCheck(uint32 policyId, address walletCheck)
        external
        override
        returns (bool isIndeed)
    {
        PolicyStorage.Policy storage policyObj = policyStorage.policyRawData(policyId);
        policyStorage.processStaged(policyId);
        isIndeed = policyObj.walletChecks.activeSet.exists(walletCheck);
    }    

    /**
     * @dev Does not check existance.
     * @return count Existing policies in PolicyManager.
     */
    function policyCount() public view override returns (uint256 count) {
        count = policyStorage.policies.length;
    }

    /**
     * @param policyId The unique identifier of a Policy.
     * @return isIndeed True if a Policy with policyId exists, otherwise false.
     */
    function isPolicy(uint32 policyId) public view override returns (bool isIndeed) {
        isIndeed = policyId < policyCount();
    }

    /**
     * @return count Total count of Attestors admitted to the global whitelist.
     */
    function globalAttestorCount() external view override returns (uint256 count) {
        count = policyStorage.globalAttestorSet.count();
    }

    /**
     * @param index The list index to inspect.
     * @return attestor An Attestor address from the global whitelist.
     */
    function globalAttestorAtIndex(uint256 index) external view override returns (address attestor) {
        if (index >= policyStorage.globalAttestorSet.count())
            revert Unacceptable({
                reason: "index"
            });
        attestor = policyStorage.globalAttestorSet.keyAtIndex(index);
    }

    /**
     * @param attestor An address.
     * @return isIndeed True if the attestor is admitted to the global whitelist.
     */
    function isGlobalAttestor(address attestor) public view override returns (bool isIndeed) {
        isIndeed = policyStorage.globalAttestorSet.exists(attestor);
    }

    /**
     * @return count Total count of wallet checks admitted to the global whitelist.
     */
    function globalWalletCheckCount() external view override returns (uint256 count) {
        count = policyStorage.globalWalletCheckSet.count();
    }

    /**
     * @param index The list index to inspect.
     * @return walletCheck A wallet check contract address from the global whitelist. 
     */
    function globalWalletCheckAtIndex(uint256 index) external view override returns (address walletCheck) {
        if (index >= policyStorage.globalWalletCheckSet.count())
            revert Unacceptable({
                reason: "index"
            });
        walletCheck = policyStorage.globalWalletCheckSet.keyAtIndex(index);
    }

    /**
     * @param walletCheck A wallet check contract address to search for.
     * @return isIndeed True if the wallet check exists in the global whitelist, otherwise false.
     */
    function isGlobalWalletCheck(address walletCheck) external view override returns (bool isIndeed) {
        isIndeed = policyStorage.globalWalletCheckSet.exists(walletCheck);
    }

    /**
     * @param attestor An address.
     * @return uri The attestor uri if the address is an attestor.
     */

    function attestorUri(address attestor) external view override returns(string memory uri) {
        uri = policyStorage.attestorUris[attestor];
    }

    /**
     * @notice Inspect user roles.
     * @param role Access control role to check.
     * @param user User address to check.
     * @return doesIndeed True if the user has the role.
     */
    function hasRole(
        bytes32 role, 
        address user
    ) 
        public 
        view 
        override(AccessControl, IPolicyManager) 
        returns (bool doesIndeed)
    {
        doesIndeed = AccessControl.hasRole(role, user);
    }
}
