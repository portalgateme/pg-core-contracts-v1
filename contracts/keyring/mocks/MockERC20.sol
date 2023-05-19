// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.14;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockERC20 is ERC20 {

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _supply
    ) ERC20(_name, _symbol) {
        require(bytes(_name).length > 0, "MockERC20:constructor: name cannot be empty");
        require(bytes(_symbol).length > 0, "MockERC20:constructor: symbol cannot be empty");
        require(_supply > 0, "MockERC20:constructor: supply cannot be zero");
        _mint(msg.sender, _supply);
    }
}
