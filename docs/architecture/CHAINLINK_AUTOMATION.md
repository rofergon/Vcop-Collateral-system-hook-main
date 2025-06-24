# 🤖 Advanced Chainlink Automation System

## 🚀 Overview

Complete automation system using **Chainlink Automation v2.25.0** with support for `FlexibleLoanManager`, `DynamicPriceRegistry` and intelligent automated liquidations. The system implements both **Custom Logic Automation** and **Log Trigger Automation** for maximum efficiency.

## 🏗️ System Architecture

### Main Components

### 1. **LoanAutomationKeeperOptimized** ⚡ 
**Function**: Main Keeper (Custom Logic Automation)
- **Location**: `src/automation/core/LoanAutomationKeeperOptimized.sol`
- **Purpose**: Executes liquidations based on custom logic
- **Features**:
  - Extends `AutomationCompatible` (automatic UI detection)
  - Internal registration of loan managers with priorities
  - Gas-optimized batch processing
  - Risk level prioritization
  - Cooldown between liquidations
  - Integrated performance metrics

### 2. **LoanManagerAutomationAdapter** 🔗
**Function**: Adapter for FlexibleLoanManager
- **Location**: `src/automation/core/LoanManagerAutomationAdapter.sol`
- **Purpose**: Interface between automation and lending protocol
- **Features**:
  - Implements `ILoanAutomation` interface
  - Efficient tracking of active positions
  - Dynamic risk assessment
  - Direct integration with `FlexibleLoanManager`

### 3. **PriceChangeLogTrigger** 📈
**Function**: Price event-based trigger (Log Automation)
- **Location**: `src/automation/core/PriceChangeLogTrigger.sol`
- **Purpose**: Immediate response to price changes
- **Features**:
  - Uses official Chainlink `ILogAutomation` interface
  - Internal registration of loan managers with priorities
  - Real-time volatility detection
  - Multiple urgency levels (4 levels)
  - Temporary volatility mode
  - Direct integration with `DynamicPriceRegistry`

## 🔄 Detailed Workflow

### Technical System Analysis

The automation system implements two types of Chainlink v2.25.0 triggers:

1. **Custom Logic Automation**: Scheduled cyclic execution to verify positions
2. **Log Trigger Automation**: Reactive execution based on price events

#### Current System Architecture

The current system works as follows:

- **LoanAutomationKeeperOptimized**: Manages its own registry of loan managers with `registeredManagers` and `managersList`
- **PriceChangeLogTrigger**: Maintains its own list of loan managers with `registeredLoanManagers` and `loanManagersList`  
- **LoanManagerAutomationAdapter**: Implements `ILoanAutomation` and connects directly with `FlexibleLoanManager`
- **Official Interfaces**: Uses `AutomationCompatible` and `ILogAutomation` from Chainlink v2.25.0

### Custom Logic Automation Cycle

**Scheduled Execution Flow:**

1. **Activation**: Chainlink node executes `checkUpkeep()` at configured intervals
2. **Manager Query**: LoanKeeper obtains the list of registered loan managers
3. **Position Retrieval**: LoanAdapter queries active positions in the specified range
4. **Risk Assessment**: Calculates risk level for each individual position
5. **Decision Making**:
   - **Liquidatable positions found**: Orders by risk level (highest first) and executes liquidations in batches
   - **No liquidatable positions**: Completes the cycle and waits for the next scheduled interval

### Log Trigger Automation Cycle

**Price Event Response Flow:**

1. **Event Emission**: DynamicPriceRegistry emits `TokenPriceUpdated` event when price changes
2. **Automatic Detection**: Chainlink node detects the event log immediately
3. **Event Analysis**: PriceChangeLogTrigger executes `checkLog()` to decode and analyze the change
4. **Impact Assessment**: Compares percentage change against configured thresholds (5%, 7.5%, 10%, 15%)
5. **Action Execution**:
   - **Significant change detected**: Determines urgency level and executes risk-prioritized liquidations
   - **Change within normal range**: Logs the event but does not execute liquidations

### Technical Implementation Details

#### 1. **LoanAutomationKeeperOptimized** - Code Analysis

```solidity
// 📍 src/automation/core/LoanAutomationKeeperOptimized.sol
contract LoanAutomationKeeperOptimized is AutomationCompatible, Ownable {
    
    // ✅ Extends AutomationCompatible (not just interface) for automatic UI detection
    // ✅ Internal registry of loan managers with priority system
    // ✅ Implements gas-optimized batching logic
    // ✅ Risk-based prioritization system
```

