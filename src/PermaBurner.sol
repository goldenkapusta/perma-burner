// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {IERC20} from "./interfaces/IERC20.sol";
import {IBpt} from "./interfaces/IBpt.sol";
import {IBalancerVault} from "./interfaces/IBalancerVault.sol";

contract PermaBurner {
    IERC20 public constant GOLD = IERC20(0xbeFD5C25A59ef2C1316c5A4944931171F30Cd3E4);

    uint256 public constant BPT_MULTIPLIER = 2;
    uint256 public constant BASE = 10_000;
    uint256 public constant PREMIUM = 10_300;

    IBalancerVault public constant BALANCER_VAULT = IBalancerVault(0xBA12222222228d8Ba445958a75a0704d566BF2C8);
    IBpt public constant BPT = IBpt(0xE40cBcCba664C7B1a953827C062F5070B78de868);
    bytes32 public constant GOLD_WETH_POOL_ID = 0xe40cbccba664c7b1a953827c062f5070b78de86800020000000000000000001b;

    // TBD
    address public constant BURN_DESTINATION = 0xbeFD5C25A59ef2C1316c5A4944931171F30Cd3E4;

    error ZeroBpt();
    error NotEOA(address caller);

    event Deposit(address depositor, uint256 bptAmount, uint256 goldRewarded, uint256 timestamp);

    /// @notice Deposits BPT and burns GOLD
    /// @param _amount Amount of BPT to deposit
    function deposit(uint256 _amount) external {
        if (msg.sender.code.length > 0) revert NotEOA(msg.sender);
        if (_amount == 0) revert ZeroBpt();

        // take bpt from depositor assuming has enough balance
        BPT.transferFrom(msg.sender, address(this), _amount);

        uint256 goldReward = _getGoldRewardOut(_amount);

        // rewards to depositor
        GOLD.transfer(msg.sender, goldReward);

        // burn gold
        GOLD.transfer(BURN_DESTINATION, goldReward);

        emit Deposit(msg.sender, _amount, goldReward, block.timestamp);
    }

    /// @notice Calculates the amount of GOLD to reward for a given BPT amount
    /// @param _bptAmount Amount of BPT to calculate reward for
    function _getGoldRewardOut(uint256 _bptAmount) internal view returns (uint256) {
        uint256 bptTs = BPT.totalSupply();
        (IERC20[] memory tokens, uint256[] memory balances,) = BALANCER_VAULT.getPoolTokens(GOLD_WETH_POOL_ID);

        uint256 goldAmountInPool;
        for (uint256 i; i < tokens.length;) {
            if (tokens[i] == GOLD) {
                goldAmountInPool = balances[i];
                break;
            }
            unchecked {
                ++i;
            }
        }

        uint256 goldInBpt = (_bptAmount * goldAmountInPool) / bptTs;

        // assume a 50:50 bpt pool
        uint256 totalInBpt = goldInBpt * BPT_MULTIPLIER;

        uint256 goldOut = (totalInBpt * PREMIUM) / BASE;

        return goldOut;
    }
}
