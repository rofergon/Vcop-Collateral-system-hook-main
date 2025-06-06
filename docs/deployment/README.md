# 🚀 DESPLIEGUE E IMPLEMENTACIÓN

Esta sección contiene toda la documentación relacionada con el despliegue, configuración e implementación del protocolo en producción.

## 📁 CONTENIDO

### 🚀 [SISTEMA_CORREGIDO_DESPLIEGUE.md](./SISTEMA_CORREGIDO_DESPLIEGUE.md) ⭐ **NUEVO**
**Guía Completa del Sistema de Préstamos Colateralizados Corregido**

**Incluye:**
- ✅ Procedimiento completo de despliegue corregido
- ✅ Configuración automatizada del oracle
- ✅ Solución a problemas de direcciones hardcodeadas
- ✅ Workflow automatizado sin intervención manual
- ✅ Verificación y testing del sistema
- ✅ Métricas de éxito y validación

### 🚨 [TROUBLESHOOTING.md](./TROUBLESHOOTING.md) ⭐ **NUEVO**
**Solución de Problemas Comunes**

**Incluye:**
- ✅ Error "Insufficient collateral" y su solución
- ✅ Problemas de oracle (precios incorrectos)
- ✅ Direcciones hardcodeadas obsoletas
- ✅ Comandos de diagnóstico y recuperación
- ✅ Checklist de verificación pre-despliegue

### ⚡ [REFERENCIA_RAPIDA.md](./REFERENCIA_RAPIDA.md) ⭐ **NUEVO**
**Comandos y Valores de Referencia Inmediata**

**Incluye:**
- ✅ Comandos esenciales de despliegue y testing
- ✅ Soluciones rápidas a problemas comunes
- ✅ Valores de configuración y precios oracle
- ✅ Template de direcciones para actualizar
- ✅ Checklist rápido de verificación

### 📄 [INSTRUCCIONES_DESPLIEGUE.md](./INSTRUCCIONES_DESPLIEGUE.md) 🔄 **ACTUALIZADO**
**Guía de despliegue para sistemas VCOP y legacy**

**Incluye:**
- ✅ Sistema de préstamos colateralizados (nuevo)
- ✅ Scripts de configuración automatizados
- ✅ Sistema VCOP original (legacy)
- ✅ Referencias cruzadas a nueva documentación

### 📄 [PSM-README.md](./PSM-README.md)
**Peg Stability Module - Configuración y funcionamiento**

**Incluye:**
- ✅ Explicación técnica del PSM
- ✅ Parámetros de configuración
- ✅ Integración con VCOPCollateralHook
- ✅ Mecanismos de estabilización
- ✅ Monitoreo y ajustes

## 🎯 ESTRATEGIA DE DESPLIEGUE

### **Enfoque Gradual por Fases**

#### **Fase 1: Core Infrastructure** 
```bash
# Contratos base
FlexibleLoanManager.sol
FlexibleAssetHandler.sol  
GenericOracle.sol
RiskCalculator.sol
```

#### **Fase 2: Asset Integration**
```bash
# Configuración de assets principales
VCOP (Mintable)
ETH (Vault-based)
WBTC (Vault-based)
USDC (Vault-based)
```

#### **Fase 3: Hook Integration**
```bash
# Integración con Uniswap v4
VCOPCollateralHook.sol
PSM Configuration
Price Monitoring
```

#### **Fase 4: Advanced Features**
```bash
# Características avanzadas
Risk metrics avanzadas
Portfolio management
Liquidation automation
```

#### **Fase 5: Production Migration**
```bash
# Migración en producción
User migration tools
Interface upgrades
Legacy system sunset
```

## 🛠️ HERRAMIENTAS DE DESPLIEGUE

### **Scripts Automatizados**
```bash
script/
├── deploy/
│   ├── DeployNewArchitecture.s.sol    # Despliegue completo
│   ├── ConfigureAssets.s.sol          # Configuración de assets
│   └── SetupOracles.s.sol             # Configuración de oráculos
├── configure/
│   ├── ConfigureVCOPSystem.sol        # Sistema VCOP
│   └── SetupPSM.s.sol                 # Configuración PSM
└── verify/
    ├── VerifyContracts.s.sol          # Verificación automática
    └── ValidateDeployment.s.sol       # Validación post-despliegue
```

### **Configuración por Red**

#### **Mainnet Production**
```solidity
// Parámetros conservadores
uint256 liquidationBonus = 50000;      // 5%
uint256 protocolFee = 5000;            // 0.5%
uint256 maxLoanAmount = 1000000e18;    // 1M tokens max
bool strictValidation = true;          // Validaciones estrictas
```

#### **Testnet Development**
```solidity
// Parámetros flexibles para testing
uint256 liquidationBonus = 100000;     // 10%
uint256 protocolFee = 10000;           // 1%
uint256 maxLoanAmount = 10000e18;      // 10K tokens max
bool strictValidation = false;         // Validaciones relajadas
```

## 📋 CHECKLIST DE DESPLIEGUE

### **Pre-Despliegue**
- [ ] ✅ Auditoría de seguridad completa
- [ ] ✅ Testing exhaustivo en testnet
- [ ] ✅ Configuración de oráculos verificada
- [ ] ✅ Parámetros de red definidos
- [ ] ✅ Scripts de despliegue validados
- [ ] ✅ Plan de rollback preparado

### **Durante el Despliegue**
- [ ] ⚙️ Desplegar contratos base
- [ ] ⚙️ Configurar asset handlers
- [ ] ⚙️ Configurar oráculos
- [ ] ⚙️ Verificar contratos en etherscan
- [ ] ⚙️ Configurar PSM
- [ ] ⚙️ Testing de integración

