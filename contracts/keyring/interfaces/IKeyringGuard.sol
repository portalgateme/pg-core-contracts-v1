// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.14;

/**
 * @notice KeyringGuard implementation that uses immutables and presents a simplified modifier.
 */

interface IKeyringGuard {

    error Unacceptable(string reason);

    event KeyringGuardConfigured(
        address keyringCredentials,
        address policyManager,
        address userPolicies,
        uint32 admissionPolicyId,
        bytes32 universeRule,
        bytes32 emptyRule
    );

    event WhitelistAddress(address admin);

    function whitelistAddressCount() external view returns (uint256 count);

    function whitelistAddressAtIndex(uint256 index) external view returns (address whitelisted);

    function isWhitelisted(address checkAddress) external view returns (bool isIndeed);

    function checkCache(address trader) external returns (bool isIndeed);

    function checkGuard(address from, address to) external returns (bool isAuthorized);
}