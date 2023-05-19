// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IRelayerRegistry {
    function getRelayerBalance(bytes32 relayer) external view returns (uint256);

    function isRelayerRegistered(bytes32 relayer) external view returns (bool);
}
