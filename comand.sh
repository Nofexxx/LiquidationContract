set -e  # Stop script with any error

# Settings
USER_ADDRESS="0x70997970C51812dc3A010C7d01b50e0d17dc79C8"
PRIVATE_KEY="0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d"
RPC_URL="http://127.0.0.1:8545"
WETH_ADDRESS="0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2"
USDC_ADDRESS="0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48"
LENDING_POOL="0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9"

echo -e "Starting Aave liquidation test setup..."

echo -e "Step 1: Wrapping ETH to WETH..."
if cast send $WETH_ADDRESS "deposit()" \
  --value 10ether \
    --private-key $PRIVATE_KEY \
  --rpc-url $RPC_URL; then
    echo -e "10 ETH wrapped to WETH"
else
    echo -e "Failed to wrap ETH"
    exit 1
fi

echo -e "Step 2: Approving WETH for Aave..."
if cast send $WETH_ADDRESS "approve(address,uint256)" \
  $LENDING_POOL \
  115792089237316195423570985008687907853269984665640564039457584007913129639935 \
  --private-key $PRIVATE_KEY \
  --rpc-url $RPC_URL; then
    echo -e "WETH approved"
else
    echo -e "Failed to approve WETH"
    exit 1
fi

echo -e "Step 3: Depositing WETH as collateral..."
if cast send $LENDING_POOL "deposit(address,uint256,address,uint16)" \
  $WETH_ADDRESS \
  10000000000000000000 \
  $USER_ADDRESS \
  0 \
    --private-key $PRIVATE_KEY \
  --rpc-url $RPC_URL; then
    echo -e "10 WETH deposited as collateral"
else
    echo -e "Failed to deposit WETH"
    exit 1
fi

echo -e "Step 4: Checking available borrow amount..."
USER_DATA=$(cast call $LENDING_POOL "getUserAccountData(address)" $USER_ADDRESS --rpc-url $RPC_URL)
echo "User account data: $USER_DATA"

borrow() {
  if cast send $LENDING_POOL "borrow(address,uint256,uint256,uint16,address)" \
    $USDC_ADDRESS \
    15000000000 \
    2 \
    0 \
    $USER_ADDRESS \
    --private-key $PRIVATE_KEY \
    --rpc-url $RPC_URL; then
    return 0
  else
    echo -e "borrow failed"
    return 1
  fi
}

echo -e "Step 5: Borrowing USDC..."
if borrow; then
    echo -e "15000 USDC borrowed"
else
    echo -e "Failed to borrow USDC"
    exit 1
fi

echo -e "Step 5: Checking current Health Factor..."
CURRENT_HF=$(cast call $LENDING_POOL "getUserAccountData(address)" $USER_ADDRESS --rpc-url $RPC_URL)
echo "Current Health Factor data: $CURRENT_HF"

# echo -e "Step 6: Lowering HF by by increasing debt"
# borrow


echo "Price Oracle: $PRICE_ORACLE"
echo "Lending Pool: $LENDING_POOL"

PRICE_ORACLE=$(cast call $ADDRESSES_PROVIDER "getPriceOracle()" --rpc-url $RPC_URL)
# Текущая цена ETH
CURRENT_PRICE=$(cast call $PRICE_ORACLE "getAssetPrice(address)" $WETH --rpc-url $RPC_URL)
echo -e "Current price ETH: $CURRENT_PRICE"

# Понизить цену ETH на 50%
NEW_PRICE=$((CURRENT_PRICE / 2))
echo -e "New price ETH: $NEW_PRICE"

ORACLE_ADMIN=$(cast call $PRICE_ORACLE "owner()" --rpc-url $RPC_URL)
cast rpc anvil_impersonateAccount $ORACLE_ADMIN --rpc-url $RPC_URL

cast send $PRICE_ORACLE "setAssetPrice(address,uint256)" $WETH $NEW_PRICE --from $ORACLE_ADMIN --rpc-url $RPC_URL


echo -e "Step 7: Checking final Health Factor..."
FINAL_HF=$(cast call $LENDING_POOL "getUserAccountData(address)" $USER_ADDRESS --rpc-url $RPC_URL)
echo "Final Health Factor data: $FINAL_HF"

# Извлекаем healthFactor из последнего 32-байтного слота
HF_HEX=$(echo $FINAL_HF | sed 's/^0x//' | tail -c 65)
HF_HEX="0x$HF_HEX"

echo -e "Health Factor hex: $HF_HEX"

# 1.0 в фиксированной точке: 1 * 10^18 = 0xde0b6b3a7640000
HF_THRESHOLD="0x0de0b6b3a7640000"

# Сравниваем напрямую в виде BigNumber
HF_DEC=$(cast --to-dec $HF_HEX)
THRESHOLD_DEC=$(cast --to-dec $HF_THRESHOLD)

if (( HF_DEC < THRESHOLD_DEC )); then
    echo -e "SUCCESS! Health Factor < 1.0 - Position is ready for liquidation!"
else
    echo -e "Position is still healthy (HF >= 1.0)"
fi
