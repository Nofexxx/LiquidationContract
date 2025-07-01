// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../src/Liquidation.sol";

contract DeploySwap is Script {
	function run() external {
		uint256 privateKey = vm.envUint("OWNER_PRIVATE_KEY");
		address deployerAddress = vm.addr(privateKey);

		console.log("Deployer Address:", deployerAddress);

		vm.createSelectFork("http://localhost:8545");
		vm.startBroadcast(privateKey);

		Liquidation liquidator = new Liquidation(
			0xB53C1a33016B2DC2fF3653530bfF1848a515c8c5,
			0x057835Ad21a177dbdd3090bB1CAE03EaCF78Fc6d
		);

		console.log("Liquidator deployed at:", address(liquidator));

		vm.stopBroadcast();

		require(
			address(liquidator) != address(0),
			"Deployment liquidator failed"
		);
	}
}
