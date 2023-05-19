// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.14;

import "../lib/AddressSet.sol";
import "../access/KeyringAccessControl.sol";
import "../interfaces/IUserPolicies.sol";
import "../interfaces/IPolicyManager.sol";

/**
 @notice Users select one policy. Attestors are required to confirm compatibility of the user policy with
 the admission policy to check before issuing attestations. Traders may also define whitelists which are
 counterparties they will trade with even if compliance cannot be confirmed by an attestor. Whitelists
 only apply where admission policy owners have set the admission policy allowUserWhitelists flag to true. 
 */

contract UserPolicies is IUserPolicies, KeyringAccessControl {

    using AddressSet for AddressSet.Set;
    address private constant NULL_ADDRESS = address(0);
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    address public immutable policyManager;

    mapping(address => uint32) public override userPolicies;
    mapping(address => AddressSet.Set) private traderWhitelists;

    /**
     * @param trustedForwarder Contract address that is allowed to relay message signers.
     */
    constructor(address trustedForwarder, address policyManager_) KeyringAccessControl(trustedForwarder)
    {
        if (trustedForwarder == NULL_ADDRESS)
            revert Unacceptable({
                reason: "trustedForwarder cannot be empty"
            });
        if (policyManager_ == NULL_ADDRESS)
            revert Unacceptable({
                reason: "policyManager cannot be empty"
            });
        policyManager = policyManager_;
        emit Deployed(trustedForwarder, policyManager_);
    }
    
    /**
     @notice Users, normally auth wallets, set a policy to be checked by attestors.
     @param policyId The policy id to enable for the auth wallet. 
     */
    function setUserPolicy(uint32 policyId) external override {
        if (!IPolicyManager(policyManager).isPolicy(policyId)) 
            revert Unacceptable({
                reason: "policyId not found"
            });
        userPolicies[_msgSender()] = policyId;
        emit SetUserPolicy(_msgSender(), policyId);
    }

    /**
     @notice Trader wallets may appoint whitelisted addresses to trade with without the protection
     of Keyring compliance checks. 
     @param whitelisted A counterparty address to trade with unconditionally. Must not be whitelisted. 
     */
    function addWhitelistedTrader(address whitelisted) external override {
        if (whitelisted == _msgSender())
            revert Unacceptable({ reason: "self whitelisting is not permitted" });
        AddressSet.Set storage wl = traderWhitelists[_msgSender()];
        wl.insert(whitelisted, "UserPolicies:addTraderWhitelisted");
        emit AddTraderWhitelisted(_msgSender(), whitelisted);
    }

    /**
     @notice Trader wallets may appoint whitelisted addresses to trade with without the protection
     of Keyring compliance checks.
     @param whitelisted A counterparty to re-enable compliance checks. Must be whitelisted.. 
     */
    function removeWhitelistedTrader(address whitelisted) external override {
        AddressSet.Set storage wl = traderWhitelists[_msgSender()];
        wl.remove(whitelisted, "UserPolicies:addTraderWhitelisted");
        emit RemoveTraderWhitelisted(_msgSender(), whitelisted);
    }

    /**
     * @notice Count the addresses on a trader whitelist.
     * @param trader The trader whitelist to inspect.
     * @return count The number of addresses on a trader whitelist.
     */
    function whitelistedTraderCount(address trader) external view override returns (uint256 count) {
        count = traderWhitelists[trader].count();
    }

    /**
     * @notice Iterate the addresses on a trader whitelist. 
     * @param trader The trader whitelist to inspect. 
     * @param index The row to inspect. 
     * @return whitelisted The address in the trader whitelist at the index row. 
     */
    function whitelistedTraderAtIndex(
        address trader, 
        uint256 index
    ) external view override returns (address whitelisted) {
        whitelisted = traderWhitelists[trader].keyAtIndex(index);
    }

    /**
     * @notice check if a counterparty is whitelisted by a trader.
     * @param trader The trader whitelist to inspect.
     * @param counterparty The address to search for on the trader whitelist. 
     * @return isIndeed True if the counterparty is present on the trader whitelist. 
     */
    function isWhitelisted(address trader, address counterparty) external view override returns (bool isIndeed) {
        isIndeed = traderWhitelists[trader].exists(counterparty);
    }
}
