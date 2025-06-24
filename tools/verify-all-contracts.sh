#!/bin/bash

# Script para verificación dinámica de todos los contratos desplegados
# Lee las direcciones desde deployed-addresses-mock.json de forma dinámica

# Configuración
JSON_FILE="deployed-addresses-mock.json"
ETHERSCAN_API_KEY="${ETHERSCAN_API_KEY:-IS3DBRSG4KAU2T8BS54ECSD2TKSIT9T9CI}"
CHAIN_ID="${CHAIN_ID:-84532}"  # Base Sepolia por defecto
COMPILER_VERSION="0.8.26"

# Verificar que jq esté instalado
if ! command -v jq &> /dev/null; then
    echo "❌ Error: jq no está instalado. Instálalo con: sudo apt install jq"
    exit 1
fi

# Verificar que el archivo JSON existe
if [ ! -f "$JSON_FILE" ]; then
    echo "❌ Error: No se encontró el archivo $JSON_FILE"
    exit 1
fi

echo "🚀 Verificando contratos dinámicamente desde $JSON_FILE"
echo "Chain ID: $CHAIN_ID"
echo "Compiler: $COMPILER_VERSION"
echo "=================================================="

# Función para verificar un contrato
verify_contract() {
    local address=$1
    local contract_path=$2
    local contract_name=$3
    local constructor_args=$4
    local description=$5
    
    echo -e "\n📋 Verificando $description..."
    echo "   Dirección: $address"
    echo "   Contrato: $contract_path:$contract_name"
    
    if [ -n "$constructor_args" ]; then
        forge verify-contract \
            --chain-id $CHAIN_ID \
            --compiler-version $COMPILER_VERSION \
            --constructor-args "$constructor_args" \
            --etherscan-api-key $ETHERSCAN_API_KEY \
            --watch \
            $address \
            $contract_path:$contract_name
    else
        forge verify-contract \
            --chain-id $CHAIN_ID \
            --compiler-version $COMPILER_VERSION \
            --etherscan-api-key $ETHERSCAN_API_KEY \
            --watch \
            $address \
            $contract_path:$contract_name
    fi
    
    if [ $? -eq 0 ]; then
        echo "✅ $description verificado exitosamente"
    else
        echo "❌ Error verificando $description"
    fi
}

# Leer direcciones del JSON y verificar contratos

# 1. TOKENS
echo -e "\n🪙 VERIFICANDO TOKENS"
echo "==================="

# Mock ETH
MOCK_ETH=$(jq -r '.tokens.mockETH' $JSON_FILE)
if [ "$MOCK_ETH" != "null" ] && [ "$MOCK_ETH" != "" ]; then
    verify_contract "$MOCK_ETH" "src/mocks/MockETH.sol" "MockETH" "" "Mock ETH"
fi

# Mock WBTC
MOCK_WBTC=$(jq -r '.tokens.mockWBTC' $JSON_FILE)
if [ "$MOCK_WBTC" != "null" ] && [ "$MOCK_WBTC" != "" ]; then
    verify_contract "$MOCK_WBTC" "src/mocks/MockWBTC.sol" "MockWBTC" "" "Mock WBTC"
fi

# Mock USDC
MOCK_USDC=$(jq -r '.tokens.mockUSDC' $JSON_FILE)
if [ "$MOCK_USDC" != "null" ] && [ "$MOCK_USDC" != "" ]; then
    verify_contract "$MOCK_USDC" "src/mocks/MockUSDC.sol" "MockUSDC" "" "Mock USDC"
fi

# VCOP Token
VCOP_TOKEN=$(jq -r '.tokens.vcopToken' $JSON_FILE)
if [ "$VCOP_TOKEN" != "null" ] && [ "$VCOP_TOKEN" != "" ]; then
    verify_contract "$VCOP_TOKEN" "src/VcopCollateral/VCOPCollateralized.sol" "VCOPCollateralized" "" "VCOP Token"
fi

# 2. VCOP COLLATERAL
echo -e "\n🔒 VERIFICANDO VCOP COLLATERAL"
echo "============================="

# Mock VCOP Oracle
MOCK_VCOP_ORACLE=$(jq -r '.vcopCollateral.mockVcopOracle' $JSON_FILE)
if [ "$MOCK_VCOP_ORACLE" != "null" ] && [ "$MOCK_VCOP_ORACLE" != "" ]; then
    verify_contract "$MOCK_VCOP_ORACLE" "src/VcopCollateral/MockVCOPOracle.sol" "MockVCOPOracle" "" "Mock VCOP Oracle"
fi

# VCOP Price Calculator
VCOP_PRICE_CALC=$(jq -r '.vcopCollateral.vcopPriceCalculator' $JSON_FILE)
if [ "$VCOP_PRICE_CALC" != "null" ] && [ "$VCOP_PRICE_CALC" != "" ]; then
    verify_contract "$VCOP_PRICE_CALC" "src/VcopCollateral/VCOPPriceCalculator.sol" "VCOPPriceCalculator" "" "VCOP Price Calculator"
