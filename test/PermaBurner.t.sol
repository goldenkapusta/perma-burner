// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/PermaBurner.sol";
import "./Fixture.t.sol";

contract TestPermaBurner is Fixture {
    PermaBurner public permaBurner;

    function setUp() public override {
        super.setUp();
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
