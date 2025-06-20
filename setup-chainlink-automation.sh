#!/bin/bash

# ==================================================
# CHAINLINK AUTOMATION SETUP FOR BASE SEPOLIA
# ==================================================
# Este script configura las variables de entorno necesarias
# para registrar upkeeps en el registry oficial de Chainlink

echo "🔗 CHAINLINK AUTOMATION SETUP FOR BASE SEPOLIA"
echo "==============================================="

# Verificar que estamos en Base Sepolia
if [ -f .env ]; then
    source .env
    if [ "$CHAIN_ID" != "84532" ]; then
        echo "❌ Error: CHAIN_ID should be 84532 for Base Sepolia"
        echo "Current CHAIN_ID: $CHAIN_ID"
        exit 1
    fi
else
    echo "❌ Error: .env file not found"
    exit 1
fi

# Leer direcciones desde deployed-addresses-mock.json
if [ ! -f "deployed-addresses-mock.json" ]; then
    echo "❌ Error: deployed-addresses-mock.json not found"
    exit 1
fi

# Extraer direcciones usando jq
AUTOMATION_KEEPER=$(jq -r '.automation.automationKeeper' deployed-addresses-mock.json)
FLEXIBLE_LOAN_MANAGER=$(jq -r '.coreLending.flexibleLoanManager' deployed-addresses-mock.json)

echo "📋 CURRENT DEPLOYMENT ADDRESSES:"
echo "Automation Keeper: $AUTOMATION_KEEPER"
echo "Flexible Loan Manager: $FLEXIBLE_LOAN_MANAGER"
echo ""

# Configurar variables de entorno para el script
export AUTOMATION_KEEPER_ADDRESS="$AUTOMATION_KEEPER"
export FLEXIBLE_LOAN_MANAGER_ADDRESS="$FLEXIBLE_LOAN_MANAGER"

echo "🔧 CHAINLINK OFFICIAL ADDRESSES (Base Sepolia):"
echo "Registry: 0x91D4a4C3D448c7f3CB477332B1c7D420a5810aC3"
echo "Registrar: 0xf28D56F3A707E25B71Ce529a21AF388751E1CF2A"
echo "LINK Token: 0xE4aB69C077896252FAFBD49EFD26B5D171A32410"
echo ""

echo "✅ Environment configured successfully!"
echo ""
echo "📝 NEXT STEPS:"
echo "1. Ensure you have at least 5 LINK tokens in your wallet"
echo "2. Get LINK tokens from Base Sepolia faucet if needed"
echo "3. Run the registration script:"
echo "   forge script script/automation/RegisterChainlinkUpkeep.s.sol:RegisterChainlinkUpkeep \\"
echo "     --rpc-url \$RPC_URL --private-key \$PRIVATE_KEY --broadcast"
echo ""
echo "🌐 USEFUL LINKS:"
echo "- Base Sepolia LINK Faucet: https://faucets.chain.link/"
echo "- Chainlink Automation UI: https://automation.chain.link/"
echo "- Base Sepolia Explorer: https://sepolia.basescan.org/"
echo "" 