**Key Features**:
- **Smart Batching**: Processes up to 200 positions per execution
- **Risk Ordering**: Prioritizes positions with higher risk
- **Gas Optimization**: Reserves gas for completion and prevents out-of-gas
- **Cooldown System**: Prevents liquidation spam
- **Real-time Metrics**: Performance tracking and statistics

#### 2. **PriceChangeLogTrigger** - Event Response

```solidity
// 📍 src/automation/core/PriceChangeLogTrigger.sol  
contract PriceChangeLogTrigger is ILogAutomation, Ownable {
    
    // ✅ Uses official ILogAutomation interface v2.25.0
    // ✅ Multi-level volatility detection
    // ✅ Temporary volatility mode (1 hour default)
    // ✅ Dynamic liquidation strategies
```

**Technical Features**:
- **Multi-tier Thresholds**: 4 urgency levels (5%, 7.5%, 10%, 15%)
- **Volatility Mode**: Automatic activation with adjustable parameters
- **Price Decoding**: Support for multiple event formats
- **Asset Filtering**: Selective liquidation by affected asset

#### 3. **LoanManagerAutomationAdapter** - Smart Interface

```solidity
// 📍 src/automation/core/LoanManagerAutomationAdapter.sol
contract LoanManagerAutomationAdapter is ILoanAutomation, Ownable {
    
    // ✅ Implements complete ILoanAutomation interface
    // ✅ Efficient active position tracking  
    // ✅ Direct integration with FlexibleLoanManager
    // ✅ Dynamic risk assessment system
```

**Advanced Features**:
- **Position Tracking**: Optimized array for efficient iteration
- **Risk Assessment**: Calculates risk based on `canLiquidate()` and collateralization ratio
- **Auto-sync**: Automatic cleanup of closed positions
- **Performance Metrics**: Success rate and liquidation statistics

#### 4. **Integration and Data Flow**

**Dual Automation System:**

### **A. Price Event Automation (Log Trigger)**

**Execution Sequence:**
```
1. DynamicPriceRegistry emits TokenPriceUpdated event
2. Chainlink node detects the log automatically
3. PriceChangeLogTrigger.checkLog() decodes the event
4. System evaluates if the change exceeds configured thresholds
5. DECISION:
   - Change ≥ 5%: Execute basic liquidations
   - Change ≥ 7.5%: Activate urgent mode
   - Change ≥ 10%: Immediate liquidations
   - Change ≥ 15%: Critical mode + temporary volatility
   - Change < 5%: Log but take no action
```

### **B. Scheduled Logic Automation (Custom Logic)**

**Verification Cycle:**
```
1. Chainlink node executes checkUpkeep() according to schedule
2. LoanKeeper queries registered loan managers
3. LoanAdapter obtains active positions in specified range
4. System calculates individual risk per position
5. DECISION:
   - Risk ≥ 95%: Immediate critical liquidation
   - Risk ≥ 85%: High priority liquidation  
   - Risk ≥ 75%: Standard liquidation
   - Risk < 75%: Monitoring only, no action
```

**Configuration Parameters:**
- Maximum batch size: 25 positions per execution
- Cooldown between liquidations: 180 seconds
- Maximum gas per upkeep: 2,500,000
- Verification interval: Configurable (typically 5-10 minutes)

## ⚙️ System Configuration

### Environment Variables

```bash
# Required contracts
FLEXIBLE_LOAN_MANAGER=0x...        # FlexibleLoanManager address
DYNAMIC_PRICE_REGISTRY=0x...       # DynamicPriceRegistry address
PRIVATE_KEY=0x...                  # Deployer private key

# Automation configuration
MAX_GAS_PER_UPKEEP=2500000        # Maximum gas per upkeep
MIN_RISK_THRESHOLD=75             # Minimum risk threshold (%)
LIQUIDATION_COOLDOWN=180          # Cooldown between liquidations (seconds)
ENABLE_VOLATILITY_MODE=true       # Enable volatility detection
```

### Multi-Level Risk Thresholds

The system uses tiered risk assessment:

| Level | Range | Color | Action | Priority |
|-------|-------|-------|--------|-----------|
| **🔴 Critical** | 95%+ | Red | Immediate liquidation | Maximum |
| **🟠 Immediate** | 85-94% | Orange | High priority liquidation | High |
| **🟡 Urgent** | 75-84% | Yellow | Standard liquidation | Medium |
| **🟢 Warning** | 60-74% | Green | Monitoring only | Low |
| **⚪ Safe** | <60% | White | No action | - |

### Volatility Detection

