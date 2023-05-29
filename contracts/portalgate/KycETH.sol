// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "../keyring/integration/KeyringGuard.sol";


contract KycETH is KeyringGuard {
    string public name     = "KYC Ether";
    string public symbol   = "kycETH";
    uint8  public decimals = 18;

    event  Approval(address indexed owner, address indexed spender, uint amount);
    event  Transfer(address indexed from, address indexed to, uint amount);
    event  Deposit(address indexed to, uint amount);
    event  Withdrawal(address indexed from, uint amount);

    mapping (address => uint)                       public  balanceOf;
    mapping (address => mapping (address => uint))  public  allowance;

    modifier checkAuthorisations(address from, address to) {
        if (!checkGuard(from, to))
            revert Unacceptable({
                reason: "trader not authorized"
            });
        _;
    }

    /**
     @notice Specify the token to wrap and the new name / symbol of the wrapped token - then good to go!
     @param keyringCredentials The address for the deployed KeyringCredentials contract.
     @param policyManager The address for the deployed PolicyManager contract.
     @param userPolicies The address for the deployed UserPolicies contract.
     @param policyId The unique identifier of a Policy.
     */
    constructor(
        address trustedForwarder,
        address keyringCredentials,
        address policyManager,
        address userPolicies,
        uint32 policyId
    )
        KeyringGuard(trustedForwarder, keyringCredentials, policyManager, userPolicies, policyId)
    {}

    function depositFor() public payable
    {
      balanceOf[msg.sender] += msg.value;
      emit Deposit(msg.sender, msg.value);
    }

    function withdrawTo(address to, uint amount) public
    {
      if(to != _msgSender()) {
        if (!checkGuard(_msgSender(), trader))
          revert Unacceptable({
              reason: "trader not authorized"
          });
      }

      require(balanceOf[msg.sender] >= amount);
      balanceOf[msg.sender] -= amount;
      payable(to).transfer(amount);
      emit Withdrawal(msg.sender, amount);
    }

    function totalSupply() public view returns (uint) {
        return address(this).balance;
    }

    function approve(address spender, uint amount) public returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transfer(address to, uint amount)
        public
        checkAuthorisations(msg.sender, to)
        returns (bool)
    {
        return transferFrom(msg.sender, to, amount);
    }

    function transferFrom(address from, address to, uint amount)
        public
        checkAuthorisations(from, to)
        returns (bool)
    {
        require(balanceOf[from] >= amount);

        if (from != msg.sender && allowance[from][msg.sender] > 0) {
            require(allowance[from][msg.sender] >= amount);
            allowance[from][msg.sender] -= amount;
        }

        balanceOf[from] -= amount;
        balanceOf[to] += amount;

        emit Transfer(from, to, amount);

        return true;
    }
}
