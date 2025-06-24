#!/bin/bash

# Script para verificación dinámica de todos los contratos desplegados
# Versión mejorada con argumentos de constructor correctos

# Configuración
JSON_FILE="${JSON_FILE:-deployed-addresses-mock.json}"
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

echo "🚀 Verificando contratos dinámicamente desde $JSON_FILE (VERSION MEJORADA)"
echo "Chain ID: $CHAIN_ID"
echo "Compiler: $COMPILER_VERSION"
echo "=================================================="

# Función para verificar un contrato
verify_contract() {
    local address=$1
    local contract_path=$2
    local constructor_args=$3
    local description=$4
    
    echo ""
    echo "📋 Verificando $description..."
    echo "   Dirección: $address"
    echo "   Contrato: $contract_path"
    if [ -n "$constructor_args" ]; then
        echo "   Constructor Args: $constructor_args"
    fi
    
    if [ -n "$constructor_args" ]; then
        forge verify-contract "$address" "$contract_path" \
            --chain-id "$CHAIN_ID" \
            --compiler-version "$COMPILER_VERSION" \
            --constructor-args "$constructor_args"
    else
        forge verify-contract "$address" "$contract_path" \
            --chain-id "$CHAIN_ID" \
            --compiler-version "$COMPILER_VERSION"
    fi
    
    if [ $? -eq 0 ]; then
        echo "✅ $description verificado exitosamente"
    else
        echo "❌ Error verificando $description"
    fi
}

# Leer direcciones del JSON
MOCK_ETH=$(jq -r '.tokens.mockETH' $JSON_FILE)
MOCK_WBTC=$(jq -r '.tokens.mockWBTC' $JSON_FILE)
MOCK_USDC=$(jq -r '.tokens.mockUSDC' $JSON_FILE)
VCOP_TOKEN=$(jq -r '.tokens.vcopToken' $JSON_FILE)

MOCK_ORACLE=$(jq -r '.vcopCollateral.mockVcopOracle' $JSON_FILE)
PRICE_CALC=$(jq -r '.vcopCollateral.vcopPriceCalculator' $JSON_FILE)
COLLATERAL_MGR=$(jq -r '.vcopCollateral.vcopCollateralManager' $JSON_FILE)
COLLATERAL_HOOK=$(jq -r '.vcopCollateral.vcopCollateralHook' $JSON_FILE)

RISK_CALC=$(jq -r '.coreLending.riskCalculator' $JSON_FILE)
GENERIC_LOAN=$(jq -r '.coreLending.genericLoanManager' $JSON_FILE)
FLEXIBLE_LOAN=$(jq -r '.coreLending.flexibleLoanManager' $JSON_FILE)
MINTABLE_HANDLER=$(jq -r '.coreLending.mintableBurnableHandler' $JSON_FILE)
VAULT_HANDLER=$(jq -r '.coreLending.vaultBasedHandler' $JSON_FILE)
FLEXIBLE_HANDLER=$(jq -r '.coreLending.flexibleAssetHandler' $JSON_FILE)
PRICE_REGISTRY=$(jq -r '.coreLending.dynamicPriceRegistry' $JSON_FILE)

POOL_MANAGER=$(jq -r '.config.poolManager' $JSON_FILE)
USD_COP_RATE=$(jq -r '.config.usdToCopRate' $JSON_FILE)

# Constantes del sistema
FEE_COLLECTOR="0xa6b3d200cd34ca14d7579dac8b054bf50a62c37c"
POOL_FEE="3000"
TICK_SPACING="60"

echo ""
echo "🪙 VERIFICANDO TOKENS"
echo "==================="

verify_contract "$MOCK_ETH" "src/mocks/MockETH.sol:MockETH" "" "Mock ETH"
verify_contract "$MOCK_WBTC" "src/mocks/MockWBTC.sol:MockWBTC" "" "Mock WBTC"
verify_contract "$MOCK_USDC" "src/mocks/MockUSDC.sol:MockUSDC" "" "Mock USDC"
verify_contract "$VCOP_TOKEN" "src/VcopCollateral/VCOPCollateralized.sol:VCOPCollateralized" "" "VCOP Token"

