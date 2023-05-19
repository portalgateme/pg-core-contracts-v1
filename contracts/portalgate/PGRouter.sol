// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "../libs/EnsResolve.sol";
import "./RelayerRegistry.sol";
import "../tornado-core/ERC20Tornado.sol";

contract TornadoRouter is EnsResolve {
    using SafeERC20 for IERC20;

    event EncryptedNote(address indexed sender, bytes encryptedNote);
        
    RelayerRegistry public relayerRegistry;

    constructor(bytes32 _relayerRegistry) {        
        relayerRegistry = RelayerRegistry(resolve(_relayerRegistry));        
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