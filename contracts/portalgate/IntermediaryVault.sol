// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./KycERC20.sol";
import "../interfaces/ITornadoInstance.sol";
import "./PGRouter.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";


contract IntermediaryVault {

  function withdraw(address _erc20, address _to) {
    KycERC20 _kycERC20 = KycERC20(_erc20);
    uint _amount = _kycERC20.balanceOf(address(this));
    _kycERC20.withdrawTo(_to, _amount);
  }
}
