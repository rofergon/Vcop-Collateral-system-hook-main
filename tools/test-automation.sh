#!/bin/bash

# CHAINLINK AUTOMATION TESTING SCRIPT
# ====================================
# This script tests your deployed Chainlink Automation system

set -e

# Check environment variables
if [ -z "$PRIVATE_KEY" ]; then
    echo "ERROR: PRIVATE_KEY environment variable not set"
    exit 1
fi

if [ -z "$RPC_URL" ]; then
    echo "ERROR: RPC_URL environment variable not set"
    exit 1
fi

echo "=========================================="
echo "CHAINLINK AUTOMATION COMPLETE TEST"
echo "=========================================="
echo ""
echo "Your upkeep ID: 35283090123137439879057452590905787868464269668261475719855807879502576065354"
echo "Dashboard: https://automation.chain.link/base-sepolia"
echo ""

# Function to wait with countdown
wait_with_countdown() {
    local seconds=$1
    local message=$2
    echo "$message"
    for ((i=seconds; i>0; i--)); do
        echo -ne "\rWaiting $i seconds... "
        sleep 1
    done
    echo -e "\rDone!           "
    echo ""
}

# Step 1: Create test positions
echo "STEP 1: Creating test positions..."
echo "=================================="
forge script script/test/Step1_CreateTestPositions.s.sol \
    --rpc-url "$RPC_URL" \
    --private-key "$PRIVATE_KEY" \
    --broadcast

if [ $? -eq 0 ]; then
    echo "✅ Step 1 completed successfully!"
else
    echo "❌ Step 1 failed!"
    exit 1
fi

# Wait before price crash
wait_with_countdown 60 "Waiting for positions to settle before price crash..."

# Step 2: Crash prices
echo "STEP 2: Crashing prices to trigger liquidations..."
echo "=================================================="
forge script script/test/Step2_CrashPrices.s.sol \
    --rpc-url "$RPC_URL" \
    --private-key "$PRIVATE_KEY" \
    --broadcast

if [ $? -eq 0 ]; then
    echo "✅ Step 2 completed successfully!"
    echo "💥 ETH price crashed from $2,500 to $1,000"
    echo "🤖 Chainlink Automation should detect liquidatable positions"
else
    echo "❌ Step 2 failed!"
    exit 1
fi

# Wait for Chainlink to detect and execute
wait_with_countdown 120 "Waiting for Chainlink Automation to detect and execute liquidations..."

# Step 3: Verify results
echo "STEP 3: Verifying liquidation results..."
echo "======================================="
forge script script/test/Step3_VerifyLiquidations.s.sol --rpc-url "$RPC_URL"

echo ""
echo "=========================================="
echo "TEST COMPLETED!"
echo "=========================================="
echo ""
echo "🔍 Check your results:"
echo "1. Dashboard: https://automation.chain.link/base-sepolia"
echo "2. Search for upkeep: 35283090123137439879057452590905787868464269668261475719855807879502576065354"
echo "3. Look for:"
echo "   - Reduced LINK balance"
echo "   - performUpkeep executions in history"
echo "   - Gas consumption metrics"
echo ""
echo "🎉 If LINK balance decreased, your automation is working!"
echo "📊 Check the verification output above for detailed stats" 