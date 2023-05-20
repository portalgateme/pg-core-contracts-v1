// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract RelayerRegistry is Ownable {
    mapping(address => bool) public isRelayer;

    event RelayerAdded(address indexed relayer);
    event RelayerRemoved(address indexed relayer);

    function add(address _relayer) public onlyOwner {
        require(!isRelayer[_relayer], "The relayer already exists");
        isRelayer[_relayer] = true;
        emit RelayerAdded(_relayer);
    }

    function remove(address _relayer) public onlyOwner {
        require(isRelayer[_relayer], "The relayer does not exist");
        isRelayer[_relayer] = false;
        emit RelayerRemoved(_relayer);
    }

    function isRelayerRegistered(address _relayer) external view returns (bool) {
        return isRelayer[_relayer];
    }

}
