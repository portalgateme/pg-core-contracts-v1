// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.14;

interface IUserPolicies {

    error Unacceptable(string reason);

    event Deployed(address trustedForwarder, address policyManager);

    event SetUserPolicy(address indexed trader, uint32 indexed policyId);

    event AddTraderWhitelisted(address indexed, address indexed whitelisted);

    event RemoveTraderWhitelisted(address indexed, address indexed whitelisted);

    function userPolicies(address trader) external view returns (uint32);

    function setUserPolicy(uint32 policyId) external;

    function addWhitelistedTrader(address whitelisted) external;

    function removeWhitelistedTrader(address whitelisted) external;

    function whitelistedTraderCount(address trader) external view returns (uint256 count);

    function whitelistedTraderAtIndex(address trader, uint256 index) external view returns (address whitelisted);

    function isWhitelisted(address trader, address counterparty) external view returns (bool isIndeed);
}