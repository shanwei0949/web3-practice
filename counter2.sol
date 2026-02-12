//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract counter2{

    uint public count;

    constructor(uint _count){
        count = _count;
    }

    function get() public view  returns (uint){
        return count;
    }

    function set(uint _x) public {
        count = _x;
    }

}