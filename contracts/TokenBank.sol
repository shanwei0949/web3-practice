// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


interface IERC20{
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
}

contract TokenBank{

    IERC20 public token;

    mapping (address => uint256) public deposits;

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);

    constructor(address _owner){
        require(_owner != address(0), "token address can not be zero");
        token =IERC20(_owner);
    }

    function deposit(uint256 _amount)external {
        require(_amount > 0, "amount must more than 0");

        require(token.balanceOf(msg.sender) >= _amount, "insuficient token balance");

        bool success = token.transferFrom(msg.sender, address(this), _amount);

        require(success, "deposit failed");
        deposits[msg.sender] += _amount;

        emit Deposit(msg.sender, _amount);
    }

    function withdraw(uint256 _amount)external {
        require(_amount > 0, "amount must greater zero");

        require(deposits[msg.sender] >= _amount, "insufficient tokan balance");

        deposits[msg.sender] -= _amount;
        bool success = token.transfer(msg.sender, _amount);
        require(success, "withdraw failed");

        emit Withdraw(msg.sender, _amount);
    }

    function balanceOf(address _user)public view returns(uint256){
        return deposits[_user];
    }


}