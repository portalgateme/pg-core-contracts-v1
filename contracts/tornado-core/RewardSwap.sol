// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IPGAT.sol";

// simplified reward swap contract
contract RewardSwap {

  IPGAT public apToken;
  address public miner;
  address public immutable operator;

  event Swap(address indexed recipient, uint256 amount, uint256 tokens);

  modifier onlyMiner() {
    require(msg.sender == miner, "Only Miner contract can call");
    _;
  }

  modifier onlyOperator() {
    require(msg.sender == operator, "Only Operator can call");
    _;
  }

  constructor(
    address _apToken,
    address _miner
  ) public {
    apToken = IPGAT(_apToken);
    miner = _miner;
    operator = msg.sender;
  }

  function setMiner(address _miner) external onlyOperator {
    miner = _miner;
  }

  function setAPToken(address _apToken) external onlyOperator {
    apToken = IPGAT(_apToken);
  }

  function swap(address _recipient, uint256 _amount) external onlyMiner returns (uint256) {
    uint256 tokens = _amount;
    apToken.mint(_recipient, _amount);
    emit Swap(_recipient, _amount, tokens);
    return tokens;
  }
}
