// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { IERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import { PausableUpgradeable } from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { ReentrancyGuardUpgradeable } from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import { SafeERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

/**
 * @title OakVault Contract
 * @author taayyohh
 * @notice A contract to manage swaps between USDC and $OAK tokens.
 */
contract OakVault is Initializable, PausableUpgradeable, OwnableUpgradeable, ReentrancyGuardUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    // State variables
    IERC20Upgradeable public oakToken;
    IERC20Upgradeable public usdcToken;
    mapping(address => uint256) public lastSwapTime;

    // Constants
    uint256 public constant SWAP_LIMIT = 10 * 10**6; // 10 USDC
    uint256 public constant TIME_LIMIT = 1 days;

    // Custom errors
    error InsufficientTokenBalance();
    error InsufficientUSDCBalance();
    error ExceedsSwapLimit();
    error SwapCooldown();
    error InvalidUSDCAddress();
    error InvalidOakAddress();

    // Events
    event SwappedUSDCForOak(address indexed user, uint256 amount);
    event SwappedOakForUSDC(address indexed user, uint256 amount, uint256 surcharge);
    event USDCWithdrawn(address indexed owner, uint256 amount);
    event USDCDeposited(address indexed owner, uint256 amount);
    event OakDeposited(address indexed owner, uint256 amount);


    /**
     * @notice Initializes the contract with the addresses of $OAK and USDC tokens.
     * @param _oakToken The address of the $OAK token.
     * @param _usdcToken The address of the USDC token.
     */
    function initialize(address _oakToken, address _usdcToken) public initializer {
        __Pausable_init();
        __Ownable_init();

        oakToken = IERC20Upgradeable(_oakToken);
        usdcToken = IERC20Upgradeable(_usdcToken);
    }


    /**
     * @notice Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     * @dev Overrides the transferOwnership function from OwnableUpgradeable for custom logic.
     * @param newOwner Address of the new owner. Must not be the zero address.
     */
    function transferOwnership(address newOwner) public override onlyOwner {
        require(newOwner != address(0), "New owner is the zero address");
        super.transferOwnership(newOwner);
    }



    /**
     * @notice Modifier to check if a user can perform a swap.
     * @param user The address of the user.
     * @param amount The amount of tokens to swap.
     */
    modifier canSwap(address user, uint256 amount) {
        if (amount > SWAP_LIMIT) revert ExceedsSwapLimit();
        if (lastSwapTime[user] != 0 && block.timestamp - lastSwapTime[user] < TIME_LIMIT) revert SwapCooldown();
        _;
    }

    /**
     * @notice Allows a user to swap USDC for $OAK.
     * @param amount The amount of USDC to swap.
     */
    function swapUSDCForOak(uint256 amount) external canSwap(msg.sender, amount) whenNotPaused nonReentrant {
        if (oakToken.balanceOf(address(this)) < amount) revert InsufficientTokenBalance();

        // Transfer USDC from user to contract
        usdcToken.safeTransferFrom(msg.sender, address(this), amount);

        // Transfer equivalent $OAK to user
        oakToken.safeTransfer(msg.sender, amount);

        // Update last swap time
        lastSwapTime[msg.sender] = block.timestamp;

        emit SwappedUSDCForOak(msg.sender, amount);
    }

    /**
     * @notice Allows a user to swap $OAK for USDC with a surcharge.
     * @param amount The amount of $OAK to swap.
     */
    function swapOakForUSDC(uint256 amount) external whenNotPaused nonReentrant {
        uint256 surcharge = (amount * 5) / 100; // 5% surcharge
        uint256 netAmount = amount - surcharge;

        if (usdcToken.balanceOf(address(this)) < netAmount) revert InsufficientUSDCBalance();

        // Transfer $OAK from user to contract
        oakToken.safeTransferFrom(msg.sender, address(this), amount);

        // Transfer USDC after deducting surcharge to user
        usdcToken.safeTransfer(msg.sender, netAmount);

        emit SwappedOakForUSDC(msg.sender, amount, surcharge);
    }

    /**
     * @notice Allows the owner to withdraw USDC from the contract.
     * @param amount The amount of USDC to withdraw.
     */
    function withdrawUSDC(uint256 amount) external onlyOwner {
        if (usdcToken.balanceOf(address(this)) < amount) revert InsufficientUSDCBalance();

        usdcToken.transfer(msg.sender, amount);

        emit USDCWithdrawn(msg.sender, amount);
    }

    /**
   * @notice Allows the owner to deposit USDC into the contract.
     * @param tokenAddress The address of the USDC token being deposited.
     * @param amount The amount of USDC to deposit.
     */
    function depositUSDC(address tokenAddress, uint256 amount) external onlyOwner {
        if (tokenAddress != address(usdcToken)) revert InvalidUSDCAddress();

        // Transfer USDC from owner to contract
        usdcToken.safeTransferFrom(msg.sender, address(this), amount);
        emit USDCDeposited(msg.sender, amount);
    }

    /**
     * @notice Allows the owner to deposit $OAK tokens into the contract.
     * @param tokenAddress The address of the $OAK token being deposited.
     * @param amount The amount of $OAK tokens to deposit.
     */
    function depositOak(address tokenAddress, uint256 amount) external onlyOwner {
        if (tokenAddress != address(oakToken)) revert InvalidOakAddress();

        // Transfer $OAK tokens from owner to contract
        oakToken.safeTransferFrom(msg.sender, address(this), amount);
        emit OakDeposited(msg.sender, amount);
    }
}
