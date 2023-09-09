pragma solidity 0.8.10;

import "forge-std/Test.sol";
import { IERC20Upgradeable } from "openzeppelin-contracts-upgradeable/contracts/token/ERC20/IERC20Upgradeable.sol";
import { OakVault } from "../src/OakVault.sol";
import "./mock/MockERC20.sol";
import "./utils/Utils.sol";
import { OakVaultProxyDeployer } from "../src/OakVaultProxyDeployer.sol";

contract OakVaultTest is Test {
    OakVault oakVault;
    MockERC20 oakToken;
    MockERC20 usdcToken;
    Utils utils;

    address deployer;
    address payable alice;

    error SwapCooldown();

    function setUp() public {
        deployer = address(this); // The test contract is the deployer
        utils = new Utils();

        // Create test users using the Utils contract
        address payable[] memory users = utils.createUsers(2);
        alice = users[0];

        // Initialize mock tokens with name, symbol, and initial supply
        oakToken = new MockERC20("Mock OAK", "mOAK", 10000 * 10**6);
        usdcToken = new MockERC20("Mock USDC", "mUSDC", 10000 * 10**6);

        assert(address(oakToken) != address(0));
        assert(address(usdcToken) != address(0));

        // Deploy the OakVault implementation contract
        OakVault oakVaultImplementation = new OakVault();
        assert(address(oakVaultImplementation) != address(0));

        // Alice deploys the OakVault contract using the proxy deployer
        vm.startPrank(alice);
        OakVaultProxyDeployer deployerContract = new OakVaultProxyDeployer(address(oakVaultImplementation), address(oakToken), address(usdcToken));
        assert(address(deployerContract) != address(0));

        // Capture the proxy address from the OakVaultDeployed event
        address oakVaultProxyAddress = deployerContract.oakVaultProxy();
        oakVault = OakVault(oakVaultProxyAddress);

        // Ensure that the OakVault contract is correctly initialized
        assertEq(address(oakVault.oakToken()), address(oakToken));
        assertEq(address(oakVault.usdcToken()), address(usdcToken));

        // Ensure that alice is the owner of the OakVault contract
        assertEq(oakVault.owner(), alice);
    }



    function resetAliceBalances() internal {
        oakToken.mint(alice, 1000 * 10**6);
        usdcToken.mint(alice, 1000 * 10**6);

        oakToken.approve(address(oakVault), 1000 * 10**6);
        usdcToken.approve(address(oakVault), 1000 * 10**6);

        oakVault.depositOak(address(oakToken), 100 * 10**6);
        oakVault.depositUSDC(address(usdcToken), 100 * 10**6);
    }

    function test_InitializeOakVault() public {
        assertEq(address(oakVault.oakToken()), address(oakToken));
        assertEq(address(oakVault.usdcToken()), address(usdcToken));
    }

    function test_SwapUSDCForOak() public {
        resetAliceBalances();

        uint256 amount = 5 * 10**6; // 5 USDC

        // Prank as alice
        vm.startPrank(alice);
        oakVault.swapUSDCForOak(amount);

        assertEq(usdcToken.balanceOf(alice), 895 * 10**6);
        assertEq(oakToken.balanceOf(alice), 905 * 10**6);
    }

    function testFail_SwapUSDCAboveLimit() public {
        resetAliceBalances();

        uint256 amount = 101 * 10**6; // 11 USDC, which is above the limit

        // Prank as alice
        vm.startPrank(alice);
        oakVault.swapUSDCForOak(amount);
    }

    function testFail_WithdrawUSDCByNonOwner() public {
        resetAliceBalances();

        uint256 amount = 5 * 10**6; // 5 USDC

        // Prank as deployer (since deployer is not the owner)
        vm.startPrank(deployer);
        oakVault.withdrawUSDC(amount);
    }

    function test_SwapOakForUSDC() public {
        resetAliceBalances();

        uint256 amount = 5 * 10**6; // 5 OAK

        // Ensure Alice has enough OAK tokens and has approved the contract
        oakToken.mint(alice, amount);
        oakToken.approve(address(oakVault), amount);

        // Prank as alice
        vm.startPrank(alice);
        oakVault.swapOakForUSDC(amount);

        assertEq(oakToken.balanceOf(alice), 900 * 10**6);
        assertEq(usdcToken.balanceOf(alice), 904.75 * 10**6);
    }

    function test_WithdrawUSDCByOwner() public {
        resetAliceBalances();

        uint256 amount = 5 * 10**6; // 5 USDC

        // Prank as alice (since she's the owner)
        vm.startPrank(alice);
        oakVault.withdrawUSDC(amount);

        assertEq(usdcToken.balanceOf(alice), 905 * 10**6);
    }

    function test_SwapUSDCForOakCooldown() public {
        resetAliceBalances();
        uint256 amount = 5 * 10**6; // 5 USDC
        uint256 timeSkip = 24 * 60 * 60 + 1; //  24 Hours and 1 second
        console.log("this is a show that console.log works.");

        // Prank as alice
        vm.startPrank(alice);
        oakVault.swapUSDCForOak(amount);
        assertEq(usdcToken.balanceOf(alice), 895 * 10**6);
        assertEq(oakToken.balanceOf(alice), 905 * 10**6);

        // Skip block.timestamp ahead
        vm.warp(timeSkip);

        // Second Swap should Pass.
        oakVault.swapUSDCForOak(amount);
        assertEq(usdcToken.balanceOf(alice), 890 * 10**6);
        assertEq(oakToken.balanceOf(alice), 910 * 10**6);
        
    }

    function test_SwapUSDCForOakDuringCooldownFails() public {
        resetAliceBalances();
        uint256 amount = 5 * 10**6; // 5 USDC
        uint256 cooldown = 24* 60 * 60; //  12 hours

        // Prank as alice
        vm.startPrank(alice);
        oakVault.swapUSDCForOak(amount);
        assertEq(usdcToken.balanceOf(alice), 895 * 10**6);
        assertEq(oakToken.balanceOf(alice), 905 * 10**6);

        for (uint256 i = 0;  i < cooldown; i++) {
            vm.warp(i);
            vm.expectRevert();
            oakVault.swapUSDCForOak(amount);
        }
        
    }

    
    
    
}