```solidity
// Price change thresholds (base 1,000,000)
priceChangeThreshold = 50000    // 5% - Basic activation
urgentThreshold = 75000         // 7.5% - Urgent level  
immediateThreshold = 100000     // 10% - Immediate level
criticalThreshold = 150000      // 15% - Critical level
volatilityBoostThreshold = 100000 // 10% - Volatility mode
```

## 🚀 Despliegue Paso a Paso

### 1. Configuración del Entorno

```bash
# Clonar y configurar
git clone <repo>
cd Vcop-Collateral-system-hook-main

# Configurar variables de entorno
cp .env.example .env
# Editar .env con tus valores

# Configurar direcciones de contratos desplegados
export FLEXIBLE_LOAN_MANAGER=0x...
export DYNAMIC_PRICE_REGISTRY=0x...
```

### 2. Desplegar Sistema de Automatización

```bash
# Opción A: Despliegue limpio completo
forge script script/automation/DeployAutomationClean.s.sol \
    --broadcast \
    --verify \
    --rpc-url $RPC_URL

# Opción B: Despliegue estándar
forge script script/automation/DeployAutomation.s.sol \
    --broadcast \
    --verify \
    --rpc-url $RPC_URL
```

### 3. Configurar en UI de Chainlink Automation

#### Custom Logic Upkeep
```bash
# Obtener checkData para registro
cast call $LOAN_AUTOMATION_KEEPER \
    "generateCheckData(address,uint256,uint256)" \
    $LOAN_ADAPTER_ADDRESS 0 25

# Configuración en UI:
# - Dirección del Contrato: $LOAN_AUTOMATION_KEEPER  
# - checkData: <resultado del comando anterior>
# - Límite de Gas: 2,500,000
# - Fondos: Mínimo 10 LINK
```

#### Log Trigger Upkeep
```bash
# Configuración en UI:
# - Dirección del Contrato: $PRICE_CHANGE_LOG_TRIGGER
# - Filtro de Log: 
#   - Dirección: $DYNAMIC_PRICE_REGISTRY
#   - Topic0: Firma del evento TokenPriceUpdated
# - Límite de Gas: 2,000,000  
# - Fondos: Mínimo 5 LINK
```

## 🔧 Funciones de Configuración

### LoanAutomationKeeperOptimized

```solidity
// Configurar umbrales
loanKeeper.setMinRiskThreshold(75);
loanKeeper.setMaxPositionsPerBatch(25);
loanKeeper.setLiquidationCooldown(180);

// Registrar gestores con prioridad
loanKeeper.registerLoanManager(adapterAddress, 100);

// Control de emergencia
loanKeeper.setEmergencyPause(false);
```

### LoanManagerAutomationAdapter

```solidity
// Configurar umbrales dinámicos
loanAdapter.setRiskThresholds(
    95,  // Umbral crítico
    85,  // Umbral de peligro
    75   // Umbral de advertencia  
);

// Configurar cooldown
loanAdapter.setLiquidationCooldown(180);

// Conectar a automatización
loanAdapter.setAutomationContract(loanKeeperAddress);

// Inicializar seguimiento de posiciones
uint256[] memory existingPositions = getExistingPositions();
loanAdapter.initializePositionTracking(existingPositions);
```

### PriceChangeLogTrigger

```solidity
// Configurar umbrales de precio
priceLogTrigger.setPriceChangeThresholds(
    50000,   // 5% básico
    75000,   // 7.5% urgente
    100000,  // 10% inmediato
    150000   // 15% crítico
);

// Configurar volatilidad
priceLogTrigger.setVolatilityParameters(
    100000, // 10% umbral de volatilidad
    3600    // 1 hora de duración
);

// Registrar gestores
priceLogTrigger.registerLoanManager(adapterAddress, 100);
```

## 📊 Monitoreo y Análisis

### Estadísticas del Sistema

```solidity
// Rendimiento del keeper
(uint256 totalLiquidations, 
 uint256 totalUpkeeps, 
 uint256 lastExecution,
 uint256 averageGas,
 uint256 managersCount) = loanKeeper.getStats();

// Estadísticas del adaptador
(uint256 tracked,
 uint256 atRisk, 
 uint256 liquidatable,
 uint256 critical,
 uint256 performance) = loanAdapter.getTrackingStats();

// Estadísticas de precio
(uint256 triggers,
 uint256 liquidations,
 uint256 volatilityEvents, 
 uint256 lastTrigger,
 uint256 activeVolatile) = priceLogTrigger.getStatistics();
```

### Monitoreo de Posiciones en Tiempo Real

