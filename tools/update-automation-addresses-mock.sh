#!/bin/bash

# Script para actualizar deployed-addresses-mock.json con las direcciones de automatización
# Este script lee las direcciones del output del script de despliegue y actualiza el JSON

echo "🔧 ACTUALIZANDO deployed-addresses-mock.json CON DIRECCIONES DE AUTOMATIZACIÓN..."
echo "================================================================"

# Verificar que existe el archivo JSON
if [ ! -f "deployed-addresses-mock.json" ]; then
    echo "❌ ERROR: deployed-addresses-mock.json no encontrado!"
    echo "Ejecuta 'make deploy-complete-mock' primero"
    exit 1
fi

# Buscar las direcciones en el log más reciente
LOG_FILE=$(find broadcast -name "run-latest.json" | grep DeployAutomationMock | head -1)

if [ ! -f "$LOG_FILE" ]; then
    echo "❌ ERROR: No se encontró el archivo de log de despliegue de automatización"
    echo "Ejecuta 'make deploy-automation-mock' primero"
    exit 1
fi

echo "📋 Leyendo direcciones del log: $LOG_FILE"

# Direcciones oficiales de Chainlink (Base Sepolia) - mismo que producción
AUTOMATION_REGISTRY="0x91D4a4C3D448c7f3CB477332B1c7D420a5810aC3"

# Extraer direcciones propias del broadcast
AUTOMATION_KEEPER=$(jq -r '.transactions[] | select(.contractName == "LoanAutomationKeeperOptimized") | .contractAddress' "$LOG_FILE" | head -1)
LOAN_ADAPTER=$(jq -r '.transactions[] | select(.contractName == "LoanManagerAutomationAdapter") | .contractAddress' "$LOG_FILE" | head -1)
PRICE_TRIGGER=$(jq -r '.transactions[] | select(.contractName == "PriceChangeLogTrigger") | .contractAddress' "$LOG_FILE" | head -1)

echo "Direcciones encontradas:"
echo "  AutomationRegistry (Chainlink Oficial): $AUTOMATION_REGISTRY"
echo "  LoanAutomationKeeper: $AUTOMATION_KEEPER"
echo "  LoanManagerAutomationAdapter: $LOAN_ADAPTER"
echo "  PriceChangeLogTrigger: $PRICE_TRIGGER"

# Verificar que todas las direcciones están presentes
if [[ -z "$AUTOMATION_REGISTRY" || -z "$AUTOMATION_KEEPER" || -z "$LOAN_ADAPTER" || -z "$PRICE_TRIGGER" ]]; then
    echo "ERROR: No se pudieron extraer todas las direcciones del log"
    exit 1
fi

# Crear backup del JSON original
cp deployed-addresses-mock.json deployed-addresses-mock.json.backup

# Actualizar el JSON agregando la sección de automatización
jq --arg registry "$AUTOMATION_REGISTRY" \
   --arg keeper "$AUTOMATION_KEEPER" \
   --arg adapter "$LOAN_ADAPTER" \
   --arg trigger "$PRICE_TRIGGER" \
   '. + {
     "automation": {
       "automationRegistry": $registry,
       "automationKeeper": $keeper,
       "loanAdapter": $adapter,
       "priceTrigger": $trigger
     }
   }' deployed-addresses-mock.json > deployed-addresses-mock-temp.json

# Verificar que el JSON es válido
if jq empty deployed-addresses-mock-temp.json; then
    mv deployed-addresses-mock-temp.json deployed-addresses-mock.json
    echo ""
    echo "✅ deployed-addresses-mock.json ACTUALIZADO EXITOSAMENTE!"
    echo "=================================================="
    echo ""
    echo "📋 Nueva sección de automatización agregada:"
    jq .automation deployed-addresses-mock.json
    echo ""
    echo "💾 Backup guardado como: deployed-addresses-mock.json.backup"
    echo "🚀 Ahora puedes usar la automatización con el sistema mock para pruebas de liquidación"
else
    echo "❌ ERROR: JSON resultante no es válido"
    rm deployed-addresses-mock-temp.json
    exit 1
fi 