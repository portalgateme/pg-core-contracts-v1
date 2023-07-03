// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.14;

import "../interfaces/IWalletCheck.sol";
import "../degradable/Degradable.sol";

/**
 * @notice Wallet checks are on-chain whitelists that can contain information gathered by
 * off-chain processes. Policies can specify which wallet checks must be checked on a just-in-time
 * basis. This contract establishes the interface that all wallet check contracts must implement. 
 * Future wallet check instances may employ additional logic. There is a distinct instance of a 
 * wallet check for each on-chain check. 
 */

contract WalletCheck is IWalletCheck, Degradable {

    address private constant NULL_ADDRESS = address(0);
    bytes32 public constant override ROLE_WALLETCHECK_LIST_ADMIN = keccak256("wallet check list admin role");
    bytes32 public constant override ROLE_WALLETCHECK_META_ADMIN = keccak256("wallet check meta admin");
    string public uri;

    // mapping(address => uint256) public override birthday;

    /**
    * @dev Modifier to restrict access to functions to wallet check list admins only. 
    */
    modifier onlyWalletCheckListAdmin() {
        _checkRole(
            ROLE_WALLETCHECK_LIST_ADMIN, 
            _msgSender(), 
            "WalletCheck::onlyWalletCheckListAdmin");
        _;
    }

    /**
    * @dev Modifier to restrict access to functions to wallet check meta admins only. 
    */
    modifier onlyWalletCheckMetaAdmin() {
        _checkRole(
            ROLE_WALLETCHECK_META_ADMIN, 
            _msgSender(), 
            "WalletCheck::onlyWalletCheckMetaAdmin");
        _;
    }

    /**
     * @param trustedForwarder_ Contract address that is allowed to relay message signers.
     * @param policyManager_ The policy manager contract address.
     * @param maximumConsentPeriod_ The maximum allowable user consent period.
     * @param uri_ The uri of the wallet check list. 
     */
    constructor(
        address trustedForwarder_,
        address policyManager_,
        uint256 maximumConsentPeriod_, 
        string memory uri_
    ) 
        Degradable(
            trustedForwarder_,
            policyManager_,
            maximumConsentPeriod_
        ) 
    {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(ROLE_WALLETCHECK_META_ADMIN, _msgSender());
        emit Deployed(_msgSender(), trustedForwarder_, policyManager_, maximumConsentPeriod_, uri);
        updateUri(uri_);
    }

    /**
     * @notice The wallet check admin can set the uri of the list maintained in this contract. 
     * @param uri_ The new uri.
     */
    function updateUri(string memory uri_) public override onlyWalletCheckMetaAdmin {
        if (bytes(uri_).length == 0) 
            revert Unacceptable({
                reason: "uri_ cannot be empty"
            });
        uri = uri_;
        emit UpdateUri(_msgSender(), uri_);
    }

    /**
     * @notice Record a wallet check. 
     * @param wallet The subject wallet.
     * @param whitelisted True if the wallet has passed the checks represented by this contract.
     * @param timestamp The effective time of the wallet check. Not used if whitelisted is false.
     */
    function setWalletCheck(
        address wallet, 
        bool whitelisted, 
        uint256 timestamp
    ) external override onlyWalletCheckListAdmin {
        if (whitelisted) {
            _recordUpdate(wallet, timestamp);
        } else {
            subjectUpdates[bytes32(uint256(uint160(wallet)))] = 0;
        }
    }

    /**
     * @notice Inspect the Wallet Check.
     * @param observer The observer for degradation mitigation consent. 
     * @param wallet The wallet to inspect. 
     * @param admissionPolicyId The admission policy for the wallet to inspect.
     * @return passed True if a wallet check exists or if mitigation measures are applicable.
     */
    function checkWallet(
        address observer, 
        address wallet,
        uint32 admissionPolicyId
    ) external override returns (bool passed) {
        
        passed = _checkKey(
            observer,
            wallet,
            admissionPolicyId
        );
    }    

}