```solidity
// Obtener todas las posiciones en riesgo
(uint256[] memory riskPositions, 
 uint256[] memory riskLevels) = loanAdapter.getPositionsAtRisk();

// Verificar posición específica
(bool isAtRisk, uint256 riskLevel) = 
    loanAdapter.isPositionAtRisk(positionId);

// Obtener datos de salud de posición
(address borrower,
 uint256 collateralValue,
 uint256 debtValue, 
 uint256 healthFactor) = loanAdapter.getPositionHealthData(positionId);
```

## 🚨 Procedimientos de Emergencia

### Pausa de Emergencia

```solidity
// Pausar todo el sistema
loanKeeper.setEmergencyPause(true);
priceLogTrigger.setEmergencyPause(true);

// Reanudar después de solucionar problemas
loanKeeper.setEmergencyPause(false);
priceLogTrigger.setEmergencyPause(false);
```

### Liquidación Manual

```solidity
// Si falla la automatización, liquidar manualmente
flexibleLoanManager.liquidatePosition(positionId);

// O a través del adaptador
loanAdapter.automatedLiquidation(positionId);
```

## 🎯 Mejores Prácticas

### Optimización de Gas

- **Tamaño de Lote**: Comenzar con 25 posiciones, ajustar según uso de gas
- **Umbrales de Riesgo**: Usar 75% mínimo para balance seguridad/eficiencia
- **Cooldown**: Mínimo 3 minutos para prevenir spam
- **Límites de Gas**: 2.5M para lógica personalizada, 2M para triggers de log

### Gestión de Riesgo

- **Monitoreo Activo**: Revisar métricas diariamente
- **Alertas**: Configurar notificaciones para fallos
- **Respaldo**: Mantener procedimientos de liquidación manual
- **Pruebas**: Probar con posiciones de muestra regularmente

## 📈 Especificaciones Técnicas

### Versiones de Chainlink
- **AutomationCompatible**: v2.25.0
- **ILogAutomation**: v2.25.0  
- **Interfaces**: Chainlink Oficial

### Compatibilidad
- **Solidity**: ^0.8.24 - ^0.8.26
- **FlexibleLoanManager**: ✅ Completamente integrado
- **DynamicPriceRegistry**: ✅ Soporte nativo
- **Multi-Asset**: ✅ Soporte completo

### Límites del Sistema
- **Tamaño Máximo de Lote**: 200 posiciones
- **Gas Máximo por Upkeep**: 5,000,000
- **Cooldown Mínimo**: 60 segundos
- **Gestores Máximos**: Ilimitado (permitiendo gas)

## 🎯 Resumen Ejecutivo del Sistema Actual

### Características Principales Implementadas

✅ **Chainlink Automation v2.25.0** - Versión más reciente con `AutomationCompatible` e `ILogAutomation`  
✅ **Sistema de Doble Trigger** - Custom Logic + Log Triggers para cobertura completa  
✅ **Integración FlexibleLoanManager** - Integración nativa con liquidaciones optimizadas  
✅ **Monitoreo Dinámico de Precios** - Respuesta inmediata a cambios de `DynamicPriceRegistry`  
✅ **Evaluación de Riesgo Multi-tier** - 4 niveles de urgencia con estrategias diferenciadas  
✅ **Detección de Volatilidad** - Modo especial para alta volatilidad del mercado  
✅ **Optimización de Gas** - Batching inteligente y gestión eficiente de gas  
✅ **Seguimiento de Posiciones** - Sistema automático de seguimiento para posiciones activas  
✅ **Métricas de Rendimiento** - Estadísticas completas y monitoreo en tiempo real  
✅ **Controles de Emergencia** - Pausas de emergencia y procedimientos de respaldo  

### Ventajas Técnicas del Sistema

🚀 **Escalabilidad**: Soporte para múltiples gestores de préstamos simultáneos  
🛡️ **Seguridad**: Cooldowns, patrones de autorización y controles de emergencia  
⚡ **Eficiencia**: Optimizado para gas con batching y priorización inteligente  
🎯 **Precisión**: Evaluación de riesgo basada en datos reales del protocolo  
🔄 **Flexibilidad**: Parámetros configurables adaptables a condiciones del mercado  
📊 **Observabilidad**: Métricas detalladas y funciones de debugging  

## 🔗 Recursos Adicionales

- [Documentación de Chainlink Automation](https://docs.chain.link/chainlink-automation)
- [Guía de FlexibleLoanManager](../../../src/core/README.md)
- [Documentación de DynamicPriceRegistry](../../../src/interfaces/IPriceRegistry.sol)
- [Interfaz ILoanAutomation](../../../src/automation/interfaces/ILoanAutomation.sol)

---

*Sistema diseñado para máxima eficiencia, seguridad y flexibilidad en el manejo automatizado de liquidaciones para el protocolo de préstamos.* 