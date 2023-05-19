// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.14;

import "../interfaces/IWalletCheck.sol";
import "../access/KeyringAccessControl.sol";

contract WalletCheck is IWalletCheck, KeyringAccessControl {

    /**
     * @notice Wallet checks are on-chain whitelists that can contain information gathered by
     off-chain processes. Policies can specify which wallet checks must be checked on a just-in-time
     basis. This contract establishes the interface that all wallet check contracts must implement. 
     Future wallet check instances may employ additional logic. There is a distinct instance of a 
     wallet check for each on-chain check. 
     */

    address private constant NULL_ADDRESS = address(0);
    bytes32 public constant override ROLE_WALLETCHECK_ADMIN = keccak256("wallet check admin role");

    mapping(address => uint256) public override birthday;

    modifier onlyWalletCheckAdmin() {
        _checkRole(ROLE_WALLETCHECK_ADMIN, _msgSender(), "WalletCheck::onlyWalletCheckAdmin");
        _;
    }

    constructor(address trustedForwarder) KeyringAccessControl(trustedForwarder) {
        if(trustedForwarder == NULL_ADDRESS)
            revert Unacceptable("trustedForwarder cannot be empty");
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        emit Deployed(_msgSender(), trustedForwarder);
    }

    /**
     * @notice Set the whitelisted boolean for a specific trading wallet to true or false.
     * @param wallet The subject wallet.
     * @param whitelisted True if the wallet has passed the checks represented by this contract.
     * @param timestamp The effective time of the wallet check.
     */
    function setWalletWhitelist(address wallet, bool whitelisted, uint256 timestamp) external override onlyWalletCheckAdmin {
        if(timestamp > block.timestamp) 
            revert Unacceptable("timestamp cannot be in the future");
        birthday[wallet] = (whitelisted) ? timestamp : 0;
        emit SetWalletWhitelist(_msgSender(), wallet, whitelisted);
    }

}
