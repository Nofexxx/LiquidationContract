// // SPDX-License-Identifier: MIT
// pragma solidity ^0.8.27;

// import "forge-std/Test.sol";
// import {console} from "forge-std/console.sol";
// import {ILiquidationHelper} from "src/interfaces/ILiquidationHelper.sol";
// import {Liquidation} from "src/Liquidation.sol";

// contract GetStructUserAccountData is Test {
// 	Liquidation public myLiquidation;

// 	address public lendingPoolAddressProvider =
// 		0xB53C1a33016B2DC2fF3653530bfF1848a515c8c5;
// 	address public dataProvider = 0x057835Ad21a177dbdd3090bB1CAE03EaCF78Fc6d;
// 	address public user = 0xE7f945B037424284FCAC3D51dcAa5b970696bdb0;
// 	address public debtAsset = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

// 	uint256 userCurrentVariableDebt = 161794219;
// 	uint256 userCurrentStableDebt = 0;

// 	function setUp() public {
// 		string memory alchemyKey = vm.envString("ALCHEMY_KEY");
// 		string memory url = string.concat(
// 			"https://eth-mainnet.alchemyapi.io/v2/",
// 			alchemyKey
// 		);

// 		uint256 forkId = vm.createFork(url, 18214402);
// 		vm.selectFork(forkId);

// 		myLiquidation = new Liquidation(
// 			lendingPoolAddressProvider,
// 			dataProvider
// 		);
// 	}

// 	function test_getStructUserReserveDataSuccess() public {
// 		ILiquidationHelper.ProtocolReserveData memory data = myLiquidation
// 			.getStructUserReserveData(debtAsset, user);

// 		assertEq(data.currentStableDebt, userCurrentStableDebt);
// 		assertEq(data.currentVariableDebt, userCurrentVariableDebt);
// 	}

// 	function test_revertIf_userZeroAddress() public {
// 		address invalidUserAddress = address(0);

// 		vm.expectRevert(ILiquidationHelper.ZeroAddress.selector);
// 		myLiquidation.getStructUserReserveData(debtAsset, invalidUserAddress);
// 	}

// 	function test_revertIf_assetZeroAddress() public {
// 		address invalidAssetAddress = address(0);

// 		vm.expectRevert(ILiquidationHelper.ZeroAddress.selector);
// 		myLiquidation.getStructUserReserveData(invalidAssetAddress, user);
// 	}
// }
