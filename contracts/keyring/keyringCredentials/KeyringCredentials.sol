// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.14;

import "../interfaces/IKeyringCredentials.sol";
import "../interfaces/IPolicyManager.sol";
import "../access/KeyringAccessControl.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

/**
 @notice Holds the time-limited credential cache, organized by user and admission policy. 
 The credentials are non-transferrable and are represented as timestamps. Non-zero 
 entries indicate that an authorized credential updater such as the KeyringZkCredentialUpdater
 accepted evidence of compliance and recorded it here with a timestamp to indicate the 
 start time to use for calculating the credential's age. 
 */

contract KeyringCredentials is IKeyringCredentials, KeyringAccessControl, Initializable {

    address private constant NULL_ADDRESS = address(0);
    uint8 private constant VERSION = 1;
    bytes32 public constant ROLE_CREDENTIAL_UPDATER = keccak256("Credentials updater");
    address public immutable policyManager;

    /**
     @dev The credentials are indexed by (version => trader => admissionPolicyId) => updateTime
     where the version is always 1.
     */
    mapping(uint8 => mapping(address => mapping(uint32 => uint256)))
        public override cache;

    /**
     @notice Revert if the message sender doesn't have the Credentials updater role.
     */
    modifier onlyUpdater() {
        _checkRole(ROLE_CREDENTIAL_UPDATER, _msgSender(), "KeyringCredentials:onlyUpdater");
        _;
    }

    /**
     @param trustedForwarder Contract address that is allowed to relay message signers.
     */
    constructor(address trustedForwarder, address policyManager_) KeyringAccessControl(trustedForwarder) {
        if (trustedForwarder == NULL_ADDRESS)
            revert Unacceptable({
                reason: "trustedForwarder cannot be empty"
            });
        if (policyManager_ == NULL_ADDRESS)
            revert Unacceptable({
                reason: "policyManager_ cannot be empty"
            });
        policyManager = policyManager_;
        emit CredentialsDeployed(_msgSender(), trustedForwarder, policyManager);
    }

    /**
     @notice This upgradeable contract must be initialized.
     @dev The initializer function MUST be called directly after deployment 
     because anyone can call it but overall only once.
     */
    function init() external override initializer {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        emit CredentialsInitialized(_msgSender());
    }

    /**
     @notice This function is called by a trusted and permitted contract such as the 
     KeyringZkCredentialUpdater. There is no prohibition on multiple proving schemes 
     at the cache level since this contract requires only that the caller has permission.
     @param trader The user address for the Credential update.
     @param admissionPolicyId The unique identifier of a Policy.
     @param timestamp The timestamp established by the credential updater.
     */
    function setCredential(
        address trader,
        uint32 admissionPolicyId,
        uint256 timestamp
    ) external override onlyUpdater {
        if (timestamp > block.timestamp)
            revert Unacceptable({
                reason: "timestamp must be in the past"
            });
        if (cache[VERSION][trader][admissionPolicyId] > timestamp)
            revert Unacceptable({
                reason: "timestamp is older than existing credential"
            });
        cache[VERSION][trader][admissionPolicyId] = timestamp;
        emit UpdateCredential(1, _msgSender(), trader, admissionPolicyId);
    }

    /**
     @notice Inspect the credential cache.
     @param version Cache organization version.
     @param trader The user to inspect.
     @param admissionPolicyId The admission policy for the credential to inspect.
     @return timestamp The timestamp established when the credential was recorded. 0 if no credential.
     */
    function getCredential(
        uint8 version, 
        address trader, 
        uint32 admissionPolicyId
    ) external view returns (uint256 timestamp) {
        timestamp = cache[version][trader][admissionPolicyId];
    }
}
