// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./RelayerRegistry.sol";
import "../tornado-core/ERC20Tornado.sol";

contract PGRouter {
    RelayerRegistry public relayerRegistry;

    constructor(address _relayerRegistry) {
        relayerRegistry = RelayerRegistry(_relayerRegistry);
    }

    function withdraw(
        Tornado _tornado,
        address _relayerAddress,
        bytes calldata _proof,
        bytes32 _root,
        bytes32 _nullifierHash,
        address payable _recipient,
        address payable _relayer,
        uint256 _fee,
        uint256 _refund
    ) public payable virtual {
        require(relayerRegistry.isRelayerRegistered(_relayerAddress), "Invalid Relayer");

        _tornado.withdraw{value: msg.value}(
            _proof,
            _root,
            _nullifierHash,
            _recipient,
            _relayer,
            _fee,
            _refund
        );
    }

}