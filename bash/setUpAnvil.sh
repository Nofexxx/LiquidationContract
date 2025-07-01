RPC_URL="https://eth-mainnet.g.alchemy.com/v2/8_KLsUQ3tHmnRKbId0FiD1clekPe2MYo"
BLOCK_NUMBER=17944912

echo -e "Run anvil on $BLOCK_NUMBER block"

anvil --fork-url $RPC_URL --fork-block-number $BLOCK_NUMBER 
