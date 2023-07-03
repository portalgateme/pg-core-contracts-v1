// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.14;

import "../interfaces/IKeyringCredentials.sol";
import "../interfaces/IPolicyManager.sol";
import "../degradable/Degradable.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

/**
 @notice Holds the time-limited credential cache, organized by user and admission policy. 
 The credentials are non-transferrable and are represented as timestamps. Non-zero 
 entries indicate that an authorized credential updater such as the KeyringZkCredentialUpdater
 accepted evidence of compliance and recorded it here with a timestamp to indicate the 
 start time to use for calculating the credential's age. 
 */

contract KeyringCredentials is IKeyringCredentials, Degradable, Initializable {

    address private constant NULL_ADDRESS = address(0);
    uint8 private constant VERSION = 1;
    bytes32 public constant ROLE_CREDENTIAL_UPDATER = keccak256("Credentials updater");

    /**
     * @notice Revert if the message sender doesn't have the Credentials updater role.
     */
    modifier onlyUpdater() {
        _checkRole(ROLE_CREDENTIAL_UPDATER, _msgSender(), "KeyringCredentials:onlyUpdater");
        _;
    }

    /**
     * @param trustedForwarder Contract address that is allowed to relay message signers.
     * @param policyManager_ The deployed policyManager contract address.
     * @param maximumConsentPeriod_ The time limit for user consent to mitigation procedures. 
     */
    constructor(
        address trustedForwarder, 
        address policyManager_,
        uint256 maximumConsentPeriod_
    ) 
        Degradable(
            trustedForwarder,
            policyManager_,
            maximumConsentPeriod_
        ) 
    {
        emit CredentialsDeployed(_msgSender(), trustedForwarder, policyManager, maximumConsentPeriod);
    }

    /**
     * @notice This upgradeable contract must be initialized.
     *  @dev The initializer function MUST be called directly after deployment 
     * because anyone can call it but overall only once.
     */
    function init() external override initializer {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        emit CredentialsInitialized(_msgSender());
    }

    /**
     * @notice This function is called by a trusted and permitted contract such as the 
     * KeyringZkCredentialUpdater. There is no prohibition on multiple proving schemes 
     * at the cache level since this contract requires only that the caller has permission.
     * @param trader The user address for the Credential update.
     * @param admissionPolicyId The unique identifier of a Policy.
     * @param timestamp The timestamp established by the credential updater.
     */
    function setCredential(
        address trader,
        uint32 admissionPolicyId,
        uint256 timestamp
    ) external override onlyUpdater {

        bytes32 key = keyGen(
            trader,
            admissionPolicyId
        );

        _recordUpdate(key, timestamp);
        emit UpdateCredential(1, _msgSender(), trader, admissionPolicyId);
    }

    /**
     * @notice Inspect the credential cache.
     * @param observer The observer for degradation mitigation consent. 
     * @param trader The user address for the Credential update.
     * @param admissionPolicyId The admission policy for the credential to inspect.
     * @return passed True if a valid cached credential exists or if mitigation measures are applicable.
     */
    function checkCredential(
        address observer, 
        address trader,
        uint32 admissionPolicyId
    ) external returns (bool passed) {
        
        bytes32 key = keyGen(
            trader,
            admissionPolicyId
        );

        passed = _checkKey(
            observer,
            key,
            admissionPolicyId
        );
    }

    /**
     * @notice Generate a cache key for a trader and policyId.
     * @param trader The trader for the credential cache.
     * @param admissionPolicyId The policyId.
     * @return key The credential cache key. 
     */
    function keyGen(
        address trader,
        uint32 admissionPolicyId
    ) public pure override returns (bytes32 key) {
        key = keccak256(abi.encodePacked(
            VERSION,
            trader,
            admissionPolicyId
        ));
    }
}
