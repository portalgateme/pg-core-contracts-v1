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

contract Zapper {
  using SafeERC20 for IERC20;

  PGRouter public pgRouter;
  InstanceRegistry public instanceRegistry;

  constructor(address _pgRouter, address _instanceRegistry) {
    pgRouter = PGRouter(_pgRouter);
    instanceRegistry = InstanceRegistry(_instanceRegistry);
  }

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
    @notice Check membership and authorization proofs using circom verifiers. Both proofs must be
     generated from the same identity commitment.
    @param _tornado The address for the deployed KeyringCredentials contract.
    @param _commitment The unique identifier of a Policy.
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

}
