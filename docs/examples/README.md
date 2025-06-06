# 🧪 EJEMPLOS DE CÓDIGO

Esta sección contiene ejemplos prácticos de implementación y uso del protocolo VCOP Collateral.

## 📁 EJEMPLOS DISPONIBLES

### 📄 [RiskCalculationExample.sol](../../examples/RiskCalculationExample.sol)
**Ejemplos prácticos de cálculos de riesgo**

**Incluye:**
- ✅ Simulaciones de posiciones ETH→USDC, WBTC→VCOP  
- ✅ Análisis de cambios de precio en tiempo real
- ✅ Proyecciones de riesgo futuro (30 días)
- ✅ Análisis de cartera multi-asset
- ✅ Impacto de volatilidad en liquidaciones

## 🚀 EJEMPLOS DE USO

### **1. Análisis Básico de Posición**
```javascript
const riskExample = new ethers.Contract(RISK_EXAMPLE_ADDRESS, abi, provider);

// Obtener análisis completo de una posición ETH→USDC
const ethExample = await riskExample.exampleETHtoUSDC();
console.log(`Scenario: ${ethExample.scenario}`);
console.log(`Collateralization Ratio: ${ethExample.collateralizationRatio / 10000}%`);
console.log(`Risk Level: ${ethExample.riskLevel}`);
console.log(`Health Factor: ${ethExample.healthFactor / 1000000}`);
console.log(`Max Withdrawable ETH: ${ethers.utils.formatEther(ethExample.maxWithdrawableETH)}`);
console.log(`Liquidation Price: $${ethExample.liquidationPriceETH / 1000000}`);
```

### **2. Simulación de Cambio de Precio**
```javascript
// Cambiar precio de ETH y ver impacto
await riskExample.updateMockPrice(ETH_ADDRESS, ethers.utils.parseUnits("1800", 6)); // $1,800

const priceChangeResult = await riskExample.simulatePriceChange(ethers.utils.parseUnits("1800", 6));
console.log(`Old Ratio: ${priceChangeResult.oldRatio / 10000}%`);
console.log(`New Ratio: ${priceChangeResult.newRatio / 10000}%`);
console.log(`Risk Level Changed: ${priceChangeResult.oldRiskLevel} → ${priceChangeResult.newRiskLevel}`);
console.log(`Liquidation Triggered: ${priceChangeResult.liquidationTriggered}`);
```

### **3. Análisis de Cartera Multi-Asset**
```javascript
// Analizar riesgo de cartera completa
const portfolio = await riskExample.portfolioRiskAnalysis();
console.log(`Total Collateral: $${portfolio.totalCollateralUSD / 1000000}`);
console.log(`Total Debt: $${portfolio.totalDebtUSD / 1000000}`);
console.log(`Portfolio Health: ${portfolio.portfolioHealthFactor / 1000000}`);
console.log(`Positions at Risk: ${portfolio.positionsAtRisk}`);
console.log(`Overall Risk Level: ${portfolio.overallRiskLevel}`);
```

### **4. Proyección de Riesgo Futuro**
```javascript
// Proyectar riesgo a 30 días con acumulación de intereses
const futureRisk = await riskExample.futureRiskProjection(30); // 30 days
console.log(`Current Health: ${futureRisk.currentHealthFactor / 1000000}`);
console.log(`Future Health (30d): ${futureRisk.futureHealthFactor / 1000000}`);
console.log(`Additional Interest: ${ethers.utils.formatUnits(futureRisk.additionalInterest, 6)} USDC`);
console.log(`Days to Liquidation: ${futureRisk.daysToLiquidation}`);
```

### **5. Análisis de Impacto de Volatilidad**
```javascript
// Analizar precios críticos para diferentes niveles de riesgo
const volatility = await riskExample.volatilityImpactAnalysis();
console.log(`Current ETH Price: $${volatility.currentPrice / 1000000}`);
console.log(`Liquidation Price: $${volatility.liquidationPrice / 1000000}`);
console.log(`10% Risk Price: $${volatility.priceFor10PercentRisk / 1000000}`);
console.log(`50% Risk Price: $${volatility.priceFor50PercentRisk / 1000000}`);
console.log(`90% Risk Price: $${volatility.priceFor90PercentRisk / 1000000}`);
```

## 📊 CASOS DE USO REALES

### **Dashboard de Usuario**
```javascript
class PositionDashboard {
    async displayUserPositions(userAddress) {
        const positions = await loanManager.getUserPositions(userAddress);
        
        for (const positionId of positions) {
            const metrics = await riskCalculator.calculateRiskMetrics(positionId);
            const position = await loanManager.getPosition(positionId);
            
            this.renderPositionCard({
                id: positionId,
                collateral: position.collateralAsset,
                loan: position.loanAsset,
                ratio: metrics.collateralizationRatio / 10000,
                healthFactor: metrics.healthFactor / 1000000,
                riskLevel: metrics.riskLevel,
                liquidationPrice: metrics.liquidationPrice,
                maxWithdrawable: metrics.maxWithdrawable
            });
        }
    }
}
```

