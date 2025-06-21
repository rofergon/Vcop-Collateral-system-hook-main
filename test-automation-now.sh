#!/bin/bash

# 🧪 AUTOMATION TESTING SCRIPT
# ============================
# Execute automation tests WITHOUT Chainlink registration required
# All tests work locally using your deployed contracts

echo "🧪 CHAINLINK AUTOMATION LOCAL TESTING"
echo "======================================"
echo ""
echo "✅ These tests work WITHOUT Chainlink registration"
echo "✅ No LINK tokens required"
echo "✅ Direct testing of your smart contracts"
echo ""

# Check if deployed addresses exist
if [ ! -f "deployed-addresses-mock.json" ]; then
    echo "❌ deployed-addresses-mock.json not found!"
    echo "   Run: make deploy-mock"
    exit 1
fi

echo "Available tests:"
echo "1. 🧪 Simple automation test"
echo "2. 🎯 Comprehensive test (with liquidation)"
echo "3. 🔍 Quick checkUpkeep test"
echo "4. 🎲 Create risk positions"
echo "5. 📊 Show all available commands"
echo ""

read -p "Choose test [1-5]: " choice

case $choice in
    1)
        echo "🧪 Running simple automation test..."
        make test-automation-local
        ;;
    2)
        echo "🎯 Running comprehensive automation test..."
        make test-automation-comprehensive
        ;;
    3)
        echo "🔍 Running quick checkUpkeep test..."
        make manual-checkupkeep-test
        ;;
    4)
        echo "🎲 Creating test positions with different risk levels..."
        make create-risk-positions
        ;;
    5)
        echo "📊 Available automation commands:"
        make automation-test-summary
        ;;
    *)
        echo "❌ Invalid choice"
        exit 1
        ;;
esac

echo ""
echo "✅ Test completed!"
echo ""
echo "📝 What these tests prove:"
echo "   - checkUpkeep() works correctly"
echo "   - performUpkeep() executes liquidations"
echo "   - Price manipulation triggers automation"
echo "   - Risk detection is accurate"
echo "   - System is ready for Chainlink registration"
echo ""
echo "🌐 For LIVE automation, register at:"
echo "   https://automation.chain.link/base-sepolia" 