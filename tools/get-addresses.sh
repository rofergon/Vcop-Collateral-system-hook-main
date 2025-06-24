#!/bin/bash

# Script para leer direcciones desde deployed-addresses.json
# Uso: source get-addresses.sh

if [ ! -f "deployed-addresses.json" ]; then
    echo "❌ deployed-addresses.json not found"
    exit 1
fi

# Leer direcciones desde el JSON de manera robusta
export DEPLOYED_REWARD_DISTRIBUTOR=$(cat deployed-addresses.json | jq -r '.rewards.rewardDistributor // empty')
export DEPLOYED_VCOP_TOKEN=$(cat deployed-addresses.json | jq -r '.vcopCollateral.vcopToken // empty')
export DEPLOYED_FLEXIBLE_LOAN_MANAGER=$(cat deployed-addresses.json | jq -r '.coreLending.flexibleLoanManager // empty')
export DEPLOYED_GENERIC_LOAN_MANAGER=$(cat deployed-addresses.json | jq -r '.coreLending.genericLoanManager // empty')
export DEPLOYED_VAULT_HANDLER=$(cat deployed-addresses.json | jq -r '.coreLending.vaultBasedHandler // empty')
export DEPLOYED_ORACLE=$(cat deployed-addresses.json | jq -r '.vcopCollateral.oracle // empty')
export DEPLOYED_COLLATERAL_MANAGER=$(cat deployed-addresses.json | jq -r '.vcopCollateral.collateralManager // empty')

# Verificar que las direcciones críticas se obtuvieron correctamente
if [ -z "$DEPLOYED_REWARD_DISTRIBUTOR" ] || [ -z "$DEPLOYED_VCOP_TOKEN" ]; then
    echo "❌ Error: Missing critical addresses in deployed-addresses.json"
    echo "RewardDistributor: '$DEPLOYED_REWARD_DISTRIBUTOR'"
    echo "VCOP Token: '$DEPLOYED_VCOP_TOKEN'"
    exit 1
fi

# Verificar formato de direcciones básico (debe empezar con 0x)
if [[ ! "$DEPLOYED_REWARD_DISTRIBUTOR" =~ ^0x ]]; then
    echo "❌ Error: Invalid RewardDistributor address format: '$DEPLOYED_REWARD_DISTRIBUTOR'"
    exit 1
fi

echo "✅ Addresses loaded from deployed-addresses.json:"
echo "  RewardDistributor: $DEPLOYED_REWARD_DISTRIBUTOR"
echo "  VCOP Token: $DEPLOYED_VCOP_TOKEN"
echo "  FlexibleLoanManager: $DEPLOYED_FLEXIBLE_LOAN_MANAGER"
echo "  GenericLoanManager: $DEPLOYED_GENERIC_LOAN_MANAGER"
echo "  VaultHandler: $DEPLOYED_VAULT_HANDLER"
echo "  Oracle: $DEPLOYED_ORACLE"
echo "  CollateralManager: $DEPLOYED_COLLATERAL_MANAGER" 