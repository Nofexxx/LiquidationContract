// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ILiquidationHelper} from "src/interfaces/ILiquidationHelper.sol";
import {Liquidation} from "src/Liquidation.sol";

contract CalculateMostProfitableDebtTest is Test {
	Liquidation public myLiquidation;

	address public lendingPoolAddressProvider =
		0xB53C1a33016B2DC2fF3653530bfF1848a515c8c5;
	address public dataProvider = 0x057835Ad21a177dbdd3090bB1CAE03EaCF78Fc6d;
	address public user = 0x85a04C8618b10BD602e83F80B1d84FE6B0753a5d;

	address public correctDebtAsset =
		0xdAC17F958D2ee523a2206206994597C13D831ec7;
	address public correctCollateralAsset =
		0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
	uint256 public correctDebtToCover = 56499823;

	function setUp() public {
		string memory alchemyKey = vm.envString("ALCHEMY_KEY");
		string memory url = string.concat(
			"https://eth-mainnet.alchemyapi.io/v2/",
			alchemyKey
		);

		vm.createSelectFork(url, 18214402);

		myLiquidation = new Liquidation(
			lendingPoolAddressProvider,
			dataProvider
		);
	}

	function test_revertIf_userZeroAddress() public {
		address invalidUser = address(0);

		vm.expectRevert(ILiquidationHelper.ZeroAddress.selector);
		myLiquidation.calculateMaxProfitableLiquidationData(invalidUser);
	}

	function test_calculateMaxProfitableLiquidationData() public {
		ILiquidationHelper.UserDebtValue memory userDebtValue;

		address debtAssetBefore = userDebtValue.debtAsset;
		address collateralAssetBefore = userDebtValue.collateralAsset;
		uint256 debtToCoverBefore = userDebtValue.debtToCover;

		userDebtValue = myLiquidation.calculateMaxProfitableLiquidationData(
			user
		);

		assert(userDebtValue.debtAsset != debtAssetBefore);
		assert(userDebtValue.collateralAsset != collateralAssetBefore);
		assert(userDebtValue.debtToCover > debtToCoverBefore);

		assertEq(userDebtValue.debtAsset, correctDebtAsset);
		assertEq(userDebtValue.collateralAsset, correctCollateralAsset);
		assertEq(userDebtValue.debtToCover, correctDebtToCover);
	}
}
