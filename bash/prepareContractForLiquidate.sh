PRIVATE_KEY="0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"
USDC_ADDRESS="0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48"
ADDRESS_CONTRACT="0x77AD263Cd578045105FBFC88A477CAd808d39Cf6"
WHALE_ADDRESS="0x55fe002aeff02f77364de339a1292923a15844b8"
DEPOSIT_VALUE=308469283391880
RPC_URL="http://localhost:8545"

echo -e "Impersonate user for transfer USDC..."
cast rpc anvil_impersonateAccount $WHALE_ADDRESS

echo -e "Checking for whale balance..."
WHALE_BALANCE_HEX=$(cast call $USDC_ADDRESS "balanceOf(address)" \
	$WHALE_ADDRESS \
	--rpc-url $RPC_URL)
WHALE_BALANCE_DEC=$(cast to-dec $WHALE_BALANCE_HEX)
echo -e "WHALE_BALANCE: $WHALE_BALANCE_DEC"

echo -e "Approve to liquidation contract"
cast send $USDC_ADDRESS "approve(address,uint256)" \
	$ADDRESS_CONTRACT \
	10000000000000000000000000000000000000000000 \
	--from $WHALE_ADDRESS \
	--unlocked \
	--rpc-url $RPC_URL

echo -e "Deposit USDC to liquidation contract"
cast send $ADDRESS_CONTRACT "deposit(address,uint256)" \
	$USDC_ADDRESS \
	$DEPOSIT_VALUE \
	--from $WHALE_ADDRESS \
	--unlocked \
	--rpc-url $RPC_URL

echo -e "Checking balance USDC liquidation contract..."
BALANCE_CONTRACT_USDC_HEX=$(cast call $USDC_ADDRESS "balanceOf(address)" \
	$ADDRESS_CONTRACT \
	--rpc-url $RPC_URL)

BALANCE_CONTRACT_USDC_DEC=$(cast to-dec $BALANCE_CONTRACT_USDC_HEX)

echo -e "Balance USDC liquidation contract: $BALANCE_CONTRACT_USDC_DEC"

