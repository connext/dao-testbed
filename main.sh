#!/bin/bash

# Exporting values for all mainnet network RPCs.
export MAINNET_RPC_URL="https://eth.llamarpc.com"
export OPTIMISM_RPC_URL="https://optimism.llamarpc.com"
export BNB_RPC_URL="https://bsc-pokt.nodies.app"
export GNOSIS_RPC_URL="https://gnosis.drpc.org"
export POLYGON_RPC_URL="https://polygon.drpc.org"
export ARBITRUM_ONE_RPC_URL="https://endpoints.omniatech.io/v1/arbitrum/one/public"


# Check gas snapshots
forge snapshot --check

# Run tests
forge test