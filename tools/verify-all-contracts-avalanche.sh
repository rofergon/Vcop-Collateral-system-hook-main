#!/bin/bash

# ========================================
# 🏔️ AVALANCHE FUJI CONTRACT VERIFICATION
# ========================================
# Verifies all deployed contracts on Avalanche Fuji using Snowtrace API

echo "🏔️ AVALANCHE FUJI CONTRACT VERIFICATION"
echo "======================================="

# Check if deployed addresses file exists
if [ ! -f "deployed-addresses-mock.json" ]; then
    echo "❌ deployed-addresses-mock.json not found!"
    echo "   Deploy contracts first: make deploy-avalanche-full-stack-mock"
    exit 1
fi

# Load environment variables
if [ ! -f ".env" ]; then
    echo "❌ .env file not found!"
    exit 1
fi

source .env

# Verify we're on Avalanche Fuji
if [ "$CHAIN_ID" != "43113" ]; then
    echo "❌ Error: CHAIN_ID should be 43113 for Avalanche Fuji"
    echo "Current CHAIN_ID: $CHAIN_ID"
    exit 1
fi

# Check Snowtrace API key
if [ -z "$SNOWTRACE_API_KEY" ]; then
    echo "❌ SNOWTRACE_API_KEY not set in .env file"
    echo "   Get API key from: https://snowtrace.io/apis"
    exit 1
fi

echo "✅ Configuration verified"
echo "   Network: Avalanche Fuji (Chain ID: 43113)"
echo "   Explorer: https://testnet.snowtrace.io"
echo "   API Key: ${SNOWTRACE_API_KEY:0:8}..."
echo ""

# Extract addresses from JSON
MOCK_ETH=$(jq -r '.tokens.mockETH' deployed-addresses-mock.json)
MOCK_WBTC=$(jq -r '.tokens.mockWBTC' deployed-addresses-mock.json)
MOCK_USDC=$(jq -r '.tokens.mockUSDC' deployed-addresses-mock.json)
VCOP_TOKEN=$(jq -r '.tokens.vcopToken' deployed-addresses-mock.json)

MOCK_ORACLE=$(jq -r '.vcopCollateral.mockVcopOracle' deployed-addresses-mock.json)
PRICE_CALCULATOR=$(jq -r '.vcopCollateral.vcopPriceCalculator' deployed-addresses-mock.json)
COLLATERAL_MANAGER=$(jq -r '.vcopCollateral.vcopCollateralManager' deployed-addresses-mock.json)
HOOK_ADDRESS=$(jq -r '.vcopCollateral.vcopCollateralHook' deployed-addresses-mock.json)

GENERIC_LOAN_MANAGER=$(jq -r '.coreLending.genericLoanManager' deployed-addresses-mock.json)
FLEXIBLE_LOAN_MANAGER=$(jq -r '.coreLending.flexibleLoanManager' deployed-addresses-mock.json)
VAULT_HANDLER=$(jq -r '.coreLending.vaultBasedHandler' deployed-addresses-mock.json)
MINTABLE_HANDLER=$(jq -r '.coreLending.mintableBurnableHandler' deployed-addresses-mock.json)
FLEXIBLE_HANDLER=$(jq -r '.coreLending.flexibleAssetHandler' deployed-addresses-mock.json)
RISK_CALCULATOR=$(jq -r '.coreLending.riskCalculator' deployed-addresses-mock.json)
PRICE_REGISTRY=$(jq -r '.coreLending.dynamicPriceRegistry' deployed-addresses-mock.json)

echo "📋 CONTRACTS TO VERIFY:"
echo "========================"
echo "Mock Tokens:"
echo "  ETH:  $MOCK_ETH"
echo "  WBTC: $MOCK_WBTC"
echo "  USDC: $MOCK_USDC"
echo "  VCOP: $VCOP_TOKEN"
echo ""
echo "VCOP Collateral System:"
echo "  Mock Oracle:         $MOCK_ORACLE"
echo "  Price Calculator:    $PRICE_CALCULATOR"
echo "  Collateral Manager:  $COLLATERAL_MANAGER"
echo "  Hook:                $HOOK_ADDRESS"
echo ""
echo "Core Lending System:"
echo "  Generic Loan Manager:  $GENERIC_LOAN_MANAGER"
echo "  Flexible Loan Manager: $FLEXIBLE_LOAN_MANAGER"
echo "  Vault Handler:         $VAULT_HANDLER"
echo "  Mintable Handler:      $MINTABLE_HANDLER"
echo "  Flexible Handler:      $FLEXIBLE_HANDLER"
echo "  Risk Calculator:       $RISK_CALCULATOR"
echo "  Price Registry:        $PRICE_REGISTRY"
echo ""