fi

# VCOP Collateral Manager
VCOP_COLLATERAL_MGR=$(jq -r '.vcopCollateral.vcopCollateralManager' $JSON_FILE)
if [ "$VCOP_COLLATERAL_MGR" != "null" ] && [ "$VCOP_COLLATERAL_MGR" != "" ]; then
    verify_contract "$VCOP_COLLATERAL_MGR" "src/VcopCollateral/VCOPCollateralManager.sol" "VCOPCollateralManager" "" "VCOP Collateral Manager"
fi

# VCOP Collateral Hook
VCOP_COLLATERAL_HOOK=$(jq -r '.vcopCollateral.vcopCollateralHook' $JSON_FILE)
if [ "$VCOP_COLLATERAL_HOOK" != "null" ] && [ "$VCOP_COLLATERAL_HOOK" != "" ]; then
    verify_contract "$VCOP_COLLATERAL_HOOK" "src/VcopCollateral/VCOPCollateralHook.sol" "VCOPCollateralHook" "" "VCOP Collateral Hook"
fi

# 3. CORE LENDING
echo -e "\n💰 VERIFICANDO CORE LENDING"
echo "=========================="

# Risk Calculator
RISK_CALC=$(jq -r '.coreLending.riskCalculator' $JSON_FILE)
if [ "$RISK_CALC" != "null" ] && [ "$RISK_CALC" != "" ]; then
    verify_contract "$RISK_CALC" "src/core/RiskCalculator.sol" "RiskCalculator" "" "Risk Calculator"
fi

# Generic Loan Manager
GENERIC_LOAN_MGR=$(jq -r '.coreLending.genericLoanManager' $JSON_FILE)
DEPLOYER=$(jq -r '.config.feeCollector' $JSON_FILE)
if [ "$GENERIC_LOAN_MGR" != "null" ] && [ "$GENERIC_LOAN_MGR" != "" ]; then
    CONSTRUCTOR_ARGS=$(cast abi-encode "constructor(address,address)" $DEPLOYER $DEPLOYER)
    verify_contract "$GENERIC_LOAN_MGR" "src/core/GenericLoanManager.sol" "GenericLoanManager" "$CONSTRUCTOR_ARGS" "Generic Loan Manager"
fi

# Flexible Loan Manager
FLEXIBLE_LOAN_MGR=$(jq -r '.coreLending.flexibleLoanManager' $JSON_FILE)
if [ "$FLEXIBLE_LOAN_MGR" != "null" ] && [ "$FLEXIBLE_LOAN_MGR" != "" ]; then
    CONSTRUCTOR_ARGS=$(cast abi-encode "constructor(address,address)" $DEPLOYER $DEPLOYER)
    verify_contract "$FLEXIBLE_LOAN_MGR" "src/core/FlexibleLoanManager.sol" "FlexibleLoanManager" "$CONSTRUCTOR_ARGS" "Flexible Loan Manager"
fi

# Mintable Burnable Handler
MINTABLE_HANDLER=$(jq -r '.coreLending.mintableBurnableHandler' $JSON_FILE)
if [ "$MINTABLE_HANDLER" != "null" ] && [ "$MINTABLE_HANDLER" != "" ]; then
    verify_contract "$MINTABLE_HANDLER" "src/core/MintableBurnableHandler.sol" "MintableBurnableHandler" "" "Mintable Burnable Handler"
fi

# Vault Based Handler
VAULT_HANDLER=$(jq -r '.coreLending.vaultBasedHandler' $JSON_FILE)
if [ "$VAULT_HANDLER" != "null" ] && [ "$VAULT_HANDLER" != "" ]; then
    verify_contract "$VAULT_HANDLER" "src/core/VaultBasedHandler.sol" "VaultBasedHandler" "" "Vault Based Handler"
fi

# Flexible Asset Handler
FLEXIBLE_HANDLER=$(jq -r '.coreLending.flexibleAssetHandler' $JSON_FILE)
if [ "$FLEXIBLE_HANDLER" != "null" ] && [ "$FLEXIBLE_HANDLER" != "" ]; then
    verify_contract "$FLEXIBLE_HANDLER" "src/core/FlexibleAssetHandler.sol" "FlexibleAssetHandler" "" "Flexible Asset Handler"
fi

# Dynamic Price Registry
DYNAMIC_PRICE=$(jq -r '.coreLending.dynamicPriceRegistry' $JSON_FILE)
if [ "$DYNAMIC_PRICE" != "null" ] && [ "$DYNAMIC_PRICE" != "" ]; then
    verify_contract "$DYNAMIC_PRICE" "src/core/DynamicPriceRegistry.sol" "DynamicPriceRegistry" "" "Dynamic Price Registry"
