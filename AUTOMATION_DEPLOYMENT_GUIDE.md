# GUIA DE DEPLOYMENT DE AUTOMATIZACION CHAINLINK

## RESUMEN EJECUTIVO

Se ha creado un sistema completo de deployment y configuracion de Chainlink Automation que lee automaticamente las direcciones del archivo `deployed-addresses.json` y configura el sistema de automatizacion para trabajar con los contratos existentes.

## COMANDO PRINCIPAL

```bash
make deploy-automation
```

Este comando debe ejecutarse DESPUES de `make deploy-complete` para agregar capacidades de automatizacion al sistema existente.

## QUE HACE EL COMANDO

### Paso 1: Deploy de Contratos de Automatizacion
- Lee direcciones desde `deployed-addresses.json`
- Deploya `AutomationRegistry`
- Deploya `LoanAutomationKeeper`
- Usa el `RiskCalculator` existente (no deploya uno nuevo)

### Paso 2: Configuracion del Sistema
- Configura `GenericLoanManager` para automatizacion
- Registra loan managers en el automation registry
- Establece thresholds de riesgo y batch sizes

### Paso 3: Generacion de CheckData
- Genera el checkData necesario para registro en Chainlink
- Muestra instrucciones para completar la configuracion

## CONTRATOS CREADOS

### AutomationRegistry
- Gestiona el registro de loan managers
- Coordina la automatizacion entre contratos

### LoanAutomationKeeper
- Implementa `AutomationCompatibleInterface` oficial
- Compatible 100% con Chainlink Automation v2.25.0
- Monitorea posiciones de riesgo
- Ejecuta liquidaciones automaticas

### ConfigureAutomationSystem
- Script de configuracion que conecta contratos existentes
- Maneja tanto GenericLoanManager como FlexibleLoanManager
- Configuracion graceful (no falla si funciones no existen)

## DIRECCIONES LEIDAS AUTOMATICAMENTE

El sistema lee estas direcciones del `deployed-addresses.json`:

```json
{
  "vcopCollateral": {
    "oracle": "0xe841B02F7d05CEEFcBae0778a814a86cC501543f"
  },
  "coreLending": {
    "genericLoanManager": "0x4FB21751f02D47eF2F4F6b1c8dC202e2D8d6aa31",
    "flexibleLoanManager": "0x450c9287446F9eDb58a7DBf0BA404b484A5b0515",
    "riskCalculator": "0x21edf183924bA81e9B41505BD77a6533BFA1b77A"
  }
}
```

## CONFIGURACION APLICADA

### GenericLoanManager
- Automation contract: Se setea a la direccion del LoanAutomationKeeper
- Automation enabled: true
- Risk threshold: 85%
- Batch size: 50 loans

### FlexibleLoanManager
- Se intenta configurar de manera graceful
- Si no tiene interface de automatizacion, se omite sin error

## PASOS SIGUIENTES

Despues de ejecutar `make deploy-automation`, debes:

1. **Ir a https://automation.chain.link/**
2. **Conectar wallet y seleccionar red**
3. **Crear Custom Logic Upkeep con:**
   - Contract Address: La direccion del LoanAutomationKeeper
   - Gas Limit: 2,000,000
   - Funding: 5-10 LINK tokens
4. **Usar el CheckData generado por el script**
5. **Monitorear en el dashboard de Chainlink**

## COMANDOS ADICIONALES

### Generar CheckData adicional
```bash
make generate-checkdata
```

### Verificar deployment
```bash
make check-deployment-status
```

## ESTRUCTURA DE ARCHIVOS CREADOS

```
script/automation/
├── DeployAutomation.s.sol          # Script principal de deploy
├── ConfigureAutomationSystem.s.sol  # Configuracion de contratos existentes

src/automation/
├── core/
│   ├── AutomationRegistry.sol       # Registro de automatizacion
│   ├── LoanAutomationKeeper.sol     # Keeper principal (Custom Logic)
│   ├── PriceChangeLogTrigger.sol    # Log trigger para cambios de precio
│   └── LoanManagerAutomationAdapter.sol # Adapter para contratos legacy
├── interfaces/
│   ├── ILoanAutomation.sol
│   └── IAutomationRegistry.sol
└── README.md
```

## COMPATIBILIDAD CHAINLINK

- Chainlink Contracts v2.25.0 instalado
- AutomationCompatibleInterface oficial
- ILogAutomation oficial  
- Estructuras Log oficiales
- Compatible con Custom Logic y Log Triggers

## WORKFLOW COMPLETO

```bash
# 1. Deploy sistema principal
make deploy-complete

# 2. Deploy automatizacion
make deploy-automation

# 3. Registrar en Chainlink (manual)
# Usar checkData generado

# 4. Verificar funcionamiento
make test-chainlink
```

## NOTAS IMPORTANTES

- El sistema usa contratos existentes, no duplica funcionalidad
- Configuracion graceful que no rompe si funciones no existen
- Totalmente compatible con documentacion oficial de Chainlink
- Sin iconos en ningun output para compatibilidad con sistemas CI/CD 