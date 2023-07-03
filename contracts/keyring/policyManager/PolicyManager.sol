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
    using Bytes32Set for Bytes32Set.Set;

    uint32 private constant DEFAULT_TTL = 1 days; 
    address private constant NULL_ADDRESS = address(0);
    bytes32 private constant SEED_POLICY_OWNER = keccak256("spo");

    bytes32 public constant override ROLE_POLICY_CREATOR = keccak256("c");
    bytes32 public constant override ROLE_GLOBAL_ATTESTOR_ADMIN = keccak256("a");
    bytes32 public constant override ROLE_GLOBAL_WALLETCHECK_ADMIN = keccak256("w");
    bytes32 public constant override ROLE_GLOBAL_BACKDOOR_ADMIN = keccak256("b");
    bytes32 public constant override ROLE_GLOBAL_VALIDATION_ADMIN = keccak256("v");

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
     * @notice Keyring governance has exclusive access to the global whitelist of backdoor.
     * @dev Reverts if the user doesn't have the global backdoor admin role. 
     */
    modifier onlyBackdoorAdmin() {
        _checkRole(ROLE_GLOBAL_BACKDOOR_ADMIN, _msgSender(), "pm:oba");
        _;
    }

    /**
     * @notice Keyring Governance has exclusive access to input validation parameters.
     * @dev Reverts if the user doesn't have the global validation admin role.
     */
    modifier onlyValidationAdmin() {
        _checkRole(ROLE_GLOBAL_VALIDATION_ADMIN, _msgSender(), "pm:va");
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
            allowApprovedCounterparties: true,
            disablementPeriod: policyStorage.minimumPolicyDisablementPeriod,
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
     * @notice Any user can disable a policy if the policy is deemed failed. 
     * @param policyId The policy to disable.
     */
    function disablePolicy(uint32 policyId) external {
        if(policyId == 0) revert Unacceptable({ reason: "cannot disable the default policy" });
        policyStorage.policy(policyId).disablePolicy();
        emit DisablePolicy(_msgSender(), policyId);
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
        policyObj.processStaged();
        policyObj.writeDescription(descriptionUtf8);
        policyObj.setDeadline(deadline);
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
        policyObj.processStaged();
        policyObj.writeRuleId(ruleId, ruleRegistry);
        policyObj.setDeadline(deadline);
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
        PolicyStorage.Policy storage policyObj = policyStorage.policy(policyId);
        policyObj.writeTtl(ttl);
        policyObj.setDeadline(deadline);
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
        PolicyStorage.Policy storage policyObj = policyStorage.policy(policyId);
        policyObj.writeGracePeriod(gracePeriod);
        policyObj.setDeadline(deadline);
        emit UpdatePolicyGracePeriod(_msgSender(), policyId, gracePeriod, deadline);
    }

    /**
     * @notice Policy owners can allow users to set whitelists of counterparties to exempt from
     compliance checks.
     * @param policyId The policy to update.
     * @param allowApprovedCounterparties True if whitelists are allowed, otherwise false.
     * @param deadline The timestamp when the staged changes will take effect. Overrides previous deadline.
     */
    function updatePolicyAllowApprovedCounterparties(
        uint32 policyId, 
        bool allowApprovedCounterparties, 
        uint256 deadline
        ) 
        external 
        override 
        onlyPolicyAdmin(policyId) 
    {
        PolicyStorage.Policy storage policyObj = policyStorage.policy(policyId);
        policyObj.writeAllowApprovedCounterparties(allowApprovedCounterparties);
        policyObj.setDeadline(deadline);
        emit UpdatePolicyAllowApprovedCounterparties(_msgSender(), policyId, allowApprovedCounterparties, deadline);
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
        PolicyStorage.Policy storage policyObj = policyStorage.policy(policyId);
        if(policyObj.scalarPending.locked != locked) {
            policyObj.writePolicyLock(locked);
            policyObj.setDeadline(deadline);
            emit UpdatePolicyLock(_msgSender(), policyId, locked, deadline);
        }
    }

    /**
     * @notice Update the disablement period of a policy. See disable Policy.
     * @dev This function updates the disablement period of the policy specified by `policyId` to `disablementPeriod`.
     * Only the policy admin can call this function.
     * @param policyId The ID of the policy to update.
     * @param disablementPeriod The new disablement period for the policy.
     */
    function updatePolicyDisablementPeriod(uint32 policyId, uint256 disablementPeriod, uint256 deadline) 
        external
        override
        onlyPolicyAdmin(policyId) 
    {
        PolicyStorage.Policy storage policyObj = policyStorage.policy(policyId);
        policyStorage.writeDisablementPeriod(policyId, disablementPeriod);
        policyObj.setDeadline(deadline);
        emit UpdatePolicyDisablementPeriod(_msgSender(), policyId, disablementPeriod, deadline);
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
        policyStorage.policy(policyId).setDeadline(deadline);
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
        PolicyStorage.Policy storage policyObj = policyStorage.policy(policyId);
        policyStorage.writeAttestorAdditions(policyObj, attestors);
        policyObj.setDeadline(deadline);
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
        PolicyStorage.Policy storage policyObj = policyStorage.policy(policyId);
        policyObj.writeAttestorRemovals(attestors);
        policyObj.setDeadline(deadline);
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
        PolicyStorage.Policy storage policyObj = policyStorage.policy(policyId);
        policyStorage.writeWalletCheckAdditions(policyObj, walletChecks);
        policyObj.setDeadline(deadline);
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
        PolicyStorage.Policy storage policyObj = policyStorage.policy(policyId);
        policyObj.writeWalletCheckRemovals(walletChecks);
        policyObj.setDeadline(deadline);
        emit RemovePolicyWalletChecks(_msgSender(), policyId, walletChecks, deadline);
    }

    /**
     * @notice The policy admin can add a backdoor.
     * @param policyId The policy to update.
     * @param backdoorId The UID of the backdoor to add. 
     */
    function addPolicyBackdoor(uint32 policyId, bytes32 backdoorId, uint256 deadline)
        external
        override
        onlyPolicyAdmin(policyId)
    {
        PolicyStorage.Policy storage policyObj = policyStorage.policy(policyId);
        policyStorage.writeBackdoorAddition(policyObj, backdoorId);
        policyObj.setDeadline(deadline);
        emit AddPolicyBackdoor(_msgSender(), policyId, backdoorId, deadline);   
    }

    /**
     * @notice The policy admin can remove a backdoor.
     * @param policyId The policy to update.
     * @param backdoorId The UID of the backdoor to remove. 
     */
    function removePolicyBackdoor(uint32 policyId, bytes32 backdoorId, uint256 deadline) 
        external
        override
        onlyPolicyAdmin(policyId)
    {
        PolicyStorage.Policy storage policyObj = policyStorage.policy(policyId);
        policyStorage.policy(policyId).writeBackdoorRemoval(backdoorId);
        policyObj.setDeadline(deadline);
        emit RemovePolicyBackdoor(_msgSender(), policyId, backdoorId, deadline);
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

    /**
     * @notice The backdoor admin can admit a backdoor. 
     * @param pubKey The public key to admit. 
     * @dev Key must be unique. Removing these keys is unsupported. 
     */
    function admitBackdoor(uint256[2] memory pubKey)
        external
        override
        onlyBackdoorAdmin
    {
        bytes32 id = policyStorage.insertGlobalBackdoor(pubKey);
        emit AdmitBackdoor(_msgSender(), id, pubKey);
    }

    /**
     * @dev Updates the minimumPolicyDisablementPeriod
     * @param minimumDisablementPeriod The new value for the minimumPolicyDisablementPeriod property.
     */
    function updateMinimumPolicyDisablementPeriod(uint256 minimumDisablementPeriod) 
        external
        override
        onlyValidationAdmin {
        policyStorage.updateMinimumPolicyDisablementPeriod(minimumDisablementPeriod);
        emit MinimumPolicyDisablementPeriodUpdated(minimumDisablementPeriod);
    }

    /**********************************************************
     Inspection
     **********************************************************/

    /**
     * @notice Generate the corresponding admin/owner role for a policyId.
     * @dev Use static calls to inspect current information.
     * @param policyId The policyId
     * @return ownerRole The bytes32 owner role that corresponds to the policyId
      */
    function policyOwnerRole(uint32 policyId) public pure override returns (bytes32 ownerRole) {
        ownerRole = bytes32(uint256(uint32(policyId)));
    }

    /**
     * @param policyId The unique identifier of a Policy.
     * @dev Use static calls to inspect current information.
     * @return config The scalar values that form part of the policy definition.
     * @return attestors The authorized attestors for the policy.
     * @return walletChecks The policy trader wallet checks that will be performed on a just-in-time basis.
     * @return backdoors The backdoor regimes applicable to the policy.
     * @return deadline The timestamp when staged changes will take effect.
     */
    function policy(uint32 policyId)
        public
        override
        returns (
            PolicyStorage.PolicyScalar memory config,
            address[] memory attestors,
            address[] memory walletChecks,
            bytes32[] memory backdoors,
            uint256 deadline
        )
    {
        PolicyStorage.Policy storage policyObj = policyStorage.policy(policyId);
        config = policyObj.scalarActive;
        attestors = policyObj.attestors.activeSet.keyList;
        walletChecks = policyObj.walletChecks.activeSet.keyList;
        backdoors = policyObj.backdoors.activeSet.keyList;
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
            address[] memory walletChecksPendingRemovals,
            bytes32[] memory backdoorsActive,
            bytes32[] memory backdoorsPendingAdditions,
            bytes32[] memory backdoorsPendingRemovals)
    {
        PolicyStorage.Policy storage p = policyStorage.policies[policyId];
        deadline = p.deadline;
        scalarActive = p.scalarActive;
        scalarPending = p.scalarPending;
        attestorsActive = p.attestors.activeSet.keyList;
        attestorsPendingAdditions = p.attestors.pendingAdditionSet.keyList;
        attestorsPendingRemovals = p.attestors.pendingRemovalSet.keyList;
        walletChecksActive = p.walletChecks.activeSet.keyList;
        walletChecksPendingAdditions = p.walletChecks.pendingAdditionSet.keyList;
        walletChecksPendingRemovals = p.walletChecks.pendingRemovalSet.keyList;
        backdoorsActive = p.backdoors.activeSet.keyList;
        backdoorsPendingAdditions = p.backdoors.pendingAdditionSet.keyList;
        backdoorsPendingRemovals = p.backdoors.pendingRemovalSet.keyList;
    }

    /**
     * @notice Inspect the active policy scalar values. 
     * @dev Use static call to inspect current values.
     * @param policyId The unique identifier of the policy.
     * @return scalarActive The active scalar values for the policy. 
     */
    function policyScalarActive(uint32 policyId) 
        external 
        override 
        returns (PolicyStorage.PolicyScalar memory scalarActive)
    {
        PolicyStorage.Policy storage p = policyStorage.policy(policyId);
        scalarActive = p.scalarActive;
    }

    /**
     * @notice Inspect the policy ruleId.
     * @dev Use static call to inspect current values.
     * @param policyId The unique identifier of the policy.
     * @return ruleId The active scalar values of the policy.
     */
    function policyRuleId(uint32 policyId)
        external
        override
        returns (bytes32 ruleId) 
    {
        PolicyStorage.Policy storage p = policyStorage.policy(policyId);
        ruleId = p.scalarActive.ruleId;
    }

    /**
     * @notice Inspect the policy ttl.
     * @dev Use static call to inspect current values.
     * @param policyId The unique identifier of the policy.
     * @return ttl The active ttl of the policy.
     */
    function policyTtl(uint32 policyId) 
        external
        override
        returns (uint32 ttl)
    {
        PolicyStorage.Policy storage p = policyStorage.policy(policyId);
        ttl = p.scalarActive.ttl;
    }

    /**
     * @notice Check if the policy allows counterparty approvals. 
     * @dev Use static call to inspect current values.
     * @param policyId The unique identifier of the policy.
     * @return isAllowed True if the active policy configuration allows counterparty approvals. 
     */
    function policyAllowApprovedCounterparties(uint32 policyId) 
        external
        override
        returns (bool isAllowed) 
    {
        isAllowed = policyStorage.policy(policyId).scalarActive.allowApprovedCounterparties;
    }

    /**
     * @notice Inspect the policy disablement flag.
     * @dev Use static calls to inspect current information.
     * @param policyId The policyId.
     * @return isDisabled True if the policy is disabled.
      */
    function policyDisabled(uint32 policyId) 
        external 
        view 
        override
        returns (bool isDisabled) 
    {
        isDisabled = policyStorage.policies[policyId].disabled;
    }

    /**
     * @notice A policy is deemed failed if all attestors or any wallet check has been
     degraded for a period exceeding the policyDisablementPeriod.
     * @dev Use static calls to inspect.
     * @param policyId The policy to inspect. 
     * @return canIndeed True if the policy can be disabled.
     */
    function policyCanBeDisabled(uint32 policyId) 
        external
        override 
        returns (bool canIndeed) 
    {
        canIndeed = policyStorage.policy(policyId).policyHasFailed() &&
            policyId != 0;
    }

    /**
     * @notice Count the active policy attestors.
     * @dev Use static calls to inspect current information.
     * @param policyId The policy to inspect.
     * @return count The count of acceptable Attestors for the Policy.
     */
    function policyAttestorCount(uint32 policyId) public override returns (uint256 count) {
        count = policyStorage.policy(policyId).attestors.activeSet.count();
    }

    /**
     * @notice Inspect the active policy attestor at the index. 
     * @dev Use static calls to inspect current information.
     * @param policyId The Policy to inspect.
     * @param index The list index to inspect.
     * @return attestor The address of a Attestor that is acceptable for the Policy.
     */
    function policyAttestorAtIndex(uint32 policyId, uint256 index)
        external
        override
        returns (address attestor)
    {
       PolicyStorage.Policy storage policyObj = policyStorage.policy(policyId);
        if (index >= policyObj.attestors.activeSet.count())
            revert Unacceptable({
                reason: "index"
            });
        attestor = policyObj.attestors.activeSet.keyAtIndex(index);
    }

    /**
     * @notice Inspect the full list of active policy attestors. 
     * @dev Use static calls to inspect current information.
     * @param policyId The policy to inspect.
     * @return attestors The list of attestors that are authoritative for the policy.
     */
    function policyAttestors(uint32 policyId) external override returns (address[] memory attestors) {
        attestors = policyStorage.policy(policyId).attestors.activeSet.keyList;
    }

    /**
     * @notice Check if an attestor is active for the policy. 
     * @dev Use static calls to inspect current information.
     * @param policyId The Policy to inspect.
     * @param attestor The address to inspect.
     * @return isIndeed True if attestor is acceptable for the Policy, otherwise false.
     */
    function isPolicyAttestor(uint32 policyId, address attestor)
        external
        override
        returns (bool isIndeed)
    {
        isIndeed = policyStorage.policy(policyId).attestors.activeSet.exists(attestor);
    }    

    /**
     * @notice Count the active wallet checks for the policy. 
     * @dev Use static calls to inspect current information.
     * @param policyId The policy to inspect.
     * @return count The count of active wallet checks for the Policy.
     */
    function policyWalletCheckCount(uint32 policyId) public override returns (uint256 count) {
        count = policyStorage.policy(policyId).walletChecks.activeSet.count();
    }

    /**
     * @notice Inspect the active wallet check at the index. 
     * @dev Use static calls to inspect current information.
     * @param policyId The Policy to inspect.
     * @param index The list index to inspect.
     * @return walletCheck The address of a wallet check for the policy.
     */
    function policyWalletCheckAtIndex(uint32 policyId, uint256 index)
        external
        override
        returns (address walletCheck)
    {
        PolicyStorage.Policy storage policyObj = policyStorage.policy(policyId);
        if (index >= policyObj.walletChecks.activeSet.count())
            revert Unacceptable({
                reason: "index"
            });
        walletCheck = policyObj.walletChecks.activeSet.keyAtIndex(index);
    }

    /**
     * @notice Inspect the full list of active wallet checks for the policy. 
     * @dev Use static calls to inspect current information.
     * @param policyId The policy to inspect.
     * @return walletChecks The list of walletCheck contracts that apply to the policy.
     */
    function policyWalletChecks(uint32 policyId) external override returns (address[] memory walletChecks) {
        walletChecks = policyStorage.policy(policyId).walletChecks.activeSet.keyList;
    }

    /**
     * @notice Check if a wallet check is active for the policy. 
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
        isIndeed = policyStorage.policy(policyId).walletChecks.activeSet.exists(walletCheck);
    }

    /**
     * @notice Count backdoors in a policy
     * @dev Use static calls to inspect current information.
     * @param policyId The policy to inspect. 
     * @return count The count of backdoors in the policy.
     */
    function policyBackdoorCount(uint32 policyId) external override returns (uint256 count) {
        count = policyStorage.policy(policyId).backdoors.activeSet.count();
    }

    /**
     * @notice Iterate the backdoors in a policy.
     * @dev Use static calls to inspect current information.
     * @param policyId The policy to inspect. 
     * @param index The index to inspect. 
     * @return backdoorId The backdoor id at the index in the policy. 
     */
    function policyBackdoorAtIndex(uint32 policyId, uint256 index) external override returns (bytes32 backdoorId) {
        backdoorId = policyStorage.policy(policyId).backdoors.activeSet.keyAtIndex(index);
    }

    /**
     * @notice Inspect the full list of backdoors in a policy. 
     * @dev Use static calls to inspect current information.
     * @param policyId The policy to inspect. 
     * @return backdoors The full list of backdoors in effect for the policy. 
     */
    function policyBackdoors(uint32 policyId) external override returns (bytes32[] memory backdoors) {
        backdoors = policyStorage.policy(policyId).backdoors.activeSet.keyList;
    }

    /**
     * @notice Check if a backdoor is in a policy. 
     * @dev Use static calls to inspect current information.
     * @param policyId The policy to inspect. 
     * @param backdoorId The backdoor id to check for. 
     * @return isIndeed True if the backdoor id is present in the policy. 
     */
    function isPolicyBackdoor(uint32 policyId, bytes32 backdoorId) external override returns (bool isIndeed) {
        isIndeed = policyStorage.policy(policyId).backdoors.activeSet.exists(backdoorId);
    }

    /**
     * @notice Count the policies in the system. 
     * @return count Existing policies in PolicyManager.
     */
    function policyCount() public view override returns (uint256 count) {
        count = policyStorage.policies.length;
    }

    /**
     * @notice Check if a policyId exists in the system. 
     * @param policyId The unique identifier of a Policy.
     * @return isIndeed True if a Policy with policyId exists, otherwise false.
     */
    function isPolicy(uint32 policyId) public view override returns (bool isIndeed) {
        isIndeed = policyId < policyCount();
    }

    /**
     * @notice Count the global attestors admitted into the system. 
     * @return count Total count of Attestors admitted to the global whitelist.
     */
    function globalAttestorCount() external view override returns (uint256 count) {
        count = policyStorage.globalAttestorSet.count();
    }

    /**
     * @notice Inspect the global attestor at the index. 
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
     * @notice Check if an address is admitted to the global attestors list. 
     * @param attestor An address.
     * @return isIndeed True if the attestor is admitted to the global whitelist.
     */
    function isGlobalAttestor(address attestor) public view override returns (bool isIndeed) {
        isIndeed = policyStorage.globalAttestorSet.exists(attestor);
    }

    /**
     * @notice Count wallet checks admitted to the global list. 
     * @return count Total count of wallet checks admitted to the global whitelist.
     */
    function globalWalletCheckCount() external view override returns (uint256 count) {
        count = policyStorage.globalWalletCheckSet.count();
    }

    /**
     * @notice Inspect the global wallet check at the index. 
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
     * @notice Check if an address is admitted to the global wallet check list. 
     * @param walletCheck A wallet check contract address to search for.
     * @return isIndeed True if the wallet check exists in the global whitelist, otherwise false.
     */
    function isGlobalWalletCheck(address walletCheck) external view override returns (bool isIndeed) {
        isIndeed = policyStorage.globalWalletCheckSet.exists(walletCheck);
    }

    /**
     * @notice Count backdoors that have been admitted into the system. 
     * @return count The number of backdoors in the system.
     */
    function globalBackdoorCount() external view override returns (uint256 count) {
        count = policyStorage.backdoorSet.count();
    }

    /**
     * @notice Iterate global backdoors.
     * @param index The global backdoor index to inspect. 
     * @return backdoorId The backdoorId at the index in the list of admitted backdoors. 
     */
    function globalBackdoorAtIndex(uint256 index) external view override returns (bytes32 backdoorId) {
        backdoorId = policyStorage.backdoorSet.keyAtIndex(index);
    }

    /**
     * @notice Check if a backdoorId exists in the global list of admitted backdoors. 
     * @param backdoorId The backdoorId to check. 
     * @return isIndeed True if the backdoorId exists in the list of globally admitted backdoors. 
     */
    function isGlobalBackdoor(bytes32 backdoorId) external view override returns (bool isIndeed) {
        isIndeed = policyStorage.backdoorSet.exists(backdoorId);
    }

    /**
     * @notice Inspect backdoorPubKey associated with the backdoorId.
     * @param backdoorId The backdoorId to inspect. 
     * @return pubKey The backdoor public key. 
     */
    function backdoorPubKey(bytes32 backdoorId) external view override returns (uint256[2] memory pubKey) {
        pubKey = policyStorage.backdoorPubKey[backdoorId];
    }

    /**
     * @notice Inspect the Uri for an attestor on the global attestor list. 
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

    /**
     * @notice Inspect the minimum policy disablement period.
     * @return period The minimum policy disablement period.
     * @dev The minimum policy disablement period is the minimum time that must pass before a policy can be disabled.
     */
    function minimumPolicyDisablementPeriod() external view override returns (uint256 period) {
        period = policyStorage.minimumPolicyDisablementPeriod;
    }
}
