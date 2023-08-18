// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/InflationController.sol";
import "./Fixture.t.sol";
import "./utils.sol";

contract TestInflationController is Fixture {
    InflationController public inflationController;

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
}
