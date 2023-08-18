// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/InflationController.sol";
import "./Fixture.t.sol";
import "./utils.sol";

contract TestInflationController is Fixture {
    InflationController public inflationController;

    IERC20 public constant GOLD =
        IERC20(0xbeFD5C25A59ef2C1316c5A4944931171F30Cd3E4);

    function setUp() public override {
        super.setUp();
        // Create a new InflationController with a start timestamp of now and a duration of 1 year
        inflationController = new InflationController(
            uint64(block.timestamp),
            uint64(365 days)
        );
    }

    function testSetBeneficiaryHappy() public {
        inflationController.setBeneficiary(alice);
        assertEq(inflationController.beneficiary(), alice);
    }

    function testSetBeneficiaryFail() public {
        vm.startPrank(alice);
        vm.expectRevert("Ownable: caller is not the owner");
        inflationController.setBeneficiary(alice);
        vm.stopPrank();

        // Try to set the beneficiary to address(0)
        vm.expectRevert("InflationController: zero address");
        inflationController.setBeneficiary(address(0));
    }

    /// @dev Happy case when owner wants to sweep all timelocked tokens
    function testSweepTimelockHappy() public {
        uint256 arbitraryAmount = 1000e18;
        // Make sure timelock is 0 now
        assertEq(inflationController.timelockEnd(), 0);
        // Make alice owner of the contract
        inflationController.transferOwnership(alice);

        // Generate some ERC20 tokens to sweep
        setStorage(
            address(inflationController),
            GOLD.balanceOf.selector,
            address(GOLD),
            arbitraryAmount
        );

        setStorage(
            address(inflationController),
            BPT.balanceOf.selector,
            address(BPT),
            arbitraryAmount
        );

        address[] memory tokens = new address[](2);
        tokens[0] = address(GOLD);
        tokens[1] = address(BPT);
        // Now alice wants to sweep the ERC20 tokens
        vm.prank(alice);
        inflationController.sweepTimelock(tokens, alice);

        // Make sure timelock is set to 14 days from now
        assertEq(
            inflationController.timelockEnd(),
            block.timestamp + inflationController.SWEEP_TIMELOCK_DURATION()
        );

        // Warp 14 days into the future
        vm.warp(
            block.timestamp + inflationController.SWEEP_TIMELOCK_DURATION()
        );

        // Now alice wants to sweep the ERC20 tokens
        vm.prank(alice);
        inflationController.sweepTimelock(tokens, alice);

        // Make sure alice now has the ERC20 tokens
        assertEq(GOLD.balanceOf(alice), arbitraryAmount);
        assertEq(BPT.balanceOf(alice), arbitraryAmount);
        // Make sure timelock is set to 0
        assertEq(inflationController.timelockEnd(), 0);
    }

    /// @dev Case when owner tries to sweep timelocked tokens before timelock is over
    function testSweepTimelockTooEarly() public {
        uint256 arbitraryAmount = 1000e18;
        // Make sure timelock is 0 now
        assertEq(inflationController.timelockEnd(), 0);
        // Make alice owner of the contract
        inflationController.transferOwnership(alice);

        // Generate some ERC20 tokens to sweep
        setStorage(
            address(inflationController),
            GOLD.balanceOf.selector,
            address(GOLD),
            arbitraryAmount
        );

        setStorage(
            address(inflationController),
            BPT.balanceOf.selector,
            address(BPT),
            arbitraryAmount
        );

        address[] memory tokens = new address[](2);
        tokens[0] = address(GOLD);
        tokens[1] = address(BPT);
        // Now alice wants to sweep the ERC20 tokens
        vm.prank(alice);
        inflationController.sweepTimelock(tokens, alice);

        // Make sure timelock is set to 14 days from now
        assertEq(
            inflationController.timelockEnd(),
            block.timestamp + inflationController.SWEEP_TIMELOCK_DURATION()
        );

        // Warp 13 days into the future
        vm.warp(
            block.timestamp +
                inflationController.SWEEP_TIMELOCK_DURATION() -
                1 days
        );

        // Now alice wants to sweep the ERC20 tokens
        vm.prank(alice);
        vm.expectRevert("InflationController: timelock not over");
        inflationController.sweepTimelock(tokens, alice);

        // Make sure alice has no ERC20 tokens
        assertEq(GOLD.balanceOf(alice), 0);
        assertEq(BPT.balanceOf(alice), 0);
        // Make sure timelock is not 0
        assertNotEq(inflationController.timelockEnd(), 0);
    }
}
