#!/bin/bash

# ==================================================
# UPDATE .ENV WITH CHAINLINK FORWARDER ADDRESS
# ==================================================
# Script para agregar la dirección del Forwarder al archivo .env

echo "🔧 UPDATING .ENV WITH CHAINLINK FORWARDER"
echo "=========================================="

# Verificar que existe .env
if [ ! -f ".env" ]; then
    echo "❌ Error: .env file not found"
    exit 1
fi

# Pedir la dirección del Forwarder al usuario
echo ""
echo "After registering your upkeep with Chainlink, you should have received"
echo "a Forwarder address in the output."
echo ""
echo "Example output:"
echo "   Forwarder Address: 0x1234567890abcdef1234567890abcdef12345678"
echo ""

read -p "Enter your Chainlink Forwarder address: " forwarder_address

# Validar que parece una dirección válida
if [[ ! $forwarder_address =~ ^0x[a-fA-F0-9]{40}$ ]]; then
    echo "❌ Error: Invalid address format. Should be 0x followed by 40 hex characters"
    exit 1
fi

# Verificar si ya existe en .env
if grep -q "CHAINLINK_FORWARDER_ADDRESS" .env; then
    # Actualizar la línea existente
    sed -i "s/CHAINLINK_FORWARDER_ADDRESS=.*/CHAINLINK_FORWARDER_ADDRESS=$forwarder_address/" .env
    echo "✅ Updated existing CHAINLINK_FORWARDER_ADDRESS in .env"
else
    # Agregar nueva línea
    echo "" >> .env
    echo "# Chainlink Automation Forwarder" >> .env
    echo "CHAINLINK_FORWARDER_ADDRESS=$forwarder_address" >> .env
    echo "✅ Added CHAINLINK_FORWARDER_ADDRESS to .env"
fi

echo ""
echo "📋 Your .env now contains:"
echo "   CHAINLINK_FORWARDER_ADDRESS=$forwarder_address"
echo ""
echo "🚀 Next step: Run the forwarder configuration"
echo "   make configure-forwarder" 