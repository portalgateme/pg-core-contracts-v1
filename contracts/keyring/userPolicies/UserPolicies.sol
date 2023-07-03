// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.14;

import "../lib/AddressSet.sol";
import "../access/KeyringAccessControl.sol";
import "../interfaces/IUserPolicies.sol";
import "../interfaces/IPolicyManager.sol";

/**
 @notice Users select one policy. Attestors are required to confirm compatibility of the user policy with
 the admission policy to check before issuing attestations. Traders may also define approves which are
 counterparties they will trade with even if compliance cannot be confirmed by an attestor. Approves
 only apply where admission policy owners have set the admission policy allowUserApproves flag to true. 
 */

contract UserPolicies is IUserPolicies, KeyringAccessControl {

    using AddressSet for AddressSet.Set;
    address private constant NULL_ADDRESS = address(0);
    
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    address public immutable policyManager;

    mapping(address => uint32) public override userPolicies;
    mapping(address => AddressSet.Set) private approvedCounterparties;

    /**
     * @param trustedForwarder Contract address that is allowed to relay message signers.
     */
    constructor(address trustedForwarder, address policyManager_) KeyringAccessControl(trustedForwarder)
    {
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
     @notice Trader wallets may appoint approved addresses to trade with without the protection
     of Keyring compliance checks. 
     @param approved A counterparty address to trade with unconditionally. Must not be approved. 
     */
    function addApprovedCounterparty(address approved) public override {
        if (approved == _msgSender())
            revert Unacceptable({ reason: "self approving is not permitted" });
        AddressSet.Set storage wl = approvedCounterparties[_msgSender()];
        wl.insert(approved, "UserPolicies:addTraderApproved");
        emit AddApprovedCounterparty(_msgSender(), approved);
    }

    /**
     @notice Trader wallets may appoint approved addresses to trade with without the protection
     of Keyring compliance checks. 
     @param approved Counterparty addresses to trade with unconditionally. Must not be approved. 
     */
    function addApprovedCounterparties(address[] calldata approved) external override {
        for (uint256 i=0; i<approved.length; i++) {
            addApprovedCounterparty(approved[i]);
        }
    }    

    /**
     @notice Trader wallets may appoint approved addresses to trade with without the protection
     of Keyring compliance checks.
     @param approved A counterparty to re-enable compliance checks. Must be approved. 
     */
    function removeApprovedCounterparty(address approved) public override {
        AddressSet.Set storage wl = approvedCounterparties[_msgSender()];
        wl.remove(approved, "UserPolicies:addTraderApproved");
        emit RemoveApprovedCounterparty(_msgSender(), approved);
    }

    /**
     @notice Trader wallets may appoint approved addresses to trade with without the protection
     of Keyring compliance checks. 
     @param approved Counterparty addresseses to re-enable compliance checks. Must be approved.
     */
    function removeApprovedCounterparties(address[] calldata approved) external override {
        for (uint256 i=0; i<approved.length; i++) {
            removeApprovedCounterparty(approved[i]);
        }
    }    

    /**
     * @notice Count the addresses on a trader approve.
     * @param trader The trader approve to inspect.
     * @return count The number of addresses on a trader approve.
     */
    function approvedCounterpartyCount(address trader) external view override returns (uint256 count) {
        count = approvedCounterparties[trader].count();
    }

    /**
     * @notice Iterate the addresses on a trader approve. 
     * @param trader The trader approve to inspect. 
     * @param index The row to inspect. 
     * @return approved The address in the trader approve at the index row. 
     */
    function approvedCounterpartyAtIndex(
        address trader, 
        uint256 index
    ) external view override returns (address approved) {
        approved = approvedCounterparties[trader].keyAtIndex(index);
    }

    /**
     * @notice check if a counterparty is approved by a trader.
     * @param trader The trader approve to inspect.
     * @param counterparty The address to search for on the trader approve. 
     * @return isIndeed True if the counterparty is present on the trader approve. 
     */
    function isApproved(address trader, address counterparty) external view override returns (bool isIndeed) {
        isIndeed = approvedCounterparties[trader].exists(counterparty);
    }
}
