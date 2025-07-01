// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

/* ====== EXTERNAL IMPORTS ====== */
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "forge-std/console.sol";

/* ====== INTERFACES IMPORTS ====== */
import {ILiquidationHelper} from "./interfaces/ILiquidationHelper.sol";
import {IProtocolDataProvider} from "./interfaces/IProtocolDataProvider.sol";
import {ILendingPool} from "./interfaces/ILendingPool.sol";
import {IPriceOracle} from "./interfaces/IPriceOracle.sol";

contract Liquidation is ILiquidationHelper, Ownable {
	using SafeERC20 for IERC20;

	/* ======== STATE ======== */
	ILendingPool public immutable lendingPool;
	IProtocolDataProvider public immutable dataProvider;
	IPriceOracle public immutable priceOracle;

	/* ======== CONSTRUCTOR AND INIT ======== */
	constructor(
		address _lendingPoolAddressProvider,
		address _dataProvider
	) Ownable(msg.sender) {
		if (
			_lendingPoolAddressProvider == address(0) ||
			_dataProvider == address(0)
		) revert ZeroAddress();

		address lendingPoolAddress = ILendingPool(_lendingPoolAddressProvider)
			.getLendingPool();
		lendingPool = ILendingPool(lendingPoolAddress);

		address priceOracleAddress = ILendingPool(_lendingPoolAddressProvider)
			.getPriceOracle();
		priceOracle = IPriceOracle(priceOracleAddress);

		dataProvider = IProtocolDataProvider(_dataProvider);
	}

	/* ======== EXTERNAL/PUBLIC ======== */
	function liquidationCall(
		ILiquidationHelper.UserDebt memory userDataToLiquidate,
		bool receiveAToken
	) external returns (bool success) {
		if (userDataToLiquidate.collateralAsset == address(0))
			revert ZeroAddress();
		if (userDataToLiquidate.debtAsset == address(0)) revert ZeroAddress();
		if (userDataToLiquidate.user == address(0)) revert ZeroAddress();

		if (userDataToLiquidate.debtToCover == 0) revert InvalidAmount();

		if (
			IERC20(userDataToLiquidate.debtAsset).balanceOf(address(this)) <=
			userDataToLiquidate.debtToCover / 2
		) revert LiquidationFailed();

		success = false;

		if (
			IERC20(userDataToLiquidate.debtAsset).allowance(
				address(this),
				address(lendingPool)
			) < userDataToLiquidate.debtToCover
		) {
			IERC20(userDataToLiquidate.debtAsset).forceApprove(
				address(lendingPool),
				type(uint256).max
			);
		}

		if (_validateUser(userDataToLiquidate.user)) {
			lendingPool.liquidationCall(
				userDataToLiquidate.collateralAsset,
				userDataToLiquidate.debtAsset,
				userDataToLiquidate.user,
				userDataToLiquidate.debtToCover,
				receiveAToken
			);
			success = true;
		}

		emit LiquidationCall(
			userDataToLiquidate.collateralAsset,
			userDataToLiquidate.debtAsset,
			userDataToLiquidate.user,
			userDataToLiquidate.debtToCover,
			receiveAToken
		);

		return success;
	}

	/* ======== ADMIN ======== */
	function withdraw(
		address asset,
		address to,
		uint256 amount
	) external onlyOwner {
		if (to == address(0) || asset == address(0)) revert ZeroAddress();
		if (amount == 0) revert InvalidAmount();
		if (IERC20(asset).balanceOf(address(this)) < amount)
			revert InsufficientBalance();

		IERC20(asset).safeTransfer(to, amount);

		emit Withdraw(asset, to, amount);
	}

	function deposit(address asset, uint256 amount) external {
		if (asset == address(0)) revert ZeroAddress();
		if (amount == 0) revert InvalidAmount();

		IERC20(asset).safeTransferFrom(msg.sender, address(this), amount);

		emit Deposit(msg.sender, asset, amount);
	}

	/* ======== VIEW ======== */
	function calculateMaxProfitableLiquidationData(
		address user
	) external view returns (ILiquidationHelper.UserDebt memory userDebt) {
		if (user == address(0)) revert ZeroAddress();

		uint256 maxDebt = 0;
		uint256 maxCollateralValue = 0;
		address debtAsset = address(0);
		address collateralAsset = address(0);

		address[] memory reserveList = lendingPool.getReservesList();

		for (uint256 i = 0; i < reserveList.length; i++) {
			address asset = reserveList[i];

			uint256 price = priceOracle.getAssetPrice(asset);

			ILiquidationHelper.ProtocolReserveData
				memory reserveData = _getStructUserReserveData(asset, user);

			ILiquidationHelper.ProtocolReserveConfigurationData
				memory reserveConfigurationData = _getReserveConfigurationData(
					asset
				);

			(maxDebt, debtAsset) = _updateMaxDebt(
				reserveData,
				maxDebt,
				asset,
				debtAsset
			);

			(maxCollateralValue, collateralAsset) = _updateMaxCollateral(
				reserveData,
				reserveConfigurationData,
				maxCollateralValue,
				price,
				asset,
				collateralAsset
			);
		}
		if (debtAsset == address(0) || collateralAsset == address(0)) {
			revert ZeroAddress();
		}

		userDebt = UserDebt({
			user: user,
			debtAsset: debtAsset,
			collateralAsset: collateralAsset,
			debtToCover: maxDebt / 2
		});
	}

	function getStructUserAccountData(
		address user
	)
		public
		view
		returns (ILiquidationHelper.UserAccountData memory accountData)
	{
		if (address(user) == address(0)) revert ZeroAddress();

		(
			uint256 totalCollateralETH,
			uint256 totalDebtETH,
			uint256 availableBorrowsETH,
			uint256 currentLiquidationThreshold,
			uint256 ltv,
			uint256 healthFactor
		) = lendingPool.getUserAccountData(user);

		accountData = ILiquidationHelper.UserAccountData({
			totalCollateralETH: totalCollateralETH,
			totalDebtETH: totalDebtETH,
			availableBorrowsETH: availableBorrowsETH,
			currentLiquidationThreshold: currentLiquidationThreshold,
			ltv: ltv,
			healthFactor: healthFactor
		});
	}

	function _updateMaxDebt(
		ILiquidationHelper.ProtocolReserveData memory reserveData,
		uint256 currentMaxDebt,
		address currentDebtAsset,
		address debtAsset
	) internal pure returns (uint256 newMaxDebt, address newDebtAsset) {
		if (
			reserveData.currentStableDebt == 0 &&
			reserveData.currentVariableDebt == 0
		) return (currentMaxDebt, debtAsset);

		uint256 currentDebt = reserveData.currentStableDebt +
			reserveData.currentVariableDebt;

		if (currentDebt > currentMaxDebt) {
			newMaxDebt = currentDebt;
			newDebtAsset = currentDebtAsset;

			return (newMaxDebt, newDebtAsset);
		}
		return (currentMaxDebt, debtAsset);
	}

	function _updateMaxCollateral(
		ILiquidationHelper.ProtocolReserveData memory reserveData,
		ILiquidationHelper.ProtocolReserveConfigurationData
			memory reserveConfigurationData,
		uint256 currentMaxCollateralValue,
		uint256 price,
		address currentCollateral,
		address collateralAsset
	)
		internal
		pure
		returns (uint256 newMaxCollateralValue, address newMaxCollateral)
	{
		if (
			!reserveData.usageAsCollateralEnabled &&
			reserveData.currentATokenBalance == 0 &&
			reserveConfigurationData.isFrozen
		) return (currentMaxCollateralValue, collateralAsset);

		uint256 collateralValue = reserveData.currentATokenBalance *
			price *
			reserveConfigurationData.liquidationBonus;

		if (collateralValue > currentMaxCollateralValue) {
			newMaxCollateralValue = collateralValue;
			newMaxCollateral = currentCollateral;

			return (newMaxCollateralValue, newMaxCollateral);
		}
		return (currentMaxCollateralValue, collateralAsset);
	}
	function _getStructUserReserveData(
		address asset,
		address user
	)
		internal
		view
		returns (ILiquidationHelper.ProtocolReserveData memory reserveData)
	{
		if (asset == address(0) || user == address(0)) revert ZeroAddress();

		(
			uint256 currentATokenBalance,
			uint256 currentStableDebt,
			uint256 currentVariableDebt,
			uint256 principalStableDebt,
			uint256 scaledVariableDebt,
			uint256 stableBorrowRate,
			uint256 liquidityRate,
			uint40 stableRateLastUpdated,
			bool usageAsCollateralEnabled
		) = dataProvider.getUserReserveData(asset, user);

		reserveData = ILiquidationHelper.ProtocolReserveData({
			currentATokenBalance: currentATokenBalance,
			currentStableDebt: currentStableDebt,
			currentVariableDebt: currentVariableDebt,
			principalStableDebt: principalStableDebt,
			scaledVariableDebt: scaledVariableDebt,
			stableBorrowRate: stableBorrowRate,
			liquidityRate: liquidityRate,
			stableRateLastUpdated: stableRateLastUpdated,
			usageAsCollateralEnabled: usageAsCollateralEnabled
		});
	}

	function _getReserveConfigurationData(
		address asset
	)
		internal
		view
		returns (
			ILiquidationHelper.ProtocolReserveConfigurationData
				memory configurationData
		)
	{
		(
			uint256 decimals,
			uint256 ltv,
			uint256 liquidationThreshold,
			uint256 liquidationBonus,
			uint256 reserveFactor,
			bool usageAsCollateralEnabled,
			bool borrowingEnabled,
			bool stableBorrowRateEnabled,
			bool isActive,
			bool isFrozen
		) = dataProvider.getReserveConfigurationData(asset);

		configurationData = ILiquidationHelper
			.ProtocolReserveConfigurationData({
				decimals: decimals,
				ltv: ltv,
				liquidationThreshold: liquidationThreshold,
				liquidationBonus: liquidationBonus,
				reserveFactor: reserveFactor,
				usageAsCollateralEnabled: usageAsCollateralEnabled,
				borrowingEnabled: borrowingEnabled,
				stableBorrowRateEnabled: stableBorrowRateEnabled,
				isActive: isActive,
				isFrozen: isFrozen
			});
	}

	function _validateUser(address user) internal view returns (bool isValid) {
		if (user == address(0)) revert ZeroAddress();

		ILiquidationHelper.UserAccountData
			memory userAccountData = getStructUserAccountData(user);

		if (userAccountData.healthFactor > 1e18) {
			isValid = false;
			return isValid;
		}
		isValid = true;

		return isValid;
	}

	receive() external payable {}
}
