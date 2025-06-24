#!/bin/bash

# Script para mostrar todas las direcciones desplegadas desde el JSON
JSON_FILE="${JSON_FILE:-deployed-addresses-mock.json}"

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

echo "📋 DIRECCIONES DESPLEGADAS - $JSON_FILE"
echo "========================================"

# Oracle Type
ORACLE_TYPE=$(jq -r '.oracleType' $JSON_FILE)
echo "🔮 Oracle Type: $ORACLE_TYPE"
echo ""

# Tokens
echo "🪙 TOKENS:"
echo "----------"
jq -r '.tokens | to_entries[] | "  \(.key): \(.value)"' $JSON_FILE
echo ""

# VCOP Collateral
echo "🔒 VCOP COLLATERAL:"
echo "-------------------"
jq -r '.vcopCollateral | to_entries[] | "  \(.key): \(.value)"' $JSON_FILE
echo ""

# Core Lending
echo "💰 CORE LENDING:"
echo "----------------"
jq -r '.coreLending | to_entries[] | "  \(.key): \(.value)"' $JSON_FILE
echo ""

# Configuration
echo "⚙️  CONFIGURATION:"
echo "------------------"
jq -r '.config | to_entries[] | "  \(.key): \(.value)"' $JSON_FILE
echo ""

# Automation
echo "🤖 AUTOMATION:"
echo "---------------"
jq -r '.automation | to_entries[] | "  \(.key): \(.value)"' $JSON_FILE
echo ""

# Totals
TOTAL_TOKENS=$(jq '.tokens | length' $JSON_FILE)
TOTAL_VCOP=$(jq '.vcopCollateral | length' $JSON_FILE)
TOTAL_CORE=$(jq '.coreLending | length' $JSON_FILE)
TOTAL_CONFIG=$(jq '.config | length' $JSON_FILE)
TOTAL_AUTO=$(jq '.automation | length' $JSON_FILE)
TOTAL_ALL=$((TOTAL_TOKENS + TOTAL_VCOP + TOTAL_CORE + TOTAL_CONFIG + TOTAL_AUTO))

echo "📊 RESUMEN:"
echo "-----------"
echo "  Tokens: $TOTAL_TOKENS contratos"
echo "  VCOP Collateral: $TOTAL_VCOP contratos"
echo "  Core Lending: $TOTAL_CORE contratos"
echo "  Configuration: $TOTAL_CONFIG items"
echo "  Automation: $TOTAL_AUTO contratos"
echo "  TOTAL: $TOTAL_ALL items"

# Verificar direcciones válidas (no null o vacías)
echo ""
echo "🔍 VERIFICACIÓN DE DIRECCIONES:"
echo "-------------------------------"

# Función para verificar una sección
check_section() {
    local section=$1
    local section_name=$2
    
    echo "  $section_name:"
    jq -r ".$section | to_entries[] | \"\(.key):\(.value)\"" $JSON_FILE | while IFS=':' read -r key value; do
        if [ "$value" = "null" ] || [ -z "$value" ]; then
            echo "    ❌ $key: VACÍO/NULL"
        elif [[ $value =~ ^0x[a-fA-F0-9]{40}$ ]]; then
            echo "    ✅ $key: VÁLIDO"
        else
            echo "    ⚠️  $key: FORMATO INVÁLIDO ($value)"
        fi
    done
}

check_section "tokens" "Tokens          "
check_section "vcopCollateral" "VCOP Collateral "
check_section "coreLending" "Core Lending    "
check_section "automation" "Automation      "

echo ""
echo "✨ Para verificar todos los contratos, ejecuta:"
echo "   make verify-all-contracts" 