### **Sistema de Alertas**
```javascript
class RiskAlertSystem {
    async monitorPositions(userAddress) {
        const positions = await loanManager.getUserPositions(userAddress);
        
        for (const positionId of positions) {
            const metrics = await riskCalculator.calculateRiskMetrics(positionId);
            
            // Alertas por nivel de riesgo
            if (metrics.riskLevel >= 3) { // CRITICAL
                this.sendAlert({
                    type: 'CRITICAL',
                    message: `Position ${positionId} is at critical risk!`,
                    action: 'ADD_COLLATERAL_OR_REPAY',
                    estimatedTime: metrics.timeToLiquidation
                });
            } else if (metrics.riskLevel === 2) { // DANGER
                this.sendAlert({
                    type: 'WARNING', 
                    message: `Position ${positionId} needs attention`,
                    action: 'CONSIDER_ADDING_COLLATERAL'
                });
            }
        }
    }
}
```

### **Bot de Liquidación**
```javascript
class LiquidationBot {
    async scanForLiquidations() {
        // Obtener todas las posiciones activas
        const allPositions = await this.getAllActivePositions();
        
        for (const positionId of allPositions) {
            const canLiquidate = await loanManager.canLiquidate(positionId);
            
            if (canLiquidate) {
                const liquidationStatus = await riskCalculator.checkLiquidationStatus(positionId);
                
                // Verificar si es rentable
                if (liquidationStatus.liquidatorProfit > this.minProfitThreshold) {
                    console.log(`Liquidating position ${positionId} for profit: ${liquidationStatus.liquidatorProfit}`);
                    await loanManager.liquidatePosition(positionId);
                }
            }
        }
    }
}
```

## 🔧 HERRAMIENTAS DE DESARROLLO

### **Testing de Cálculos**
```javascript
describe("Risk Calculations", function() {
    it("should calculate correct ratios", async function() {
        const example = await deployContract("RiskCalculationExample");
        
        // Test escenario ETH→USDC
        const result = await example.exampleETHtoUSDC();
        expect(result.collateralizationRatio).to.equal(2500000); // 250%
        expect(result.riskLevel).to.equal("HEALTHY");
        expect(result.healthFactor).to.be.gt(2000000); // > 2.0
    });
    
    it("should detect liquidation correctly", async function() {
        const example = await deployContract("RiskCalculationExample");
        
        // Simular crash de precio
        const crashResult = await example.simulatePriceChange(ethers.utils.parseUnits("960", 6));
        expect(crashResult.liquidationTriggered).to.be.true;
        expect(crashResult.newRiskLevel).to.equal("LIQUIDATABLE");
    });
});
```

### **Integración con Frontend**
```javascript
// Hook de React para monitoreo de posiciones
function usePositionRisk(positionId) {
    const [metrics, setMetrics] = useState(null);
    
    useEffect(() => {
        const updateMetrics = async () => {
            const newMetrics = await riskCalculator.calculateRiskMetrics(positionId);
            setMetrics(newMetrics);
        };
        
        updateMetrics();
        const interval = setInterval(updateMetrics, 30000); // Cada 30 segundos
        
        return () => clearInterval(interval);
    }, [positionId]);
    
    return metrics;
}

// Componente de visualización
function PositionRiskDisplay({ positionId }) {
    const metrics = usePositionRisk(positionId);
    
    if (!metrics) return <Loading />;
    
    return (
        <div className={`risk-${metrics.riskLevel.toLowerCase()}`}>
            <h3>Position #{positionId}</h3>
            <div>Ratio: {(metrics.collateralizationRatio / 10000).toFixed(1)}%</div>
            <div>Health: {(metrics.healthFactor / 1000000).toFixed(2)}</div>
            <div>Risk: {metrics.riskLevel}</div>
            {metrics.riskLevel >= 2 && (
                <Alert severity="warning">
                    Position needs attention! Consider adding collateral.
                </Alert>
            )}
        </div>
    );
}
```

## 📈 MÉTRICAS DE PERFORMANCE

### **Benchmarking de Gas**
```javascript
async function benchmarkGasCosts() {
    const gasReport = {
        createLoan: await estimateGas('createLoan', loanTerms),
        addCollateral: await estimateGas('addCollateral', positionId, amount),
        withdrawCollateral: await estimateGas('withdrawCollateral', positionId, amount),
        repayLoan: await estimateGas('repayLoan', positionId, amount),
        liquidate: await estimateGas('liquidatePosition', positionId),
        calculateRisk: await estimateGas('calculateRiskMetrics', positionId)
    };
    
    console.table(gasReport);
}
```

## 🔗 ENLACES RELACIONADOS

- 🏗️ [Arquitectura](../architecture/) - Diseño del sistema
- 📊 [Gestión de Riesgo](../risk-management/) - Documentación técnica
- 🚀 [Despliegue](../deployment/) - Guías de implementación
- 📚 [Documentación Principal](../README.md) - Índice general 