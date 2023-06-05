// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./KycERC20.sol";
import "./KycETH.sol";
import "../interfaces/ITornadoInstance.sol";
import "./PGRouter.sol";
import "./InstanceRegistry.sol";

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Zapper is Ownable {
  using SafeERC20 for IERC20;

  PGRouter public pgRouter;
  InstanceRegistry public instanceRegistry;

  constructor(address _pgRouter, address _instanceRegistry) {
    pgRouter = PGRouter(_pgRouter);
    instanceRegistry = InstanceRegistry(_instanceRegistry);
  }

  /**
    @notice Once click zap in function to convert eth to kycEth tokens and deposit into relevant tc pool. The pool denomination will be the convert and deposit amount by default.
    @param _tornado TC pool instance address
    @param _commitment the note commitment, which is PedersenHash(nullifier + secret)
  */
  function zapInEth(ITornadoInstance _tornado, bytes32 _commitment) public payable {
    (
      ,
      IERC20 token,
      ,
      ,
      ,
    ) = instanceRegistry.instances(_tornado);

    address _kycEth = address(token);
    KycETH kycEth = KycETH(_kycEth);
    kycEth.depositFor{value: msg.value}();

    uint approveAmt = kycEth.allowance(address(this), address(pgRouter));
    if (approveAmt < _tornado.denomination()) {
      kycEth.approve(address(pgRouter), _tornado.denomination());
    }

    pgRouter.deposit(_tornado, _commitment, "0x");
  }

  /**
    @notice Once click zap in function to convert erc20 tokens to kycErc20 tokens and deposit into relevant tc pool. The pool denomination will be the convert and deposit amount by default.
    @param _tornado TC pool instance address
    @param _commitment the note commitment, which is PedersenHash(nullifier + secret)
  */
  function zapIn(ITornadoInstance _tornado, bytes32 _commitment) external {

    (
      ,
      IERC20 token,
      ,
      ,
      ,
    ) = instanceRegistry.instances(_tornado);

    address _kycErc20 = address(token);
    KycERC20 kycErc20 = KycERC20(_kycErc20);
    IERC20 erc20 = kycErc20.underlying();
    erc20.safeTransferFrom(msg.sender, address(this), _tornado.denomination());
    erc20.approve(_kycErc20, _tornado.denomination());

    kycErc20.depositFor(address(this), _tornado.denomination());
    kycErc20.approve(address(pgRouter), _tornado.denomination());
    pgRouter.deposit(_tornado, _commitment, "0x");
  }

  function updatePgRouter(address _newPgRouter) external onlyOwner {
    pgRouter = PGRouter(_newPgRouter);
  }

  function updateInstanceRegistry(address _newinstanceRegistry) external onlyOwner {
    instanceRegistry = InstanceRegistry(_newinstanceRegistry);
  }

}
