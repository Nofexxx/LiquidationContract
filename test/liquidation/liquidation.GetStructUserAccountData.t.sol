// // SPDX-License-Identifier: MIT
// pragma solidity ^0.8.27;

// import "forge-std/Test.sol";
// import {console} from "forge-std/console.sol";
// import {Liquidation} from "src/Liquidation.sol";
// import {ILiquidationHelper} from "src/interfaces/ILiquidationHelper.sol";

// contract GetStructUserAccountData is Test {
// 	Liquidation public myLiquidation;

// 	address public lendingPoolAddressProvider =
// 		0xB53C1a33016B2DC2fF3653530bfF1848a515c8c5;
// 	address public dataProvider = 0x057835Ad21a177dbdd3090bB1CAE03EaCF78Fc6d;
// 	address public user = 0xE7f945B037424284FCAC3D51dcAa5b970696bdb0;

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

// 	function test_revertIf_userZeroAddress() public {
// 		address invalidUserAddress = address(0);

// 		vm.expectRevert(ILiquidationHelper.ZeroAddress.selector);
// 		myLiquidation.getStructUserAccountData(invalidUserAddress);
// 	}

// 	function test_getStructUserAccountDataSuccess() public {
// 		ILiquidationHelper.UserAccountData memory data = myLiquidation
// 			.getStructUserAccountData(user);

// 		assertLe(data.healthFactor, 1e18);
// 	}
// }
