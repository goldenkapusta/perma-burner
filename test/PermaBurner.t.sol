// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/PermaBurner.sol";

contract TestPermaBurner is Test {
    PermaBurner public permaBurner;

    function setUp() public {
        permaBurner = new PermaBurner();
    }
}