# Function to verify contract
verify_contract() {
    local name=$1
    local address=$2
    local contract_path=$3
    
    if [ "$address" = "null" ] || [ "$address" = "" ] || [ "$address" = "0x0000000000000000000000000000000000000000" ]; then
        echo "⏭️  Skipping $name (not deployed)"
        return
    fi
    
    echo "🔍 Verifying $name at $address..."
    
    # Use forge verify-contract for Avalanche Fuji
    forge verify-contract \
        --chain-id 43113 \
        --num-of-optimizations 200 \
        --watch \
        --etherscan-api-key $SNOWTRACE_API_KEY \
        --verifier-url https://api.snowtrace.io/api \
        $address \
        $contract_path \
        --compiler-version v0.8.24+commit.e11b9ed9 \
        > /dev/null 2>&1
    
    if [ $? -eq 0 ]; then
        echo "✅ $name verified successfully"
    else
        echo "❌ $name verification failed"
    fi
    
    # Add delay to avoid rate limiting
    sleep 2
}

echo "🚀 STARTING VERIFICATION PROCESS..."
echo "=================================="

# Verify Mock Tokens
verify_contract "MockETH" "$MOCK_ETH" "src/mocks/MockETH.sol:MockETH"
verify_contract "MockWBTC" "$MOCK_WBTC" "src/mocks/MockWBTC.sol:MockWBTC"
verify_contract "MockUSDC" "$MOCK_USDC" "src/mocks/MockUSDC.sol:MockUSDC"
verify_contract "VCOPToken" "$VCOP_TOKEN" "src/VcopCollateral/VCOPCollateralized.sol:VCOPCollateralized"

# Verify VCOP Collateral System
verify_contract "MockVCOPOracle" "$MOCK_ORACLE" "src/VcopCollateral/MockVCOPOracle.sol:MockVCOPOracle"
verify_contract "VCOPPriceCalculator" "$PRICE_CALCULATOR" "src/VcopCollateral/VCOPPriceCalculator.sol:VCOPPriceCalculator"
verify_contract "VCOPCollateralManager" "$COLLATERAL_MANAGER" "src/VcopCollateral/VCOPCollateralManager.sol:VCOPCollateralManager"

# Skip hook if not deployed (Pool Manager not available)
if [ "$HOOK_ADDRESS" != "null" ] && [ "$HOOK_ADDRESS" != "" ] && [ "$HOOK_ADDRESS" != "0x0000000000000000000000000000000000000000" ]; then
    verify_contract "VCOPCollateralHook" "$HOOK_ADDRESS" "src/VcopCollateral/VCOPCollateralHook.sol:VCOPCollateralHook"
else
    echo "⏭️  Skipping VCOPCollateralHook (Pool Manager not available on Avalanche Fuji)"
fi

# Verify Core Lending System
verify_contract "GenericLoanManager" "$GENERIC_LOAN_MANAGER" "src/core/GenericLoanManager.sol:GenericLoanManager"
verify_contract "FlexibleLoanManager" "$FLEXIBLE_LOAN_MANAGER" "src/core/FlexibleLoanManager.sol:FlexibleLoanManager"
verify_contract "VaultBasedHandler" "$VAULT_HANDLER" "src/core/VaultBasedHandler.sol:VaultBasedHandler"
verify_contract "MintableBurnableHandler" "$MINTABLE_HANDLER" "src/core/MintableBurnableHandler.sol:MintableBurnableHandler"
verify_contract "FlexibleAssetHandler" "$FLEXIBLE_HANDLER" "src/core/FlexibleAssetHandler.sol:FlexibleAssetHandler"
verify_contract "RiskCalculator" "$RISK_CALCULATOR" "src/core/RiskCalculator.sol:RiskCalculator"
verify_contract "DynamicPriceRegistry" "$PRICE_REGISTRY" "src/core/DynamicPriceRegistry.sol:DynamicPriceRegistry"

echo ""
echo "🎉 AVALANCHE FUJI VERIFICATION COMPLETED!"
echo "========================================"
echo ""
echo "🌐 View verified contracts at:"
echo "   https://testnet.snowtrace.io"
echo ""
echo "🔍 Search by address or check your deployer address:"
echo "   https://testnet.snowtrace.io/address/$DEPLOYER_ADDRESS"
echo ""
echo "📋 Next steps:"
echo "   1. Check contract verification status on Snowtrace"
echo "   2. Register Chainlink upkeep: https://automation.chain.link/avalanche-fuji"
echo "   3. Test the system: make test-avalanche-automation" 