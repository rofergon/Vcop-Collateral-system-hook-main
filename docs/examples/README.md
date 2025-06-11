# 🧪 CODE EXAMPLES

This section contains practical implementation and usage examples of the VCOP Collateral protocol.

## 📁 AVAILABLE EXAMPLES

### 📄 [RiskCalculationExample.sol](../../examples/RiskCalculationExample.sol)
**Practical risk calculation examples**

**Includes:**
- ✅ ETH→USDC, WBTC→VCOP position simulations
- ✅ Real-time price change analysis
- ✅ Future risk projections (30 days)
- ✅ Multi-asset portfolio analysis
- ✅ Volatility impact on liquidations

## 🚀 USAGE EXAMPLES

### **1. Basic Position Analysis**
```javascript
const riskExample = new ethers.Contract(RISK_EXAMPLE_ADDRESS, abi, provider);

// Get complete analysis of an ETH→USDC position
const ethExample = await riskExample.exampleETHtoUSDC();
console.log(`Scenario: ${ethExample.scenario}`);
console.log(`Collateralization Ratio: ${ethExample.collateralizationRatio / 10000}%`);
console.log(`Risk Level: ${ethExample.riskLevel}`);
console.log(`Health Factor: ${ethExample.healthFactor / 1000000}`);
console.log(`Max Withdrawable ETH: ${ethers.utils.formatEther(ethExample.maxWithdrawableETH)}`);
console.log(`Liquidation Price: $${ethExample.liquidationPriceETH / 1000000}`);
```

### **2. Price Change Simulation**
```javascript
// Change ETH price and see impact
await riskExample.updateMockPrice(ETH_ADDRESS, ethers.utils.parseUnits("1800", 6)); // $1,800

const priceChangeResult = await riskExample.simulatePriceChange(ethers.utils.parseUnits("1800", 6));
console.log(`Old Ratio: ${priceChangeResult.oldRatio / 10000}%`);
console.log(`New Ratio: ${priceChangeResult.newRatio / 10000}%`);
console.log(`Risk Level Changed: ${priceChangeResult.oldRiskLevel} → ${priceChangeResult.newRiskLevel}`);
console.log(`Liquidation Triggered: ${priceChangeResult.liquidationTriggered}`);
```

### **3. Multi-Asset Portfolio Analysis**
```javascript
// Analyze complete portfolio risk
const portfolio = await riskExample.portfolioRiskAnalysis();
console.log(`Total Collateral: $${portfolio.totalCollateralUSD / 1000000}`);
console.log(`Total Debt: $${portfolio.totalDebtUSD / 1000000}`);
console.log(`Portfolio Health: ${portfolio.portfolioHealthFactor / 1000000}`);
console.log(`Positions at Risk: ${portfolio.positionsAtRisk}`);
console.log(`Overall Risk Level: ${portfolio.overallRiskLevel}`);
```

### **4. Future Risk Projection**
```javascript
// Project risk to 30 days with interest accumulation
const futureRisk = await riskExample.futureRiskProjection(30); // 30 days
console.log(`Current Health: ${futureRisk.currentHealthFactor / 1000000}`);
console.log(`Future Health (30d): ${futureRisk.futureHealthFactor / 1000000}`);
console.log(`Additional Interest: ${ethers.utils.formatUnits(futureRisk.additionalInterest, 6)} USDC`);
console.log(`Days to Liquidation: ${futureRisk.daysToLiquidation}`);
```

### **5. Volatility Impact Analysis**
```javascript
// Analyze critical prices for different risk levels
const volatility = await riskExample.volatilityImpactAnalysis();
console.log(`Current ETH Price: $${volatility.currentPrice / 1000000}`);
console.log(`Liquidation Price: $${volatility.liquidationPrice / 1000000}`);
console.log(`10% Risk Price: $${volatility.priceFor10PercentRisk / 1000000}`);
console.log(`50% Risk Price: $${volatility.priceFor50PercentRisk / 1000000}`);
console.log(`90% Risk Price: $${volatility.priceFor90PercentRisk / 1000000}`);
```

## 📊 REAL USE CASES

### **User Dashboard**
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

