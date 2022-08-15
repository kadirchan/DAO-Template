// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

error notOwner();
error run_renounceOwnership_instead();

contract Ownable {
    address public owner;

    constructor() {}

    modifier onlyOwner() {
        checkOwner();
        _;
    }

    function checkOwner() internal view {
        if (owner != msg.sender) {
            revert notOwner();
        }
    }

    function renounceOwnership() public onlyOwner {
        owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        if (newOwner == address(0)) {
            revert run_renounceOwnership_instead();
        }
        owner = newOwner;
    }
}
