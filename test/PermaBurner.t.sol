// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/PermaBurner.sol";
import "./Fixture.t.sol";
import "./utils.sol";

contract TestPermaBurner is Fixture {
    PermaBurner public permaBurner;

    Utils internal utils;

    address payable[] internal users;
    address internal alice;
    address internal bob;

    IBpt public constant BPT = IBpt(0xE40cBcCba664C7B1a953827C062F5070B78de868);

    function setUp() public {
        utils = new Utils();
        users = utils.createUsers(2);
        alice = users[0];
        bob = users[1];

        permaBurner = new PermaBurner();
        // Alice and Bob approve PermaBurner to spend their tokens
        vm.prank(alice);
        BPT.approve(address(permaBurner), type(uint256).max);
        vm.prank(bob);
        BPT.approve(address(permaBurner), type(uint256).max);
        // Give Alice and Bob some BPT
        setStorage(
            alice,
            BPT.balanceOf.selector,
            address(BPT),
            type(uint256).max
        );
        setStorage(
            bob,
            BPT.balanceOf.selector,
            address(BPT),
            type(uint256).max
        );
    }

    /// @notice Happy test case for burning tokens
    function testHappyBurn(uint256 burnAmount) public {
        vm.assume(burnAmount > 0 && burnAmount < 100_000_000e18);
        uint256 balanceSnapshot = BPT.balanceOf(address(alice));

        vm.prank(alice);
        permaBurner.deposit(burnAmount);

        // Make sure BPT balance decreased for alice by burnAmount
        assertEq(BPT.balanceOf(alice), balanceSnapshot - burnAmount);

        // Check that alice has a claim
        (uint256 claimable, uint256 timestamp) = permaBurner.claimDetails(
            alice
        );

        // Make sure claimable is not 0 and timestamp is correct
        assertGt(claimable, 0);
        assertEq(timestamp, block.timestamp + permaBurner.CLAIM_DELAY());
    }
}
