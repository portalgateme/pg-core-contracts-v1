// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.14;

import "../interfaces/IKeyringGuard.sol";
import "../interfaces/IRuleRegistry.sol";
import "../interfaces/IPolicyManager.sol";
import "../interfaces/IUserPolicies.sol";
import "../interfaces/IWalletCheck.sol";
import "../interfaces/IKeyringCredentials.sol";
import "../access/KeyringAccessControl.sol";

/**
 * @notice KeyringGuard implementation that uses immutable configuration parameters and presents 
 a simplified modifier for use in derived contracts.
 */

abstract contract KeyringGuard is IKeyringGuard, KeyringAccessControl {

    using AddressSet for AddressSet.Set;
    
    uint8 private constant VERSION = 1;
    bytes32 private constant NULL_BYTES32 = bytes32(0);
    address internal constant NULL_ADDRESS = address(0);

    bytes32 public constant ROLE_GLOBAL_WHITELIST_ADMIN = keccak256("whitelist admin");
    address public immutable keyringCredentials;
    address public immutable policyManager;
    address public immutable userPolicies;
    uint32 public immutable admissionPolicyId;
    bytes32 public immutable universeRule;
    bytes32 public immutable emptyRule;

    AddressSet.Set globalWhitelistSet;

    modifier onlyPolicyAdmin {
        bytes32 role = bytes32(uint256(uint32(admissionPolicyId)));
        if (!IPolicyManager(policyManager).hasRole(role, _msgSender()))
            revert Unauthorized({
                sender: _msgSender(),
                module: "KeyringAccessControl",
                method: "_checkRole",
                role: role,
                reason: "sender does not have the required role",
                context: "KeyringGuard:onlyPolicyAdmin"
            });
        _;
    }

     /**
     @param trustedForwarder Contract address that is allowed to relay message signers.
     @param keyringCredentials_ The KeyringCredentials contract to rely on.
     @param policyManager_ The address of the deployed PolicyManager to rely on.
     @param userPolicies_ The address of the deployed UserPolicies contract to rely on. 
     @param admissionPolicyId_ The unique identifier of a Policy against which user accounts will be compared.
     */
    constructor(
        address trustedForwarder,
        address keyringCredentials_,
        address policyManager_,
        address userPolicies_,
        uint32 admissionPolicyId_
    ) 
        KeyringAccessControl(trustedForwarder)
    {
        if (keyringCredentials_ == NULL_ADDRESS)
            revert Unacceptable({
                reason: "credentials cannot be empty"
            });
        if (policyManager_ == NULL_ADDRESS)
            revert Unacceptable({
                reason: "policyManager cannot be empty"
            });
        if(userPolicies_ == NULL_ADDRESS)
            revert Unacceptable({
                reason: "userPolicies cannot be empty"
            });
        if (!IPolicyManager(policyManager_).isPolicy(admissionPolicyId_))
            revert Unacceptable({
                reason: "admissionPolicyId not found"
            });
        keyringCredentials = keyringCredentials_;
        policyManager = policyManager_;
        userPolicies = userPolicies_;
        admissionPolicyId = admissionPolicyId_;
        (universeRule, emptyRule) = IRuleRegistry(IPolicyManager(policyManager_).ruleRegistry()).genesis();
        if (universeRule == NULL_BYTES32)
            revert Unacceptable({
                reason: "the universe rule is not defined in the PolicyManager's RuleRegistry"
            });
        if (emptyRule == NULL_BYTES32)
            revert Unacceptable({
                reason: "the empty rule is not defined in the PolicyManager's RuleRegistry"
            });
        emit KeyringGuardConfigured(
            keyringCredentials_,
            policyManager_,
            userPolicies_,
            admissionPolicyId_,
            universeRule,
            emptyRule
        );
    }

    /**
     * @notice Policy admins can maintain a global list of whitelisted addresses, usually contracts.
     * @param subject The address to whitelist or delist.
     */
    function whitelistAddress(address subject) external onlyPolicyAdmin {
        if (globalWhitelistSet.exists(subject)) 
            revert Unacceptable({ reason: "subject is already whitelisted" });
        globalWhitelistSet.insert(subject, "internal error");
        emit WhitelistAddress(_msgSender());
    }

    /**
     * @notice Count the globally whitelisted addresses.
     * @return count The number of globally whitelisted addresses.
     */
    function whitelistAddressCount() external view override returns (uint256 count) {
        count = globalWhitelistSet.count();
    }

    /**
     * @notice Enumerate the globally whitelisted addresses.
     * @param index The row to inspect.
     * @return whitelisted A whitelisted address.
     */
    function whitelistAddressAtIndex(uint256 index) external view override returns (address whitelisted) {
        whitelisted = globalWhitelistSet.keyAtIndex(index);
    }

    /**
     * @notice Check if an address is whitelisted globally.
     * @param checkAddress The address to inspect.
     * @return isIndeed True if the checkAddress is whitelisted.
     */
    function isWhitelisted(address checkAddress) external view override returns (bool isIndeed) {
        isIndeed = globalWhitelistSet.exists(checkAddress);
    }

    /**
     @notice Checks if the given trader has a stored, fresh credential for the admission policy in the
     credential cache and the trader wallet is present on all policy wallet check lists. 
     @dev Use static call to inspect.
     @param trader The user address, normally a trading wallet, to check.
     @param isIndeed True if the user as a fresh, cached credential.
     */
    function checkCache(address trader) public override returns (bool isIndeed) {
        uint32 userPolicyId = IUserPolicies(userPolicies).userPolicies(trader);
        bytes32 userRuleId = IPolicyManager(policyManager).policyRuleId(userPolicyId);
        bytes32 admissionPolicyRuleId = IPolicyManager(policyManager).policyRuleId(admissionPolicyId);
        address[] memory walletChecks = IPolicyManager(policyManager).policyWalletChecks(admissionPolicyId);

        uint256 expiryTime = IPolicyManager(policyManager).policyTtl(admissionPolicyId);

        for(uint256 i = 0; i < walletChecks.length; i++) {
            uint256 checkAge = block.timestamp - IWalletCheck(walletChecks[i]).birthday(trader);
            if(checkAge > expiryTime) return false;
        }

        if (admissionPolicyRuleId == universeRule && userRuleId == universeRule) {
            isIndeed = true;
        } else if (admissionPolicyRuleId == emptyRule || userRuleId == emptyRule) {
            isIndeed = false;
        } else {
            uint256 timestamp = IKeyringCredentials(keyringCredentials).getCredential(
                VERSION, 
                trader, 
                admissionPolicyId);
            uint256 cacheAge = block.timestamp - timestamp;
            isIndeed = cacheAge <= expiryTime;
        }
    }  

    /**
     @notice Check if parties are acceptable to each other, either through compliance with the active policy,
     or because they are explicitly whitelisted by the trader. 
     @param from The first of two parties to check. 
     @param to The second of two parties to check. 
     @return isAuthorised True if the parties have cached credentials signifying compliance attestations, or
     if counterparties are explicitly whitelisted by the other. 
     */
    function checkGuard(address from, address to) public override returns (bool isAuthorised) {
        bool fromGlobalWhitelisted;
        bool toGlobalWhitelisted;
        bool fromAuthorised;
        bool toAuthorised;
        bool fromIsWhitelistedByTo;
        bool toIsWhitelistedByFrom;
        bool policyAllowUserWhitelists;

        fromGlobalWhitelisted = globalWhitelistSet.exists(from);
        toGlobalWhitelisted = globalWhitelistSet.exists(to);
        policyAllowUserWhitelists = IPolicyManager(policyManager).policyAllowUserWhitelists(admissionPolicyId);
        
        if (!fromGlobalWhitelisted && policyAllowUserWhitelists) {
            fromIsWhitelistedByTo = IUserPolicies(userPolicies).isWhitelisted(to, from);
        }
        if (!toGlobalWhitelisted && policyAllowUserWhitelists) {
            toIsWhitelistedByFrom = IUserPolicies(userPolicies).isWhitelisted(from, to);
        }

        if (!fromIsWhitelistedByTo && !fromGlobalWhitelisted) fromAuthorised = checkCache(from);
        if (!toIsWhitelistedByFrom && !toGlobalWhitelisted) toAuthorised = checkCache(to);

        isAuthorised = (
            fromIsWhitelistedByTo || fromAuthorised || fromGlobalWhitelisted) && (
            toIsWhitelistedByFrom || toAuthorised || toGlobalWhitelisted
        );
    }
}
