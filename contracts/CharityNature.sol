// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface Posup {
    function safeMint(address to, uint _campCounter) external;

    function closeCamp(uint _campCounter) external;
}

contract CharityNature {
    address payable public owner;

    constructor() payable {
        owner = payable(msg.sender);
    }

    uint max_donation_pool = 1000;

    uint total_reached;

    address posupAddress;

    function donate(
        uint _campCounter,
        address _to,
        address _posup
    ) public payable {
        require(max_donation_pool >= total_reached, "maximum donation reached");

        posupAddress = _posup;

        total_reached = total_reached + msg.value;

        return Posup(posupAddress).safeMint(_to, _campCounter);
    }

    function withdraw(uint _campCounter) public {
        require(msg.sender == owner, "Not a contract owner");

        //if withdraw, the campaigning is closed in the Posup contract
        Posup(posupAddress).closeCamp(_campCounter);

        uint amount = address(this).balance;

        (bool success, ) = owner.call{value: amount}("");
        require(success, "Failed to send Ether");
    }
}
