// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.14;

/**
 * @notice This stub provides a hint for hardhat artifacts and typings. It is a non-functional
 implementation to deploy behind a TransparentUpgradeableProxy. The proxy address will be passed
 to constructors that expect an immutable trusted forwarder for future gasless transaction
 support (trustedForwarder). This contract implements the essential functions as stubs that
 fail harmlessly. 
 */

contract NoImplementation {

    struct ForwardRequest {
        address from;
        address to;
        uint256 value;
        uint256 gas;
        uint256 nonce;
        bytes data;
    }

    error NotImplemented(address sender, string message);

    function getNonce(address /* from */) public pure returns (uint256) {
        return 0;
    }

    function verify(ForwardRequest calldata /* req */, bytes calldata /* signature */) public pure returns (bool) {
        return false;
    }

    function execute(ForwardRequest calldata /* req */, bytes calldata /* signature */)
        public
        payable
        returns (bool, bytes memory)
    {
        revert NotImplemented({
            sender: msg.sender,
            message: "This forwarder is not operational"
        });
    }
}
