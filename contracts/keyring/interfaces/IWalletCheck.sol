// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.14;

interface IWalletCheck {

    error Unacceptable(string reason);

    event Deployed(address admin, address trustedForwarder);
    
    event SetWalletWhitelist(address admin, address wallet, bool isWhitelisted);

    function ROLE_WALLETCHECK_ADMIN() external view returns (bytes32);

    function birthday(address wallet) external view returns(uint256 timestamp);

    function setWalletWhitelist(address wallet, bool whitelisted, uint256 timestamp) external;
}
