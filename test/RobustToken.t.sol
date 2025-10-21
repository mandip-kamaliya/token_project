// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {RobustToken} from "../src/RobustToken.sol";

// Import the contracts that define the custom errors we want to check for.
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {ERC20Pausable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";
import {ERC20Capped} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";

contract SimpleRobustTokenTest is Test {
    RobustToken public token;
    address public owner;
    address public recipient;

    function setUp() public {
        // Setup initial accounts
        owner = makeAddr("owner");
        recipient = makeAddr("recipient");

        // Deploy the contract as the owner
        vm.prank(owner);
        token = new RobustToken();
    }

    // 1. Test Initial Deployment State
    function test_InitialState() public view {
        assertEq(token.name(), "RobustToken", "Name should be RobustToken");
        assertEq(token.symbol(), "RBT", "Symbol should be RBT");

        uint256 expectedInitialSupply = 100_000_000 * 1e18;
        assertEq(token.balanceOf(owner), expectedInitialSupply, "Owner should have initial supply");
    }

    // 2. Test Basic Token Transfers
    function test_Transfer() public {
        uint256 amount = 1000 * 1e18;

        vm.prank(owner);
        token.transfer(recipient, amount);

        assertEq(token.balanceOf(recipient), amount, "Recipient balance should be the transferred amount");
    }

    // 3. Test Minting Logic and Access Control
    // function test_Minting() public {
    //     uint256 amount = 500 * 1e18;

    //     // The owner (who has MINTER_ROLE) should be able to mint
    //     vm.prank(owner);
    //     token.mint(recipient, amount);
    //     assertEq(token.balanceOf(recipient), amount, "Minting by owner should succeed");

    //     // A random account (recipient) should NOT be able to mint
    //     vm.prank(recipient);
    //     // Expect the modern custom error, referencing it from its original contract (AccessControl).
    //     vm.expectRevert(
    //         abi.encodeWithSelector(
    //             AccessControl.AccessControlUnauthorizedAccount.selector,
    //             recipient,
    //             token.MINTER_ROLE()
    //         )
    //     );
    //     token.mint(recipient, amount);
    // }

    // // 4. Test Pausable Functionality
    // function test_Pausable() public {
    //     // Owner pauses the contract
    //     vm.prank(owner);
    //     token.pause();
    //     assertEq(token.paused(), true, "Contract should be paused");

    //     // Transfers should fail while paused, referencing the error from its original contract (ERC20Pausable).
    //     vm.prank(owner);
    //     vm.expectRevert(ERC20Pausable.EnforcedPause.selector);
    //     token.transfer(recipient, 100);

    //     // Owner unpauses the contract
    //     vm.prank(owner);
    //     token.unpause();
    //     assertEq(token.paused(), false, "Contract should be unpaused");

    //     // Transfers should succeed now
    //     vm.prank(owner);
    //     token.transfer(recipient, 100);
    //     assertEq(token.balanceOf(recipient), 100, "Transfer after unpause should succeed");
    // }

    // 5. Test the Supply Cap
    function test_CappedSupply() public {
        uint256 cap = token.cap();
        uint256 currentSupply = token.totalSupply();
        uint256 remaining = cap - currentSupply;

        // Owner should be able to mint right up to the cap
        vm.prank(owner);
        token.mint(owner, remaining);
        assertEq(token.totalSupply(), cap, "Total supply should now equal the cap");

        // Trying to mint even one more wei should fail, referencing the error from its original contract (ERC20Capped).
        vm.prank(owner);
        vm.expectRevert(
            abi.encodeWithSelector(
                ERC20Capped.ERC20ExceededCap.selector,
                cap + 1, // The attempted total supply
                cap      // The cap
            )
        );
        token.mint(owner, 1);
    }
}

