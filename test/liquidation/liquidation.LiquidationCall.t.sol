// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ILiquidationHelper} from "src/interfaces/ILiquidationHelper.sol";
import {Liquidation} from "src/Liquidation.sol";

contract verifyLiquidationCallTest is Test {
	Liquidation public myLiquidation;

	address public lendingPoolAddressProvider =
		0xB53C1a33016B2DC2fF3653530bfF1848a515c8c5;
	address public dataProvider = 0x057835Ad21a177dbdd3090bB1CAE03EaCF78Fc6d;
	address public user = 0x85a04C8618b10BD602e83F80B1d84FE6B0753a5d;

	bool receiveAToken = false;

	function setUp() public {
		string memory alchemyKey = vm.envString("ALCHEMY_KEY");
		string memory url = string.concat(
			"https://eth-mainnet.alchemyapi.io/v2/",
			alchemyKey
		);

		uint256 forkId = vm.createFork(url, 22459399);
		vm.selectFork(forkId);

		myLiquidation = new Liquidation(
			lendingPoolAddressProvider,
			dataProvider
		);
	}

	function test_revertIf_collateralAssetsZeroAddress() public {
		ILiquidationHelper.UserDebtValue memory userDebtValue = myLiquidation
			.calculateMaxProfitableLiquidationData(user);

		userDebtValue.collateralAsset = address(0);

		vm.expectRevert(ILiquidationHelper.ZeroAddress.selector);
		myLiquidation.verifyLiquidationCall(userDebtValue, receiveAToken);
	}

	function test_revertIf_debtAssetZeroAddress() public {
		ILiquidationHelper.UserDebtValue memory userDebtValue = myLiquidation
			.calculateMaxProfitableLiquidationData(user);
		userDebtValue.debtAsset = address(0);

		vm.expectRevert(ILiquidationHelper.ZeroAddress.selector);
		myLiquidation.verifyLiquidationCall(userDebtValue, receiveAToken);
	}

	function test_revertIf_userZeroAddress() public {
		ILiquidationHelper.UserDebtValue memory userDebtValue = myLiquidation
			.calculateMaxProfitableLiquidationData(user);
		userDebtValue.user = address(0);

		vm.expectRevert(ILiquidationHelper.ZeroAddress.selector);
		myLiquidation.verifyLiquidationCall(userDebtValue, receiveAToken);
	}

	function test_revertIf_invalidDebtToCover() public {
		ILiquidationHelper.UserDebtValue memory userDebtValue = myLiquidation
			.calculateMaxProfitableLiquidationData(user);
		userDebtValue.debtToCover = 0;

		vm.expectRevert(ILiquidationHelper.InvalidAmount.selector);
		myLiquidation.verifyLiquidationCall(userDebtValue, receiveAToken);
	}

	function test_revertIf_invalidBalanceToPay() public {
		ILiquidationHelper.UserDebtValue memory userDebtValue = myLiquidation
			.calculateMaxProfitableLiquidationData(user);

		vm.expectRevert(ILiquidationHelper.LiquidationFailed.selector);
		myLiquidation.verifyLiquidationCall(userDebtValue, receiveAToken);
	}

	function test_verifyLiquidationCallSuccessTest() public {
		ILiquidationHelper.UserDebtValue memory userDebtValue = myLiquidation
			.calculateMaxProfitableLiquidationData(user);

		deal(
			userDebtValue.debtAsset,
			address(myLiquidation),
			userDebtValue.debtToCover
		);

		uint256 balanceBefore = IERC20(userDebtValue.collateralAsset).balanceOf(
			address(myLiquidation)
		);

		myLiquidation.verifyLiquidationCall(userDebtValue, receiveAToken);

		uint256 balanceAfter = IERC20(userDebtValue.collateralAsset).balanceOf(
			address(myLiquidation)
		);

		assertGt(balanceAfter, balanceBefore);
	}
}
