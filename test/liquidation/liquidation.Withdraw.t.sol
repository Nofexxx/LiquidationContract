// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ILiquidationHelper} from "src/interfaces/ILiquidationHelper.sol";
import {Liquidation} from "src/Liquidation.sol";

contract WithdrawTest is Test {
	Liquidation public myLiquidation;

	address public lendingPoolAddressProvider =
		0xB53C1a33016B2DC2fF3653530bfF1848a515c8c5;
	address public dataProvider = 0x057835Ad21a177dbdd3090bB1CAE03EaCF78Fc6d;
	address public debtAsset = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
	address public owner;
	address public userToTransfer;

	uint256 amount = 161794219;

	function setUp() public {
		string memory alchemyKey = vm.envString("ALCHEMY_KEY");
		string memory url = string.concat(
			"https://eth-mainnet.alchemyapi.io/v2/",
			alchemyKey
		);

		uint256 forkId = vm.createFork(url, 18214402);
		vm.selectFork(forkId);

		myLiquidation = new Liquidation(
			lendingPoolAddressProvider,
			dataProvider
		);

		owner = makeAddr("owner");
		userToTransfer = makeAddr("userToTransfer");

		myLiquidation.transferOwnership(owner);

		deal(debtAsset, address(myLiquidation), amount);
	}

	function test_revertIf_debtAssetZeroAddress() public {
		address invalidDebtAsset = address(0);

		vm.prank(owner);
		vm.expectRevert(ILiquidationHelper.ZeroAddress.selector);
		myLiquidation.withdraw(invalidDebtAsset, userToTransfer, amount);
	}

	function test_revertIf_recipientZeroAddress() public {
		address invalidRecipient = address(0);

		vm.prank(owner);
		vm.expectRevert(ILiquidationHelper.ZeroAddress.selector);
		myLiquidation.withdraw(debtAsset, invalidRecipient, amount);
	}

	function test_revertIf_InsufficientBalance() public {
		uint256 invalidAmount = amount * 2;

		vm.prank(owner);
		vm.expectRevert(ILiquidationHelper.InsufficientBalance.selector);
		myLiquidation.withdraw(debtAsset, userToTransfer, invalidAmount);
	}

	function test_withdrawSuccess() public {
		uint256 balanceBefore = IERC20(debtAsset).balanceOf(
			address(myLiquidation)
		);

		vm.prank(owner);
		myLiquidation.withdraw(debtAsset, userToTransfer, amount);

		uint256 balanceAfter = IERC20(debtAsset).balanceOf(
			address(myLiquidation)
		);

		assertLt(balanceAfter, balanceBefore);
	}
}
