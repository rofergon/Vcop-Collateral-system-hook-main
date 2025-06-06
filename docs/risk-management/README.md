# 📊 GESTIÓN DE RIESGO

Esta sección contiene toda la documentación relacionada con los cálculos de riesgo, métricas y monitoreo del protocolo.

## 📁 CONTENIDO

### 📄 [CALCULOS_RIESGO.md](./CALCULOS_RIESGO.md)
**Sistema completo de cálculos de riesgo on-chain**

**Incluye:**
- ✅ Métricas de riesgo en tiempo real (15+ indicadores)
- ✅ Health factors y ratios de colateralización
- ✅ Integración con oráculos para precios actualizados
- ✅ RiskCalculator.sol - Contrato especializado
- ✅ Ejemplos prácticos de implementación
- ✅ Comparativa: cálculos on-chain vs frontend

## 🎯 FILOSOFÍA DE GESTIÓN DE RIESGO

### **ON-CHAIN: Cálculos Críticos**
```solidity
// Todos los cálculos de seguridad están en contratos
function getCollateralizationRatio(uint256 positionId) external view returns (uint256)
function canLiquidate(uint256 positionId) public view returns (bool)
function calculateRiskMetrics(uint256 positionId) external view returns (RiskMetrics memory)
```

### **FRONTEND: UX y Warnings**
```javascript
// Frontend maneja experiencia de usuario y alertas
function calculateRiskWarnings(ratio) {
    if (ratio > 200) return { level: 'safe', color: 'green' };
    if (ratio > 105) return { level: 'extreme', color: 'red' };
    return { level: 'insane', color: 'darkred' };
}
```

## 📊 MÉTRICAS IMPLEMENTADAS

### **RiskMetrics Struct**
```solidity
struct RiskMetrics {
    uint256 collateralizationRatio;    // Ratio actual (1500000 = 150%)
    uint256 liquidationThreshold;      // Umbral de liquidación
    uint256 healthFactor;              // Factor de salud (1000000 = 1.0)
    uint256 maxWithdrawable;          // Máximo colateral retirable
    uint256 maxBorrowable;            // Máximo adicional prestable
    uint256 liquidationPrice;         // Precio de liquidación exacto
    RiskLevel riskLevel;              // HEALTHY/WARNING/DANGER/CRITICAL
    uint256 timeToLiquidation;        // Tiempo estimado en segundos
    bool isLiquidatable;              // ¿Puede liquidarse ahora?
}
```

### **Niveles de Riesgo**
| Nivel | Ratio | Color | Descripción |
|---|---|---|---|
| **HEALTHY** | >200% | 🟢 Verde | Posición muy segura |
| **WARNING** | 150-200% | 🟡 Amarillo | Atención requerida |
| **DANGER** | 120-150% | 🟠 Naranja | Alto riesgo |
| **CRITICAL** | 110-120% | 🔴 Rojo | Muy peligroso |
| **LIQUIDATABLE** | <110% | ⚫ Negro | Liquidación activa |

## 🔧 COMPONENTES TÉCNICOS

### **1. RiskCalculator.sol**
```solidity
// Cálculos comprehensivos de riesgo
function calculateRiskMetrics(uint256 positionId) external view returns (RiskMetrics memory)
function analyzePriceImpact(uint256 positionId) external view returns (PriceImpact memory)
function calculatePortfolioRisk(address user) external view returns (...)
function projectFutureRisk(uint256 positionId, uint256 timeInSeconds) external view returns (...)
```

### **2. Integración con Oráculos**
```solidity
// Precios en tiempo real para cálculos
function _getAssetValueInUSD(address asset, uint256 amount) internal view returns (uint256)
function getPriceMetrics(address asset) external view returns (uint256 price, int256 change24h, uint256 volatility)
```

### **3. Monitoreo Continuo**
```solidity
// Verificación automática en cada operación
modifier riskCheck(uint256 positionId) {
    _;
    if (canLiquidate(positionId)) {
        emit LiquidationWarning(positionId);
    }
}
```

## 📈 EJEMPLOS PRÁCTICOS