echo ""
echo "🔒 VERIFICANDO VCOP COLLATERAL"
echo "============================="

# Mock Oracle: MockVCOPOracle(vcopToken, mockUSDC)
MOCK_ORACLE_ARGS=$(cast abi-encode "constructor(address,address)" "$VCOP_TOKEN" "$MOCK_USDC")
verify_contract "$MOCK_ORACLE" "src/VcopCollateral/MockVCOPOracle.sol:MockVCOPOracle" "$MOCK_ORACLE_ARGS" "Mock VCOP Oracle"

# Price Calculator: VCOPPriceCalculator(poolManager, vcopToken, mockUSDC, fee, tickSpacing, hookAddress, usdToCopRate)
# IMPORTANTE: En el despliegue se usa address(0) inicialmente y después se actualiza
PRICE_CALC_ARGS=$(cast abi-encode "constructor(address,address,address,uint24,int24,address,uint256)" \
    "$POOL_MANAGER" "$VCOP_TOKEN" "$MOCK_USDC" "$POOL_FEE" "$TICK_SPACING" "0x0000000000000000000000000000000000000000" "$USD_COP_RATE")
verify_contract "$PRICE_CALC" "src/VcopCollateral/VCOPPriceCalculator.sol:VCOPPriceCalculator" "$PRICE_CALC_ARGS" "VCOP Price Calculator"

# Collateral Manager: VCOPCollateralManager(vcopToken, mockOracle)
COLLATERAL_MGR_ARGS=$(cast abi-encode "constructor(address,address)" "$VCOP_TOKEN" "$MOCK_ORACLE")
verify_contract "$COLLATERAL_MGR" "src/VcopCollateral/VCOPCollateralManager.sol:VCOPCollateralManager" "$COLLATERAL_MGR_ARGS" "VCOP Collateral Manager"

# Collateral Hook: VCOPCollateralHook(poolManager, collateralManager, oracle, vcop, usdc, treasury, owner)
# Usar FEE_COLLECTOR como treasury y owner (deployer)
COLLATERAL_HOOK_ARGS=$(cast abi-encode "constructor(address,address,address,address,address,address,address)" \
    "$POOL_MANAGER" "$COLLATERAL_MGR" "$MOCK_ORACLE" "$VCOP_TOKEN" "$MOCK_USDC" "$FEE_COLLECTOR" "$FEE_COLLECTOR")
verify_contract "$COLLATERAL_HOOK" "src/VcopCollateral/VCOPCollateralHook.sol:VCOPCollateralHook" "$COLLATERAL_HOOK_ARGS" "VCOP Collateral Hook"

echo ""
echo "💰 VERIFICANDO CORE LENDING"
echo "=========================="

# Risk Calculator: RiskCalculator(oracle, loanManager)
# NOTA: En el despliegue se crea ANTES del loan manager, así que puede usar address(0) o genericLoanManager
RISK_CALC_ARGS=$(cast abi-encode "constructor(address,address)" "$MOCK_ORACLE" "$GENERIC_LOAN")
verify_contract "$RISK_CALC" "src/core/RiskCalculator.sol:RiskCalculator" "$RISK_CALC_ARGS" "Risk Calculator"

# Generic Loan Manager: GenericLoanManager(oracle, feeCollector)
GENERIC_LOAN_ARGS=$(cast abi-encode "constructor(address,address)" "$MOCK_ORACLE" "$FEE_COLLECTOR")
verify_contract "$GENERIC_LOAN" "src/core/GenericLoanManager.sol:GenericLoanManager" "$GENERIC_LOAN_ARGS" "Generic Loan Manager"

# Flexible Loan Manager: FlexibleLoanManager(oracle, feeCollector)
FLEXIBLE_LOAN_ARGS=$(cast abi-encode "constructor(address,address)" "$MOCK_ORACLE" "$FEE_COLLECTOR")
verify_contract "$FLEXIBLE_LOAN" "src/core/FlexibleLoanManager.sol:FlexibleLoanManager" "$FLEXIBLE_LOAN_ARGS" "Flexible Loan Manager"