fi

# 4. AUTOMATION (si existen)
echo -e "\n🤖 VERIFICANDO AUTOMATION"
echo "========================"

# Automation Registry
AUTO_REGISTRY=$(jq -r '.automation.automationRegistry' $JSON_FILE)
if [ "$AUTO_REGISTRY" != "null" ] && [ "$AUTO_REGISTRY" != "" ]; then
    echo "⚠️  Automation Registry encontrado: $AUTO_REGISTRY"
    echo "   (Contrato de Chainlink - no se puede verificar directamente)"
fi

# Automation Keeper
AUTO_KEEPER=$(jq -r '.automation.automationKeeper' $JSON_FILE)
if [ "$AUTO_KEEPER" != "null" ] && [ "$AUTO_KEEPER" != "" ]; then
    echo "⚠️  Automation Keeper encontrado: $AUTO_KEEPER"
    echo "   (Buscar contrato correspondiente en src/automation/)"
fi

# Loan Adapter
LOAN_ADAPTER=$(jq -r '.automation.loanAdapter' $JSON_FILE)
if [ "$LOAN_ADAPTER" != "null" ] && [ "$LOAN_ADAPTER" != "" ]; then
    echo "⚠️  Loan Adapter encontrado: $LOAN_ADAPTER"
    echo "   (Buscar contrato correspondiente en src/automation/)"
fi

# Price Trigger
PRICE_TRIGGER=$(jq -r '.automation.priceTrigger' $JSON_FILE)
if [ "$PRICE_TRIGGER" != "null" ] && [ "$PRICE_TRIGGER" != "" ]; then
    echo "⚠️  Price Trigger encontrado: $PRICE_TRIGGER"
    echo "   (Buscar contrato correspondiente en src/automation/)"
fi

echo -e "\n🎉 VERIFICACIÓN COMPLETADA"
echo "=========================="
echo "Revisa los resultados arriba para ver qué contratos se verificaron exitosamente."
echo ""
echo "📋 ENLACES DE VERIFICACIÓN:"

# Generar enlaces dinámicamente
if [ "$CHAIN_ID" = "84532" ]; then
    BASE_URL="https://sepolia.basescan.org/address"
elif [ "$CHAIN_ID" = "8453" ]; then
    BASE_URL="https://basescan.org/address"
else
    BASE_URL="https://etherscan.io/address"
fi

echo "Tokens:"
[ "$MOCK_ETH" != "null" ] && echo "  Mock ETH: $BASE_URL/$MOCK_ETH"
[ "$MOCK_WBTC" != "null" ] && echo "  Mock WBTC: $BASE_URL/$MOCK_WBTC"
[ "$MOCK_USDC" != "null" ] && echo "  Mock USDC: $BASE_URL/$MOCK_USDC"
[ "$VCOP_TOKEN" != "null" ] && echo "  VCOP Token: $BASE_URL/$VCOP_TOKEN"

echo "VCOP Collateral:"
[ "$MOCK_VCOP_ORACLE" != "null" ] && echo "  Mock Oracle: $BASE_URL/$MOCK_VCOP_ORACLE"
[ "$VCOP_PRICE_CALC" != "null" ] && echo "  Price Calculator: $BASE_URL/$VCOP_PRICE_CALC"
[ "$VCOP_COLLATERAL_MGR" != "null" ] && echo "  Collateral Manager: $BASE_URL/$VCOP_COLLATERAL_MGR"
[ "$VCOP_COLLATERAL_HOOK" != "null" ] && echo "  Collateral Hook: $BASE_URL/$VCOP_COLLATERAL_HOOK"

echo "Core Lending:"
[ "$RISK_CALC" != "null" ] && echo "  Risk Calculator: $BASE_URL/$RISK_CALC"
[ "$GENERIC_LOAN_MGR" != "null" ] && echo "  Generic Loan Manager: $BASE_URL/$GENERIC_LOAN_MGR"
[ "$FLEXIBLE_LOAN_MGR" != "null" ] && echo "  Flexible Loan Manager: $BASE_URL/$FLEXIBLE_LOAN_MGR"
[ "$MINTABLE_HANDLER" != "null" ] && echo "  Mintable Handler: $BASE_URL/$MINTABLE_HANDLER"
[ "$VAULT_HANDLER" != "null" ] && echo "  Vault Handler: $BASE_URL/$VAULT_HANDLER"
[ "$FLEXIBLE_HANDLER" != "null" ] && echo "  Flexible Handler: $BASE_URL/$FLEXIBLE_HANDLER"
[ "$DYNAMIC_PRICE" != "null" ] && echo "  Dynamic Price: $BASE_URL/$DYNAMIC_PRICE" 