### **Alert System**
```javascript
class RiskAlertSystem {
    async monitorPositions(userAddress) {
        const positions = await loanManager.getUserPositions(userAddress);
        
        for (const positionId of positions) {
            const metrics = await riskCalculator.calculateRiskMetrics(positionId);
            
            // Alerts by risk level
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

### **Liquidation Bot**
```javascript
class LiquidationBot {
    async scanForLiquidations() {
        // Get all active positions
        const allPositions = await this.getAllActivePositions();
        
        for (const positionId of allPositions) {
            const canLiquidate = await loanManager.canLiquidate(positionId);
            
            if (canLiquidate) {
                const liquidationStatus = await riskCalculator.checkLiquidationStatus(positionId);
                
                // Check if profitable
                if (liquidationStatus.liquidatorProfit > this.minProfitThreshold) {
                    console.log(`Liquidating position ${positionId} for profit: ${liquidationStatus.liquidatorProfit}`);
                    await loanManager.liquidatePosition(positionId);
                }
            }
        }
    }
}
```

## 🔧 DEVELOPMENT TOOLS

### **Calculation Testing**
```javascript
describe("Risk Calculations", function() {
    it("should calculate correct ratios", async function() {
        const example = await deployContract("RiskCalculationExample");
        
        // Test ETH→USDC scenario
        const result = await example.exampleETHtoUSDC();
        expect(result.collateralizationRatio).to.equal(2500000); // 250%
        expect(result.riskLevel).to.equal("HEALTHY");
        expect(result.healthFactor).to.be.gt(2000000); // > 2.0
    });
    
    it("should detect liquidation correctly", async function() {
        const example = await deployContract("RiskCalculationExample");
        
        // Simulate price crash
        const crashResult = await example.simulatePriceChange(ethers.utils.parseUnits("960", 6));
        expect(crashResult.liquidationTriggered).to.be.true;
        expect(crashResult.newRiskLevel).to.equal("LIQUIDATABLE");
    });
});
```

### **Frontend Integration**
```javascript
// React hook for position monitoring
function usePositionRisk(positionId) {
    const [metrics, setMetrics] = useState(null);
    
    useEffect(() => {
        const updateMetrics = async () => {
            const newMetrics = await riskCalculator.calculateRiskMetrics(positionId);
            setMetrics(newMetrics);
        };
        
        updateMetrics();
        const interval = setInterval(updateMetrics, 30000); // Every 30 seconds
        
        return () => clearInterval(interval);
    }, [positionId]);
    
    return metrics;
}

// Display component
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

## 📈 PERFORMANCE METRICS

### **Gas Benchmarking**
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

### **Performance Monitoring**
```javascript
class PerformanceMonitor {
    async trackProtocolMetrics() {
        const metrics = {
            totalValueLocked: await this.calculateTVL(),
            activePositions: await this.getActivePositionsCount(),
            averageHealthFactor: await this.getAverageHealthFactor(),
            liquidationRate: await this.getLiquidationRate(),
            protocolRevenue: await this.getProtocolRevenue(),
            gasEfficiency: await this.getGasEfficiencyMetrics()
        };
        
        // Store metrics for historical analysis
        await this.storeMetrics(metrics);
        
        // Check for anomalies
        await this.detectAnomalies(metrics);
        
        return metrics;
    }
    
    async detectAnomalies(currentMetrics) {
        const historicalData = await this.getHistoricalMetrics(30); // 30 days
        
        // Check for unusual patterns
        if (currentMetrics.liquidationRate > historicalData.avgLiquidationRate * 3) {
            await this.alertHighLiquidationActivity();
        }
        
        if (currentMetrics.averageHealthFactor < 1.2) {
            await this.alertLowSystemHealth();
        }
    }
}
```

## 🧮 CALCULATION UTILITIES

### **Risk Score Calculator**
```javascript
class RiskScoreCalculator {
    calculateRiskScore(metrics) {
        const {
            collateralizationRatio,
            healthFactor,
            timeToLiquidation,
            volatility
        } = metrics;
        
        // Weighted risk score (0-100)
        const ratioScore = Math.max(0, Math.min(100, (200 - collateralizationRatio / 10000) * 2));
        const healthScore = Math.max(0, Math.min(100, (2 - healthFactor / 1000000) * 50));
        const timeScore = Math.max(0, Math.min(100, 100 - (timeToLiquidation / 86400) * 3.33)); // 30 days = 0 score
        const volatilityScore = Math.min(100, volatility * 100);
        
        const weightedScore = (
            ratioScore * 0.4 +
            healthScore * 0.3 +
            timeScore * 0.2 +
            volatilityScore * 0.1
        );
        
        return {
            totalScore: Math.round(weightedScore),
            breakdown: {
                ratio: ratioScore,
                health: healthScore,
                time: timeScore,
                volatility: volatilityScore
            }
        };
    }
}
```

## 🔗 RELATED LINKS

- 🏗️ [Architecture](../architecture/) - System design
- 📊 [Risk Management](../risk-management/) - Technical documentation
- 🚀 [Deployment](../deployment/) - Implementation guides
- 📚 [Main Documentation](../README.md) - General index 