# Dynamic Price Registry: DynamicPriceRegistry(oracle)
PRICE_REGISTRY_ARGS=$(cast abi-encode "constructor(address)" "$MOCK_ORACLE")
verify_contract "$PRICE_REGISTRY" "src/core/DynamicPriceRegistry.sol:DynamicPriceRegistry" "$PRICE_REGISTRY_ARGS" "Dynamic Price Registry"

# Asset Handlers (sin constructor args)
verify_contract "$MINTABLE_HANDLER" "src/core/MintableBurnableHandler.sol:MintableBurnableHandler" "" "Mintable Burnable Handler"
verify_contract "$VAULT_HANDLER" "src/core/VaultBasedHandler.sol:VaultBasedHandler" "" "Vault Based Handler"
verify_contract "$FLEXIBLE_HANDLER" "src/core/FlexibleAssetHandler.sol:FlexibleAssetHandler" "" "Flexible Asset Handler"

echo ""
echo "🤖 VERIFICANDO AUTOMATION"
echo "========================"
# Automation contracts son de Chainlink, no se pueden verificar directamente
echo "⚠️  Automation Registry encontrado: $(jq -r '.automation.automationRegistry // "N/A"' $JSON_FILE)"
echo "   (Contrato de Chainlink - no se puede verificar directamente)"
echo "⚠️  Automation Keeper encontrado: $(jq -r '.automation.automationKeeper // "N/A"' $JSON_FILE)"
echo "   (Buscar contrato correspondiente en src/automation/)"
echo "⚠️  Loan Adapter encontrado: $(jq -r '.automation.loanAdapter // "N/A"' $JSON_FILE)"
echo "   (Buscar contrato correspondiente en src/automation/)"
echo "⚠️  Price Trigger encontrado: $(jq -r '.automation.priceTrigger // "N/A"' $JSON_FILE)"
echo "   (Buscar contrato correspondiente en src/automation/)"

echo ""
echo "🎉 VERIFICACIÓN COMPLETADA (VERSIÓN MEJORADA v2)"
echo "==============================================="
echo "Revisa los resultados arriba para ver qué contratos se verificaron exitosamente."

echo ""
echo "📋 ENLACES DE VERIFICACIÓN:"
echo "Tokens:"
echo "  Mock ETH: https://sepolia.basescan.org/address/$MOCK_ETH"
echo "  Mock WBTC: https://sepolia.basescan.org/address/$MOCK_WBTC"
echo "  Mock USDC: https://sepolia.basescan.org/address/$MOCK_USDC"
echo "  VCOP Token: https://sepolia.basescan.org/address/$VCOP_TOKEN"
echo "VCOP Collateral:"
echo "  Mock Oracle: https://sepolia.basescan.org/address/$MOCK_ORACLE"
echo "  Price Calculator: https://sepolia.basescan.org/address/$PRICE_CALC"
echo "  Collateral Manager: https://sepolia.basescan.org/address/$COLLATERAL_MGR"
echo "  Collateral Hook: https://sepolia.basescan.org/address/$COLLATERAL_HOOK"
echo "Core Lending:"
echo "  Risk Calculator: https://sepolia.basescan.org/address/$RISK_CALC"
echo "  Generic Loan Manager: https://sepolia.basescan.org/address/$GENERIC_LOAN"
echo "  Flexible Loan Manager: https://sepolia.basescan.org/address/$FLEXIBLE_LOAN"
echo "  Mintable Handler: https://sepolia.basescan.org/address/$MINTABLE_HANDLER"
echo "  Vault Handler: https://sepolia.basescan.org/address/$VAULT_HANDLER"
echo "  Flexible Handler: https://sepolia.basescan.org/address/$FLEXIBLE_HANDLER"
echo "  Dynamic Price: https://sepolia.basescan.org/address/$PRICE_REGISTRY" 