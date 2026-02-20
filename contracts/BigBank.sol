// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBank {
    function deposit()external payable;
    function getTopDepositors()external view returns (address[3] memory, uint[3] memory);
    function withdraw()external ; 
}

contract Bank is IBank{

    address public admin;
    mapping (address => uint256) public deposits;

    address[3] public topDepositors;

    uint8 private constant TOP_COUNT = 3;

    constructor(){
        admin= msg.sender;
    }

    receive()external payable virtual {
        handleDeposit();
    }

    function deposit()external payable virtual {
        handleDeposit();
    }

    function handleDeposit()internal {
        deposits[msg.sender] += msg.value;
        updateTopDepositors(msg.sender);
    }

    function updateTopDepositors(address depositor) internal {
        uint depositorBalance = deposits[depositor];
        for (uint8 i = 0; i < TOP_COUNT; i++) {
            if (topDepositors[i] == depositor) {
                _updateRankings();
                return;
            }
        }
        
        for (uint8 i = 0; i < TOP_COUNT; i++) {
            address currentAddr = topDepositors[i];
            if (currentAddr == address(0) || depositorBalance > deposits[currentAddr]) {
                for (uint8 j = 2; j > i; j--) {
                    topDepositors[j] = topDepositors[j-1];
                }
                topDepositors[i] = depositor;
                break;
            }
        }
    }

    function _updateRankings()internal {
        for (uint8 i = 1; i < TOP_COUNT; i++){
            address key = topDepositors[i];
            if (key == address(0)) continue;

            uint256 keyDeposits = deposits[key];
            uint8 j = i - 1;

            while (j >= 0 && (topDepositors[j] == address(0) || deposits[topDepositors[j]] < keyDeposits)){
                topDepositors[j + 1] = topDepositors[j];
                j--;
            }
            topDepositors[j+1] = key;
        }
    }

    function getTopDepositors()external view returns (address[3] memory, uint[3] memory){
        uint[3] memory amount;
        for (uint8 i=0;i<TOP_COUNT;i++){
            amount[i] = deposits[topDepositors[i]];
        }
        return (topDepositors, amount);
    }

    function withdraw()external {
        require(msg.sender == admin, "only admin can withdraw");

        uint balance = address(this).balance;

        require(balance > 0, "no balance to withdraw");

        (bool success, )=admin.call{value: balance}("");

        require(success, "withdraw failed");
    }

}

contract BigBank is Bank{

    address public immutable owner;

    constructor() {
        owner = msg.sender;
    }

    modifier depositMoreThan001Eth(){
        require(msg.value >= 0.001 ether, "deposit amount must exceed 0.001 ether");
        _;
    }

    function deposit()external payable override depositMoreThan001Eth{
        handleDeposit();
    }

    receive() external payable override { 
        require(msg.value > 0.001 ether, "deposit amount must exceed 0.001 ether");
        handleDeposit();
    }

    function changeAdmin(address newAdmin)external {
        require(msg.sender == admin, "Only admin can change admin");
        require(newAdmin != address(0), "New admin can not be zero address");

        admin =  newAdmin;

    }
}

contract Admin{
    address public immutable admin;

    constructor(){
        admin = msg.sender;
    }

    receive() external payable { }

    function adminWithdraw(IBank bank)public {
        require(msg.sender == admin, "Only admin can withdraw");
        bank.withdraw();
    }
}


