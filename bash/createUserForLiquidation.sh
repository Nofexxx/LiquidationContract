set -e  # Stop script with any error

# Settings
USER_ADDRESS="0x70997970C51812dc3A010C7d01b50e0d17dc79C8"
PRIVATE_KEY="0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d"
RPC_URL="http://localhost:8545"
WETH_ADDRESS="0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2"
USDC_ADDRESS="0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48"
ADDRESSES_PROVIDER="0xB53C1a33016B2DC2fF3653530bfF1848a515c8c5"
LENDING_POOL="0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9"
MOCK_ORACLE_ADDRESS="0x38628490c3043E5D0bbB26d5a0a62fC77342e9d5"

echo -e "Starting Aave liquidation test setup..."
clean_address() {
  local raw_address=$1

  shopt -s extglob

  raw_address=${raw_address#0x}
  cleaned_address=${raw_address##+(0)}

  echo -e "0x$cleaned_address"
}

# LENDING_POOL_RAW=$(cast call $ADDRESSES_PROVIDER "getLendingPool()" --rpc-url $RPC_URL) 
# LENDING_POOL=$(clean_address $LENDING_POOL_RAW)

echo -e "Lending pool raw: $LENDING_POOL_RAW"
echo -e "Lending Pool: $LENDING_POOL"

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

echo -e "Step 2: Approving WETH_ADDRESS for Aave..."
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

# ALLOWANCE=$(cast call 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2 "allowance(address,address)" 0x70997970C51812dc3A010C7d01b50e0d17dc79C8 0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9 --rpc-url http://localhost:8545)
# echo -e clean_address $ALLOWANCE


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
    1500000000 \
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

# USDC variable debt token
DEBT_TOKEN=0x619beb58998ed2278e08620f97007e1116d5d25b

BALANCE=$(cast call $DEBT_TOKEN "balanceOf(address)(uint256)" $USER_ADDRESS --rpc-url $RPC_URL)
echo "Current debt in USDC: $BALANCE"

BASE_SLOT=0  
SLOT=$(cast keccak $(cast abi-encode "f(address,uint256)" $USER_ADDRESS $BASE_SLOT))
NEW_DEBT=20000000000  # 20000 * 10^6
NEW_DEBT_HEX=$(printf "0x%064x" $NEW_DEBT)
cast rpc anvil_setStorageAt $DEBT_TOKEN $SLOT $NEW_DEBT_HEX --rpc-url $RPC_URL

NEW_BALANCE=$(cast call $DEBT_TOKEN "balanceOf(address)(uint256)" $USER_ADDRESS --rpc-url $RPC_URL)
echo "New debt in USDC: $NEW_BALANCE"

echo -e "Step 7: Checking final Health Factor..."
FINAL_HF=$(cast call $LENDING_POOL "getUserAccountData(address)" $USER_ADDRESS --rpc-url $RPC_URL)
echo "Final Health Factor data: $FINAL_HF"

HF_HEX=$(echo $FINAL_HF | sed 's/^0x//' | cut -c321-384)
HF_HEX="0x$HF_HEX"
HF_DEC=$(cast to-dec $HF_HEX)

# 1.0 = 1 * 10^18 = 0xde0b6b3a7640000
HF_THRESHOLD="0x0de0b6b3a7640000"

# Сравниваем напрямую в виде BigNumber
THRESHOLD_DEC=$(cast --to-dec $HF_THRESHOLD)
echo -e "HF_THRESHOLD: $HF_THRESHOLD"
echo -e "HF: $HF_DEC"

if (( HF_DEC < THRESHOLD_DEC )); then
    echo -e "SUCCESS! Health Factor < 1.0 - Position is ready for liquidation!"
else
    echo -e "Position is still healthy (HF >= 1.0)"
fi
