#!/bin/bash

# Script para actualizar deployed-addresses.json con las direcciones de automatización
# Este script actualiza con contratos propios + direcciones oficiales de Chainlink

echo "ACTUALIZANDO deployed-addresses.json CON DIRECCIONES DE AUTOMATIZACIÓN..."
echo "================================================================"

# Verificar que existe el archivo JSON
if [ ! -f "deployed-addresses.json" ]; then
    echo "❌ ERROR: deployed-addresses.json no encontrado!"
    echo "Ejecuta 'make deploy-complete' primero"
    exit 1
fi

# Buscar las direcciones en el log más reciente
LOG_FILE=$(find broadcast -name "run-latest.json" | grep DeployAutomationProduction | head -1)

if [ ! -f "$LOG_FILE" ]; then
    echo "ERROR: No se encontró el archivo de log de despliegue de automatización"
    echo "Ejecuta 'make deploy-automation' primero"
    exit 1
fi

echo "Leyendo direcciones del log: $LOG_FILE"

# Direcciones oficiales de Chainlink (Base Sepolia)
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
cp deployed-addresses.json deployed-addresses.json.backup

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
   }' deployed-addresses.json > deployed-addresses-temp.json

# Verificar que el JSON es válido
if jq empty deployed-addresses-temp.json; then
    mv deployed-addresses-temp.json deployed-addresses.json
    echo ""
    echo "deployed-addresses.json ACTUALIZADO EXITOSAMENTE!"
    echo "=================================================="
    echo ""
    echo "Nueva sección de automatización agregada:"
    jq .automation deployed-addresses.json
    echo ""
    echo "Backup guardado como: deployed-addresses.json.backup"
    echo "Sistema listo para usar Chainlink Automation oficial"
else
    echo "ERROR: JSON resultante no es válido"
    rm deployed-addresses-temp.json
    exit 1
fi 