### **Escenario 1: Posición Saludable**
```
Colateral: 10 ETH @ $2,000 = $20,000
Préstamo: 8,000 USDC
Ratio: 250% ✅ HEALTHY
Health Factor: 2.27
Liquidación en: ETH < $960
```

### **Escenario 2: Posición en Peligro**
```
Colateral: 10 ETH @ $1,400 = $14,000
Préstamo: 8,200 USDC (incluye interés)
Ratio: 170% ⚠️ WARNING
Health Factor: 1.55
Liquidación en: ETH < $984
```

### **Escenario 3: Liquidación Inminente**
```
Colateral: 10 ETH @ $900 = $9,000
Préstamo: 8,500 USDC (incluye interés)
Ratio: 105% 🚨 LIQUIDATABLE
Health Factor: 0.95
Acción: LIQUIDACIÓN AUTOMÁTICA
```

## 🖥️ INTEGRACIÓN FRONTEND

### **Lectura de Métricas**
```javascript
// Obtener métricas completas
const metrics = await riskCalculator.calculateRiskMetrics(positionId);

// Mostrar en UI
displayRiskLevel(metrics.riskLevel);
showHealthFactor(metrics.healthFactor / 1000000);
displayLiquidationPrice(metrics.liquidationPrice);
```

### **Monitoreo en Tiempo Real**
```javascript
// Suscripción a eventos
loanManager.on('RiskLevelChanged', (positionId, oldLevel, newLevel) => {
    updatePositionUI(positionId, newLevel);
    if (newLevel >= 3) showCriticalAlert(positionId);
});

// Actualización periódica
setInterval(async () => {
    const positions = await loanManager.getUserPositions(userAddress);
    for (const positionId of positions) {
        const metrics = await riskCalculator.calculateRiskMetrics(positionId);
        updateDashboard(positionId, metrics);
    }
}, 30000); // Cada 30 segundos
```

## 🛡️ PROTECCIONES IMPLEMENTADAS

### **1. Validación de Oracle**
```solidity
require(priceData.isValid, "Invalid price data");
require(block.timestamp - priceData.timestamp <= MAX_PRICE_AGE, "Price too stale");
```

### **2. Prevención de Overflow**
```solidity
require(numerator <= type(uint256).max / 1000000, "Overflow in ratio calculation");
```

### **3. Circuit Breakers**
```solidity
modifier emergencyStop() {
    require(!paused, "Contract paused");
    _;
}
```

## 🚀 VENTAJAS COMPETITIVAS

### **vs Aave/Compound**
| Característica | Aave/Compound | VCOP |
|---|---|---|
| **Métricas disponibles** | 3-5 básicas | 15+ avanzadas |
| **Cálculos predictivos** | ❌ No | ✅ Sí |
| **Análisis de cartera** | ❌ Limitado | ✅ Completo |
| **Proyección futura** | ❌ No | ✅ Con intereses |
| **Análisis de volatilidad** | ❌ No | ✅ Sí |
| **Tiempo real** | ✅ Básico | ✅ Avanzado |

### **Ventajas Únicas**
- ✅ **Proyección de riesgo futuro** con acumulación de intereses
- ✅ **Análisis de impacto de precios** para diferentes escenarios
- ✅ **Health factor dinámico** que considera múltiples variables
- ✅ **Monitoreo de cartera completa** agregado
- ✅ **Estimación de tiempo a liquidación**

## 🔄 CASOS DE USO

### **Para Usuarios Finales**
1. **Monitoreo diario** de posiciones
2. **Alertas tempranas** de riesgo
3. **Optimización** de colateral
4. **Planificación** de estrategias

### **Para Traders Profesionales**
1. **Análisis técnico** avanzado
2. **Gestión de riesgo** sofisticada
3. **Arbitraje** con métricas precisas
4. **Backtesting** de estrategias

### **Para Liquidadores**
1. **Identificación** de oportunidades
2. **Cálculo** de rentabilidad
3. **Monitoreo** automatizado
4. **Optimización** de gas

## 🔗 ENLACES RELACIONADOS

- 🏗️ [Arquitectura](../architecture/) - Diseño del sistema
- 🚀 [Despliegue](../deployment/) - Implementación
- 📚 [Documentación Principal](../README.md) - Índice general
- 🧪 [Ejemplos](../../examples/) - Código de ejemplo 