### **Post-Despliegue**
- [ ] ✅ Verificación de funcionalidad
- [ ] ✅ Monitoreo de métricas
- [ ] ✅ Documentación actualizada
- [ ] ✅ Interfaces de usuario actualizadas
- [ ] ✅ Comunicación a usuarios
- [ ] ✅ Monitoreo continuo 24/7

## 🔧 CONFIGURACIÓN TÉCNICA

### **Variables de Entorno**
```bash
# Configuración de red
ETHEREUM_RPC_URL=https://mainnet.infura.io/v3/YOUR_KEY
POLYGON_RPC_URL=https://polygon-mainnet.infura.io/v3/YOUR_KEY
BSC_RPC_URL=https://bsc-dataseed.binance.org/

# Claves de despliegue
DEPLOYER_PRIVATE_KEY=0x...
MULTISIG_ADDRESS=0x...

# Configuración de verificación
ETHERSCAN_API_KEY=YOUR_ETHERSCAN_KEY
POLYGONSCAN_API_KEY=YOUR_POLYGONSCAN_KEY

# Oráculos
CHAINLINK_ETH_USD=0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
CHAINLINK_BTC_USD=0xF4030086522a5bEEa4988F8cA5B36dbC97BeE88c
```

### **Configuración de Gas**
```solidity
// Optimización de gas por red
if (block.chainid == 1) {          // Mainnet
    gasPrice = 30 gwei;
    gasLimit = 500000;
} else if (block.chainid == 137) { // Polygon  
    gasPrice = 50 gwei;
    gasLimit = 800000;
} else if (block.chainid == 56) {  // BSC
    gasPrice = 5 gwei;
    gasLimit = 600000;
}
```

## 🔍 VALIDACIÓN Y TESTING

### **Testing Automatizado**
```bash
# Suite de tests completa
forge test --fork-url $ETHEREUM_RPC_URL
forge test --fork-url $POLYGON_RPC_URL
forge test --fork-url $BSC_RPC_URL

# Tests específicos por componente
forge test --match-contract FlexibleLoanManagerTest
forge test --match-contract RiskCalculatorTest
forge test --match-contract AssetHandlerTest
```

### **Verificación Post-Despliegue**
```solidity
// Script de validación automática
contract ValidateDeployment {
    function validateFullSystem() external {
        // 1. Verificar contratos desplegados
        require(address(loanManager) != address(0), "LoanManager not deployed");
        require(address(assetHandler) != address(0), "AssetHandler not deployed");
        
        // 2. Verificar configuraciones
        require(loanManager.protocolFee() == EXPECTED_FEE, "Wrong protocol fee");
        
        // 3. Testing de funcionalidad básica
        testCreateLoan();
        testLiquidation();
        testRiskCalculations();
        
        // 4. Verificar integraciones
        testOracleIntegration();
        testPSMFunctionality();
    }
}
```

## 📊 MONITOREO POST-DESPLIEGUE

### **Métricas Clave**
```javascript
// Dashboard de monitoreo
const metrics = {
    totalValueLocked: await getTVL(),
    activeLoans: await getActiveLoansCount(),
    liquidationsLast24h: await getLiquidations24h(),
    averageHealthFactor: await getAverageHealthFactor(),
    protocolRevenue: await getProtocolRevenue(),
    gasUsageOptimization: await getGasMetrics()
};
```

### **Alertas Automáticas**
```javascript
// Sistema de alertas
if (metrics.averageHealthFactor < 1.5) {
    sendAlert('WARNING: Low average health factor detected');
}

if (metrics.liquidationsLast24h > THRESHOLD) {
    sendAlert('HIGH: Unusual liquidation activity');
}

if (oracle.isStale()) {
    sendAlert('CRITICAL: Oracle price feed is stale');
}
```

## 🔐 SEGURIDAD Y CONTINGENCIAS

### **Plan de Rollback**
```solidity
// Mecanismo de pausa de emergencia
contract EmergencyControls {
    function pauseSystem() external onlyOwner {
        loanManager.setPaused(true);
        assetHandler.pauseAllAssets();
        hook.pausePSM(true);
    }
    
    function rollbackToSnapshot(uint256 snapshotId) external onlyOwner {
        // Revertir a estado anterior conocido
        revertToSnapshot(snapshotId);
    }
}
```

### **Multisig Controls**
```solidity
// Controles críticos requieren multisig
modifier onlyMultisig() {
    require(msg.sender == MULTISIG_ADDRESS, "Only multisig");
    _;
}

function updateCriticalParameter(uint256 newValue) external onlyMultisig {
    // Cambios críticos solo vía multisig
}
```

## 🔄 MIGRACIÓN DE USUARIOS

### **Herramientas de Migración**
```solidity
contract MigrationHelper {
    // Migrar posición del sistema viejo al nuevo
    function migratePosition(uint256 oldPositionId) external {
        // 1. Verificar ownership
        // 2. Cerrar posición en sistema viejo
        // 3. Recrear en sistema nuevo
        // 4. Transferir assets
    }
    
    // Migración en lote
    function batchMigrate(uint256[] calldata positionIds) external {
        for (uint i = 0; i < positionIds.length; i++) {
            migratePosition(positionIds[i]);
        }
    }
}
```

## 🔗 ENLACES RELACIONADOS

- 🏗️ [Arquitectura](../architecture/) - Diseño del sistema
- 📊 [Gestión de Riesgo](../risk-management/) - Cálculos y métricas
- 📚 [Documentación Principal](../README.md) - Índice general
- 🧪 [Ejemplos](../../examples/) - Código de ejemplo
- 📜 [Scripts](../../script/) - Scripts de despliegue 