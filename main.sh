#!/bin/bash

# Exporting values for all mainnet network RPCs.
export MAINNET_RPC_URL="https://eth.llamarpc.com"
export OPTIMISM_RPC_URL="https://optimism.llamarpc.com"
export BNB_RPC_URL="https://binance.llamarpc.com"
export GNOSIS_RPC_URL="https://gnosis-pokt.nodies.app"
export POLYGON_RPC_URL="https://polygon.llamarpc.com"
export ARBITRUM_ONE_RPC_URL="https://arbitrum.llamarpc.com"


# Check gas snapshots
forge snapshot --check

# Run tests
forge test