// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

interface ILendingPool {
	//functions
	function liquidationCall(
		address collateralAssets,
		address debtAsset,
		address user,
		uint256 debtToCover,
		bool receiveAToken
	) external;

	function getUserAccountData(
		address user
	)
		external
		view
		returns (
			uint256 totalCollateralETH,
			uint256 totalDebtETH,
			uint256 availableBorrowsETH,
			uint256 currentLiquidationThreshold,
			uint256 ltv,
			uint256 healthFactor
		);

	function getLendingPool()
		external
		view
		returns (address lendingPoolAddress);

	function getPriceOracle() external view returns (address);

	function getReservesList() external view returns (address[] memory);
}
