// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

interface ILiquidationHelper {
	//events
	event LiquidationCall(
		address indexed collateralAssets,
		address indexed debtAsset,
		address indexed user,
		uint256 debtToCover,
		bool receiveAToken
	);
	event Withdraw(address indexed token, address indexed to, uint256 amount);
	event Deposit(address indexed user, address indexed token, uint256 amount);

	//errors
	error ZeroAddress();
	error InvalidAmount();
	error InsufficientBalance();
	error LiquidationFailed();
	error FailedToDeposit();
	error NotValidHealthFactor();

	//struct
	struct UserAccountData {
		uint256 totalCollateralETH;
		uint256 totalDebtETH;
		uint256 availableBorrowsETH;
		uint256 currentLiquidationThreshold;
		uint256 ltv;
		uint256 healthFactor;
	}

	struct ProtocolReserveData {
		uint256 currentATokenBalance;
		uint256 currentStableDebt;
		uint256 currentVariableDebt;
		uint256 principalStableDebt;
		uint256 scaledVariableDebt;
		uint256 stableBorrowRate;
		uint256 liquidityRate;
		uint40 stableRateLastUpdated;
		bool usageAsCollateralEnabled;
	}

	struct UserDebt {
		address user;
		address debtAsset;
		address collateralAsset;
		uint256 debtToCover;
	}

	struct ProtocolReserveConfigurationData {
		uint256 decimals;
		uint256 ltv;
		uint256 liquidationThreshold;
		uint256 liquidationBonus;
		uint256 reserveFactor;
		bool usageAsCollateralEnabled;
		bool borrowingEnabled;
		bool stableBorrowRateEnabled;
		bool isActive;
		bool isFrozen;
	}

	//functions
	function liquidationCall(
		UserDebt memory userDataToLiquidate,
		bool receiveAToken
	) external returns (bool success);

	function withdraw(address token, address to, uint256 amount) external;

	function calculateMaxProfitableLiquidationData(
		address user
	) external view returns (ILiquidationHelper.UserDebt memory UserDebt);
}
