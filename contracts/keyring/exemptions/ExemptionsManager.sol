// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.14;

import "../interfaces/IExemptionsManager.sol";
import "../interfaces/IPolicyManager.sol";
import "../access/KeyringAccessControl.sol";
import "../lib/AddressSet.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

/**
 * @title ExemptionsManager
 * @notice This contract manages the exemptions for the policy engine.
 * It allows an exemptions admin to manage global exemptions and policy admins
 * to manage policy-specific exemptions.
 * @dev Inherits from IExemptionsManager, KeyringAccessControl, and Initializable.
 */

contract ExemptionsManager is IExemptionsManager, KeyringAccessControl, Initializable {
    using AddressSet for AddressSet.Set;

    bytes32 public constant override ROLE_GLOBAL_EXEMPTIONS_ADMIN = keccak256("x");
    address private constant NULL_ADDRESS = address(0);
    AddressSet.Set private globalExemptionsSet;
    mapping(uint32 => AddressSet.Set) private policyExemptions;

    address public override policyManager;
    mapping(address => string) public override exemptionDescriptions;

    /**
     * @notice Keyring Governance has exclusive access to global exemptions.
     * @dev Reverts if the user doesn't have the global validation admin role.
     */
    modifier onlyExemptionsAdmin() {
        _checkRole(ROLE_GLOBAL_EXEMPTIONS_ADMIN, _msgSender(), "em:ea");
        _;
    }

    /**
     * @notice Only the Policy Admin can manipulate policy-specific settings.
     * @param policyId The policyId to check.
     * @dev Reverts if the sender is not an admin for the specified policy.
     */
    modifier onlyPolicyAdmin (uint32 policyId) {
        bytes32 role = bytes32(uint256(policyId));
        if (!IPolicyManager(policyManager).hasRole(role, _msgSender()))
            revert Unauthorized({
                sender: _msgSender(),
                module: "KeyringAccessControl",
                method: "_checkRole",
                role: role,
                reason: "sender does not have the required role",
                context: "ExemptionsManager:onlyPolicyAdmin"
            });
        _;
    }

    constructor(address trustedForwarder) KeyringAccessControl(trustedForwarder){}

    /**
     * @notice Initializes the contract with the provided policyManager address.
     * @dev Can only be called once, as it is an initializer function.
     * @param policyManager_ The address of the PolicyManager contract.
     */
    function init(address policyManager_) external override initializer {
        if(policyManager_ == NULL_ADDRESS) revert Unacceptable({ reason: "policyManager_ cannot be empty" });
        policyManager = policyManager_;
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        emit ExemptionsManagerInitialized(_msgSender(), policyManager_);
    }

    /**
     * @notice Admits the specified addresses as global exemptions with a description.
     * @dev Can only be called by the exemptions admin. Admission is irrevocable. 
     * @param exemptAddresses An array of addresses to be admitted as global exemptions.
     * @param description A human-readable description of the exempt addresses.
     */
    function admitGlobalExemption(
        address[] calldata exemptAddresses,
        string memory description
    ) 
        external
        override
        onlyExemptionsAdmin
    {
        for (uint256 i=0; i<exemptAddresses.length; i++) {
            globalExemptionsSet.insert(exemptAddresses[i], "PolicyStorage:insertGlobalExemptAddress");
            _updateGlobalExemption(exemptAddresses[i], description);
            emit AdmitGlobalExemption(_msgSender(), exemptAddresses[i], description);
        }
    }

    /**
     * @notice Updates the description of an existing global exemption address.
     * @dev Can only be called by the exemptions admin.
     * @param exemptAddress The exempt address whose description needs to be updated.
     * @param description The new human-readable description for the exempt address.
     */
    function updateGlobalExemption(
        address exemptAddress,
        string memory description
    ) 
        external
        override
        onlyExemptionsAdmin
    {
        // null address is allowed to be exempt
        _updateGlobalExemption(exemptAddress, description);  
        emit UpdateGlobalExemption(_msgSender(), exemptAddress, description);
    }

    function _updateGlobalExemption(
        address exemptAddress,
        string memory description
    )
        internal
    {
        // null address is allowed to be exempt
        if (!globalExemptionsSet.exists(exemptAddress))
            revert Unacceptable({
                reason: "unknown exemptAddress"
            });
        if (bytes(description).length == 0)
            revert Unacceptable({
                reason: "description cannot be empty"
            });
        exemptionDescriptions[exemptAddress] = description;  
    }

    /**
     * @notice Approves the specified exemptions for a given policy.
     * @dev Can only be called by a policy admin for the specified policyId. Only policies
     * that are admitted globally are eligable for approval. Approval is irrevocable. 
     * @param policyId The ID of the policy for which exemptions are being approved.
     * @param exemptions An array of addresses to be approved as exemptions for the policy.
     */
    function approvePolicyExemptions(
        uint32 policyId,
        address[] memory exemptions
    )
        external 
        override
        onlyPolicyAdmin(policyId)
    {
        for(uint256 i=0; i<exemptions.length; i++) {
            if(!isGlobalExemption(exemptions[i]))
                revert Unacceptable ({
                    reason: "exemption is not approved"
                });
            policyExemptions[policyId].insert(
                exemptions[i],
                "ExemptionsManager.approvePolicyExemptions"
            );
            emit ApprovePolicyExemptions(_msgSender(), policyId, exemptions[i]);
        }
    }

    /**
     * @notice Returns the count of global exemptions.
     * @return count The count of global exemptions.
     */
    function globalExemptionsCount() external view override returns (uint256 count) {
        count = globalExemptionsSet.count();
    }

    /**
     * @notice Returns the global exemption address at the specified index.
     * @param index The index of the exemption in the global exemptions list.
     * @return exemption The global exemption address at the specified index.
     */
    function globalExemptionAtIndex(uint256 index) external view override returns (address exemption) {
        if (index >= globalExemptionsSet.count())
            revert Unacceptable ({
                reason: "index out of range"
            });
        exemption = globalExemptionsSet.keyAtIndex(index);
    }

    /**
     * @notice Checks if a given address is a global exemption.
     * @param exemption The address to be checked as a global exemption.
     * @return isIndeed True if the address is a global exemption, otherwise false.
     */
    function isGlobalExemption(address exemption) public view override returns (bool isIndeed) {
        isIndeed = globalExemptionsSet.exists(exemption);
    }

    /**
     * @notice Returns the count of policy-specific exemptions for a given policyId.
     * @param policyId The ID of the policy for which exemptions count is required.
     * @return count The count of exemptions for the given policyId.
     */
    function policyExemptionsCount(uint32 policyId) external view override returns (uint256 count) {
        count = policyExemptions[policyId].count();
    }
    
    /**
     * @notice Returns the policy-specific exemption address at the specified index for a given policyId.
     * @param policyId The ID of the policy for which the exemption is required.
     * @param index The index of the exemption in the policy exemptions list.
     * @return exemption The exemption address at the specified index.
     */
    function policyExemptionAtIndex(uint32 policyId, uint256 index) external view override returns (address exemption) {
        AddressSet.Set storage pe = policyExemptions[policyId];
        if (index >= pe.count())
            revert Unacceptable({
                reason: "index out of range"
            });
        exemption = pe.keyAtIndex(index);
    }

    /**
     * @notice Checks if a given address is an exemption for a specified policyId.
     * @param policyId The ID of the policy for which the exemption check is required.
     * @param exemption The address to be checked as an exemption for the policy.
     * @return isIndeed True if the address is an exemption for the policy, otherwise false.
     */
    function isPolicyExemption(uint32 policyId, address exemption) external view override returns (bool isIndeed) {
        isIndeed = policyExemptions[policyId].exists(exemption);
    }    

}