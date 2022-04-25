// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.4.22 <0.9.0;

contract Sample {
    string public data;

    constructor() {
            data = "Hello, world!";
    }

    function setValue(string memory _data) public {
        data = _data;
    }

    function getValue() public view returns (string memory) {
        return data;
    }
}