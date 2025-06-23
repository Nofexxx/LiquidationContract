// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ILiquidationHelper} from "src/interfaces/ILiquidationHelper.sol";
import {Liquidation} from "src/Liquidation.sol";

contract DepositTest is Test {
	Liquidation public myLiquidation;

	address public lendingPoolAddressProvider =
		0xB53C1a33016B2DC2fF3653530bfF1848a515c8c5;
	address public dataProvider = 0x057835Ad21a177dbdd3090bB1CAE03EaCF78Fc6d;
	address public token = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48; // USDC
	address public user;

	uint256 public amount = 1000000000000000000;

	function setUp() public {
		string memory alchemyKey = vm.envString("ALCHEMY_KEY");
		string memory url = string.concat(
			"https://eth-mainnet.alchemyapi.io/v2/",
			alchemyKey
		);

		vm.createSelectFork(url);

		myLiquidation = new Liquidation(
			lendingPoolAddressProvider,
			dataProvider
		);

		user = makeAddr("user");
		deal(token, user, amount);
		deal(user, amount);
	}

	function test_RevertIf_tokenZeroAddress() public {
		address invalidToken = address(0);

		vm.expectRevert(ILiquidationHelper.ZeroAddress.selector);
		myLiquidation.deposit(invalidToken, amount);
	}

	function test_RevertIf_amountZero() public {
		uint256 invalidAmount = 0;

		vm.expectRevert(ILiquidationHelper.InvalidAmount.selector);
		myLiquidation.deposit(token, invalidAmount);
	}

	function test_depositSuccess() public {
		uint256 balanceTokensBefore = IERC20(token).balanceOf(
			address(myLiquidation)
		);

		vm.startPrank(user);

		IERC20(token).approve(address(myLiquidation), amount);
		myLiquidation.deposit(token, amount);

		vm.stopPrank();

		uint256 balanceTokensAfter = IERC20(token).balanceOf(
			address(myLiquidation)
		);

		assertGt(balanceTokensAfter, balanceTokensBefore);
	}
}
