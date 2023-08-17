// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

contract Fixture is Test {
    using stdStorage for StdStorage;

    function setStorage(
        address _user,
        bytes4 _selector,
        address _contract,
        uint256 value
    ) public {
        uint256 slot = stdstore
            .target(_contract)
            .sig(_selector)
            .with_key(_user)
            .find();
        vm.store(_contract, bytes32(slot), bytes32(value));
    }
}
