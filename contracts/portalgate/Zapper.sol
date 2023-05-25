// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./KycERC20.sol";
import "../interfaces/ITornadoInstance.sol";
import "./PGRouter.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Zapper {
  PGRouter public pgRouter;

  constructor(address _pgRouter) {
    pgRouter = PGRouter(_pgRouter);
  }

  function zappIn(address _erc20, address _kycErc20, ITornadoInstance _tornado, uint _approveAmt, uint _zappedInAmt, bytes32 _commitment) external {
    ERC20 erc20 = ERC20(_erc20);
    KycERC20 kycErc20 = KycERC20(_kycErc20);
    uint approveAmt1 = kycErc20.allowance(msg.sender, address(this));

    erc20.transferFrom(msg.sender, address(this), _zappedInAmt);

    if (approveAmt1 <= _approveAmt) {
      erc20.increaseAllowance(_kycErc20, _approveAmt);
    }

    kycErc20.depositFor(address(this), _zappedInAmt);

    uint approveAmt2 = kycErc20.allowance(address(this), address(pgRouter));
    if (approveAmt2 <= _approveAmt) {
      kycErc20.increaseAllowance(address(pgRouter), _approveAmt);
    }

    pgRouter.deposit(_tornado, _commitment, "0x");
  }

}
