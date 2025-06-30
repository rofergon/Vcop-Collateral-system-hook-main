#!/bin/bash

# ========================================
# 🤖 UPDATE AUTOMATION ADDRESSES IN JSON
# ========================================
# Extracts automation addresses from deployment log and updates deployed-addresses-mock.json

echo "🤖 Updating automation addresses in deployed-addresses-mock.json..."

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    echo "❌ Error: jq is required but not installed"
    echo "   Install with: sudo apt install jq"
    exit 1
fi

# Check if deployed-addresses-mock.json exists
if [ ! -f "deployed-addresses-mock.json" ]; then
    echo "❌ Error: deployed-addresses-mock.json not found!"
    echo "   Deploy core system first: make deploy-avalanche-complete-mock"
    exit 1
fi

# Find the latest automation deployment log
AUTOMATION_LOG=$(find broadcast/DeployAutomationMock.s.sol -name "run-latest.json" 2>/dev/null | head -1)

if [ -z "$AUTOMATION_LOG" ]; then
    echo "❌ Error: Automation deployment log not found!"
    echo "   Deploy automation first: make deploy-avalanche-automation"
    exit 1
fi

echo "📋 Found automation log: $AUTOMATION_LOG"

# Extract addresses directly from the latest JSON broadcast
echo "📋 Extracting addresses from deployment transactions..."

# Get the deployed contract addresses from transactions
AUTOMATION_KEEPER=$(jq -r '.transactions[] | select(.contractName == "LoanAutomationKeeperOptimized") | .contractAddress' "$AUTOMATION_LOG" 2>/dev/null | head -1)
LOAN_ADAPTER=$(jq -r '.transactions[] | select(.contractName == "LoanManagerAutomationAdapter") | .contractAddress' "$AUTOMATION_LOG" 2>/dev/null | head -1)
PRICE_TRIGGER=$(jq -r '.transactions[] | select(.contractName == "PriceChangeLogTrigger") | .contractAddress' "$AUTOMATION_LOG" 2>/dev/null | head -1)

# Set network-specific Chainlink addresses based on chain ID
CHAIN_ID=$(jq -r '.chain' "$AUTOMATION_LOG" 2>/dev/null)

if [ "$CHAIN_ID" = "43113" ]; then
    # Avalanche Fuji
    AUTOMATION_REGISTRY="0x819B58A646CDd8289275A87653a2aA4902b14fe6"
    CHAINLINK_REGISTRAR="0xD23D3D1b81711D75E1012211f1b65Cc7dBB474e2"
    CHAINLINK_LINK_TOKEN="0x0b9d5D9136855f6FEc3c0993feE6E9CE8a297846"
elif [ "$CHAIN_ID" = "84532" ]; then
    # Base Sepolia
    AUTOMATION_REGISTRY="0x91D4a4C3D448c7f3CB477332B1c7D420a5810aC3"
    CHAINLINK_REGISTRAR="0xf28D56F3A707E25B71Ce529a21AF388751E1CF2A"
    CHAINLINK_LINK_TOKEN="0xE4aB69C077896252FAFBD49EFD26B5D171A32410"
else
    echo "❌ Error: Unsupported chain ID: $CHAIN_ID"
    exit 1
fi

# Validate that we have all required addresses
if [ -z "$AUTOMATION_KEEPER" ] || [ -z "$LOAN_ADAPTER" ] || [ -z "$PRICE_TRIGGER" ]; then
    echo "❌ Error: Could not extract all automation addresses"
    echo "   Automation Keeper: $AUTOMATION_KEEPER"
    echo "   Loan Adapter: $LOAN_ADAPTER"
    echo "   Price Trigger: $PRICE_TRIGGER"
    exit 1
fi

echo "✅ Found automation addresses:"
echo "   Automation Keeper: $AUTOMATION_KEEPER"
echo "   Loan Adapter: $LOAN_ADAPTER"
echo "   Price Trigger: $PRICE_TRIGGER"
echo "   Automation Registry: $AUTOMATION_REGISTRY"
echo "   Chainlink Registrar: $CHAINLINK_REGISTRAR"
echo "   LINK Token: $CHAINLINK_LINK_TOKEN"

# Update the JSON file using jq
echo "📝 Updating deployed-addresses-mock.json..."

# Create backup
cp deployed-addresses-mock.json deployed-addresses-mock.json.backup

# Add automation section to JSON
jq --arg keeper "$AUTOMATION_KEEPER" \
   --arg adapter "$LOAN_ADAPTER" \
   --arg trigger "$PRICE_TRIGGER" \
   --arg registry "$AUTOMATION_REGISTRY" \
   --arg registrar "$CHAINLINK_REGISTRAR" \
   --arg link "$CHAINLINK_LINK_TOKEN" \
   '. + {
     "automation": {
       "automationRegistry": $registry,
       "automationKeeper": $keeper,
       "loanAdapter": $adapter,
       "priceLogTrigger": $trigger,
       "chainlinkRegistrar": $registrar,
       "chainlinkLinkToken": $link
     }
   }' deployed-addresses-mock.json > deployed-addresses-mock.json.tmp

# Replace original file
mv deployed-addresses-mock.json.tmp deployed-addresses-mock.json

echo "✅ Successfully updated deployed-addresses-mock.json with automation addresses!"
echo "📋 Backup saved as: deployed-addresses-mock.json.backup"

# Verify the update
echo ""
echo "🔍 Verification - automation section in JSON:"
jq '.automation' deployed-addresses-mock.json

echo ""
echo "✅ Automation addresses successfully added to deployed-addresses-mock.json!" 