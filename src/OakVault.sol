// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract OakVault is Initializable, PausableUpgradeable, OwnableUpgradeable {
    IERC20Upgradeable public oakToken;
    IERC20Upgradeable public usdcToken;
    mapping(address => uint256) public lastSwapTime;

    uint256 public constant SWAP_LIMIT = 10 * 10**6; // 10 USDC
    uint256 public constant TIME_LIMIT = 1 days;

    // Constructor logic will go here

    // Modifiers will go here

    // Functions will go here
}
