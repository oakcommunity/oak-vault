pragma solidity 0.8.10;

import "forge-std/Test.sol";
import { IERC20Upgradeable } from "openzeppelin-contracts-upgradeable/contracts/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import { OakVault } from "../src/OakVault.sol";


interface IUSDC {
    function masterMinter() external view returns (address);
    function configureMinter(address minter, uint256 minterAllowedAmount) external;
    function mint(address account, uint256 amount) external;
}

contract OakVaultTest is Test {
    OakVault oakVault;
    IERC20Upgradeable oakToken;
    IERC20Upgradeable usdcToken;

    address deployer;
    address user1;
    address user2;

    function setUp() public {
        deployer = address(this); // The test contract is the deployer
        user1 = address(0x123); // Replace with actual test address
        user2 = address(0x456); // Replace with actual test address

        oakToken = IERC20Upgradeable(address(0xabc)); // Mock or actual token address
        usdcToken = IERC20Upgradeable(address(0xdef)); // Mock or actual token address

        // Prank as user1 to deploy the contract
        vm.startPrank(user1);
        oakVault = new OakVault();
        oakVault.initialize(address(oakToken), address(usdcToken));

        // Mint USDC and OAK tokens to user1
        IUSDC(address(usdcToken)).mint(user1, 10000e18);
        IUSDC(address(oakToken)).mint(user1, 10000e18); // Assuming OAK token has a similar mint function

        // User1 approves the OakVault contract to spend tokens
        oakToken.approve(address(oakVault), 10000e18);
        usdcToken.approve(address(oakVault), 10000e18);
//
//        // User1 deposits USDC and OAK tokens into the contract
//        oakVault.depositUSDC(user1, 10000e18);
        oakVault.depositOak(user1, 10000e18);
    }

    function test_InitializeOakVault() public {
        assertEq(address(oakVault.oakToken()), address(oakToken));
        assertEq(address(oakVault.usdcToken()), address(usdcToken));
    }

    function test_SwapUSDCForOak() public {
        uint256 amount = 5 * 10**6; // 5 USDC

        // Deal USDC to user1
        deal(address(usdcToken), user1, amount);

        // Prank as user1
        vm.startPrank(user1);

        oakVault.swapUSDCForOak(amount);

        // Check the balances and lastSwapTime
        assertEq(usdcToken.balanceOf(address(oakVault)), amount);
        assertEq(oakToken.balanceOf(user1), amount);
        assertEq(oakVault.lastSwapTime(user1), block.timestamp);
    }

    function testFail_SwapUSDCAboveLimit() public {
        uint256 amount = 11 * 10**6; // 11 USDC, which is above the limit

        // Deal USDC to user1
        deal(address(usdcToken), user1, amount);

        // Prank as user1
        vm.startPrank(user1);

        oakVault.swapUSDCForOak(amount);
    }

    function test_SwapOakForUSDC() public {
        uint256 amount = 5 * 10**6; // 5 OAK
        uint256 surcharge = (amount * 5) / 100; // 5% surcharge
        uint256 netAmount = amount - surcharge;

        // Deal OAK to user2
        deal(address(oakToken), user2, amount);

        // Prank as user2
        vm.startPrank(user2);

        oakVault.swapOakForUSDC(amount);

        // Check the balances
        assertEq(oakToken.balanceOf(address(oakVault)), amount);
        assertEq(usdcToken.balanceOf(user2), netAmount);
    }

    function test_WithdrawUSDCByOwner() public {
        uint256 amount = 5 * 10**6; // 5 USDC

        // Deal USDC to the contract
        deal(address(usdcToken), address(oakVault), amount);

        // Prank as deployer
        vm.startPrank(deployer);

        oakVault.withdrawUSDC(amount);

        // Check the balance
        assertEq(usdcToken.balanceOf(deployer), amount);
    }

    function testFail_WithdrawUSDCByNonOwner() public {
        uint256 amount = 5 * 10**6; // 5 USDC

        // Deal USDC to the contract
        deal(address(usdcToken), address(oakVault), amount);

        // Prank as user1
        vm.startPrank(user1);

        oakVault.withdrawUSDC(amount);
    }
}
