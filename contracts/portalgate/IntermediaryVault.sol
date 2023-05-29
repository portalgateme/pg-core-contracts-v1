// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./KycERC20.sol";
import "../interfaces/ITornadoInstance.sol";
import "./PGRouter.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";


contract IntermediaryVault {
  using SafeERC20 for IERC20;

  address public governance;
  PGRouter public router;

  event IntermediaryVaultWithdrawal(address indexed _recipient, address erc20, uint erc20Amt, uint refund, bool success);

  modifier onlyGovernance() {
    require(msg.sender == governance, "Not authorized");
    _;
  }

  modifier onlyRouter() {
    require(msg.sender == address(router), "Not authorized");
    _;
  }

  constructor(address _router) {
    router = PGRouter(_router);
    governance = msg.sender;
  }

  function withdraw(address _erc20, address _recipient, uint _refund) external virtual onlyRouter {
    KycERC20 _kycERC20 = KycERC20(_erc20);
    uint _amount = _kycERC20.balanceOf(address(this));
    _kycERC20.withdrawTo(_recipient, _amount);

    require( _refund == address(this).balance, "Refund is not available");

    bool success = true;
    if (_refund > 0) {
      (success, ) = _recipient.call{value: _refund}("");
    }

    emit IntermediaryVaultWithdrawal(_recipient, _erc20, _amount, _refund, success);
  }

  /// @dev Method to claim junk and accidentally sent tokens
  function rescueTokens(IERC20 _token, address payable _to, uint256 _amount) external virtual onlyGovernance {
    require(_to != address(0), "PG: can not send to zero address");

    if (address(_token) == address(0)) {
      // for Ether
      uint256 totalBalance = address(this).balance;
      uint256 balance = Math.min(totalBalance, _amount);
      _to.transfer(balance);
    } else {
      // any other erc20
      uint256 totalBalance = _token.balanceOf(address(this));
      uint256 balance = Math.min(totalBalance, _amount);
      require(balance > 0, "PG: trying to send 0 balance");
      _token.safeTransfer(_to, balance);
    }
  }
}
