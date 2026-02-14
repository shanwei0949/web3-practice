// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


interface IERC20{
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function transferWithCallBack(address recipient, uint256 amount) external returns (bool);
}

interface ITokenReceiver {
    function tokensReceived(address from, uint256 amount) external returns(bool);
}

contract ExtendedERC20 {
    string public name; 
    string public symbol; 
    uint8 public decimals; 

    uint256 public totalSupply; 

    mapping (address => uint256) balances; 

    mapping (address => mapping (address => uint256)) allowances; 

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor() {
        name = "ExtendedERC20";
        symbol = "EERC20";
        decimals = 18;
        totalSupply = 100000000 * 10**uint256(decimals); // 100,000,000 tokens
        
        balances[msg.sender] = totalSupply;  
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balances[msg.sender] >= _value, "ERC20: transfer amount exceeds balance");
        require(_to != address(0), "ERC20: transfer to the zero address");
        
        balances[msg.sender] -= _value;
        balances[_to] += _value;

        emit Transfer(msg.sender, _to, _value);  
        return true;   
    }
    

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(balances[_from] >= _value, "ERC20: transfer amount exceeds balance");
        require(allowances[_from][msg.sender] >= _value, "ERC20: transfer amount exceeds allowance");
        require(_to != address(0), "ERC20: transfer to the zero address");
        
        balances[_from] -= _value;
        balances[_to] += _value;
        allowances[_from][msg.sender] -= _value;
        
        emit Transfer(_from, _to, _value); 
        return true; 
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        require(_spender != address(0), "ERC20: approve to the zero address");
        
        allowances[msg.sender][_spender] = _value;

        emit Approval(msg.sender, _spender, _value); 
        return true; 
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {   
        return allowances[_owner][_spender];
    }

    function transferWithCallBack(address to, uint256 amount)public returns (bool success){
        require(balanceOf(msg.sender) >= amount, "transfer amount exceed balance");
        require(to!=address(0), "can not transfer to zero address");

        balances[(msg.sender)] -= amount;
        balances[to] += amount;

        emit Transfer(msg.sender, to, amount);

        if(isContract(to)){
            try ITokenReceiver(to).tokensReceived(msg.sender, amount) returns (bool){

            }catch {

            }
        }

        return true;
    }

    function isContract(address _addr)private view returns (bool){
        uint32 size;
        assembly{
            size := extcodesize(_addr)
        }
        return size > 0;
    }
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

        bool success = token.transferWithCallBack(address(this), _amount);

        require(success, "deposit failed");
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

contract TokenBankV2 is TokenBank, ITokenReceiver {

    ExtendedERC20 public extendedERC20;

    constructor(address _tokenAddress) TokenBank(_tokenAddress){
        extendedERC20=ExtendedERC20(_tokenAddress);
    }

    function tokensReceived(address from, uint256 amount) external override  returns(bool){
        require(msg.sender == address(token), "caller is not tokan addresss");

        deposits[from] += amount;

        emit Deposit(from, amount);

        return true;
    }
    
}