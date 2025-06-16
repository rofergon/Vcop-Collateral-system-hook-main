#!/bin/bash

# Script to update deployed-addresses.json with ALL latest deployment addresses
# This script extracts addresses from .env and latest broadcasts to update the complete JSON

set -e

echo "🔄 Updating deployed-addresses.json with complete latest deployment..."

# Define paths
DEPLOYED_JSON="deployed-addresses.json"
ENV_FILE=".env"

# Check if .env exists
if [ ! -f "$ENV_FILE" ]; then
    echo "❌ .env file not found"
    exit 1
fi

echo "📖 Reading addresses from .env file..."

# Extract addresses from .env file
MOCK_ETH=$(grep "MOCK_ETH_ADDRESS" .env | cut -d'=' -f2 | tr -d ' ')
MOCK_WBTC=$(grep "MOCK_WBTC_ADDRESS" .env | cut -d'=' -f2 | tr -d ' ')
MOCK_USDC=$(grep "MOCK_USDC_ADDRESS" .env | cut -d'=' -f2 | tr -d ' ')
VCOP_TOKEN=$(grep "VCOP_TOKEN_ADDRESS" .env | cut -d'=' -f2 | tr -d ' ')
VCOP_ORACLE=$(grep "VCOP_ORACLE_ADDRESS" .env | cut -d'=' -f2 | tr -d ' ')
POOL_MANAGER=$(grep "POOL_MANAGER_ADDRESS" .env | cut -d'=' -f2 | tr -d ' ')
GENERIC_LOAN_MANAGER=$(grep "GENERIC_LOAN_MANAGER_ADDRESS" .env | cut -d'=' -f2 | tr -d ' ')
FLEXIBLE_LOAN_MANAGER=$(grep "FLEXIBLE_LOAN_MANAGER_ADDRESS" .env | cut -d'=' -f2 | tr -d ' ')
VAULT_HANDLER=$(grep "VAULT_HANDLER_ADDRESS" .env | cut -d'=' -f2 | tr -d ' ')
COLLATERAL_MANAGER=$(grep "COLLATERAL_MANAGER_ADDRESS" .env | cut -d'=' -f2 | tr -d ' ')

# Validate critical addresses
if [ -z "$VCOP_ORACLE" ] || [ "$VCOP_ORACLE" = "null" ]; then
    echo "❌ VCOP_ORACLE_ADDRESS not found in .env"
    exit 1
fi

echo "✅ Extracted addresses from .env:"
echo "  Mock ETH: $MOCK_ETH"
echo "  Mock WBTC: $MOCK_WBTC"
echo "  Mock USDC: $MOCK_USDC"
echo "  VCOP Token: $VCOP_TOKEN"
echo "  VCOP Oracle: $VCOP_ORACLE"
echo "  Pool Manager: $POOL_MANAGER"
echo "  Generic Loan Manager: $GENERIC_LOAN_MANAGER"
echo "  Flexible Loan Manager: $FLEXIBLE_LOAN_MANAGER"
echo "  Vault Handler: $VAULT_HANDLER"
echo "  Collateral Manager: $COLLATERAL_MANAGER"

# Check for RewardDistributor (might not exist yet)
REWARD_DISTRIBUTOR=$(grep "REWARD_DISTRIBUTOR_ADDRESS" .env 2>/dev/null | cut -d'=' -f2 | tr -d ' ' || echo "")

# Backup original file
echo "💾 Creating backup..."
cp "$DEPLOYED_JSON" "${DEPLOYED_JSON}.backup"

# Update the complete JSON using jq
echo "📝 Updating complete deployed-addresses.json..."

TIMESTAMP=$(date +%s)

cat "$DEPLOYED_JSON" | jq \
    --arg mockETH "$MOCK_ETH" \
    --arg mockWBTC "$MOCK_WBTC" \
    --arg mockUSDC "$MOCK_USDC" \
    --arg vcopToken "$VCOP_TOKEN" \
    --arg oracle "$VCOP_ORACLE" \
    --arg poolManager "$POOL_MANAGER" \
    --arg genericLoanManager "$GENERIC_LOAN_MANAGER" \
    --arg flexibleLoanManager "$FLEXIBLE_LOAN_MANAGER" \
    --arg vaultHandler "$VAULT_HANDLER" \
    --arg collateralManager "$COLLATERAL_MANAGER" \
    --arg rewardDistributor "$REWARD_DISTRIBUTOR" \
    --arg timestamp "$TIMESTAMP" \
    '{
      "network": "Base Sepolia",
      "chainId": 84532,
      "deployer": .deployer,
      "deploymentDate": $timestamp,
      "poolManager": $poolManager,
      "mockTokens": {
        "ETH": $mockETH,
        "WBTC": $mockWBTC,
        "USDC": $mockUSDC
      },
      "vcopCollateral": {
        "vcopToken": $vcopToken,
        "oracle": $oracle,
        "priceCalculator": .vcopCollateral.priceCalculator,
        "collateralManager": $collateralManager,
        "hook": .vcopCollateral.hook
      },
      "coreLending": {
        "genericLoanManager": $genericLoanManager,
        "flexibleLoanManager": $flexibleLoanManager,
        "vaultBasedHandler": $vaultHandler,
        "mintableBurnableHandler": .coreLending.mintableBurnableHandler,
        "flexibleAssetHandler": .coreLending.flexibleAssetHandler,
        "riskCalculator": .coreLending.riskCalculator
      },
      "rewards": (if $rewardDistributor != "" then {
        "rewardDistributor": $rewardDistributor
      } else .rewards end),
      "chainlink": {
        "oracle": $oracle,
        "btcUsdFeed": "0x0FB99723Aee6f420beAD13e6bBB79b7E6F034298",
        "ethUsdFeed": "0x4aDC67696bA383F43DD60A9e78F2C97Fbbfc7cb1",
        "enabled": true,
        "deploymentDate": $timestamp,
        "network": "Base Sepolia"
      }
    }' > "${DEPLOYED_JSON}.tmp"

# Replace original with updated version
mv "${DEPLOYED_JSON}.tmp" "$DEPLOYED_JSON"

echo "✅ deployed-addresses.json updated successfully with complete system!"
echo "📋 Updated addresses:"
echo "  Oracle: $VCOP_ORACLE"
echo "  Mock Tokens: ETH($MOCK_ETH), WBTC($MOCK_WBTC), USDC($MOCK_USDC)"
echo "  Core System: $GENERIC_LOAN_MANAGER, $FLEXIBLE_LOAN_MANAGER"
echo "  Chainlink: Enabled with BTC/USD and ETH/USD feeds"
echo "💾 Backup saved as: ${DEPLOYED_JSON}.backup"

echo ""
echo "🎉 Complete address update completed successfully!"
echo "📄 JSON now contains all current deployment addresses"
echo "🔗 Chainlink Oracle integration: READY"
echo "Ready to use!" 