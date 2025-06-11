# 📊 RISK MANAGEMENT

This section contains all documentation related to risk calculations, metrics and protocol monitoring.

## 📁 CONTENT

### 📄 [RISK_CALCULATIONS.md](./CALCULOS_RIESGO.md)
**Complete on-chain risk calculation system**

**Includes:**
- ✅ Real-time risk metrics (15+ indicators)
- ✅ Health factors and collateralization ratios
- ✅ Oracle integration for updated prices
- ✅ RiskCalculator.sol - Specialized contract
- ✅ Practical implementation examples
- ✅ Comparison: on-chain vs frontend calculations

## 🎯 RISK MANAGEMENT PHILOSOPHY

### **ON-CHAIN: Critical Calculations**
```solidity
// All security calculations are in contracts
function getCollateralizationRatio(uint256 positionId) external view returns (uint256)
function canLiquidate(uint256 positionId) public view returns (bool)
function calculateRiskMetrics(uint256 positionId) external view returns (RiskMetrics memory)
```

### **FRONTEND: UX and Warnings**
```javascript
// Frontend handles user experience and alerts
function calculateRiskWarnings(ratio) {
    if (ratio > 200) return { level: 'safe', color: 'green' };
    if (ratio > 105) return { level: 'extreme', color: 'red' };
    return { level: 'insane', color: 'darkred' };
}
```

## 📊 IMPLEMENTED METRICS

### **RiskMetrics Struct**
```solidity
struct RiskMetrics {
    uint256 collateralizationRatio;    // Current ratio (1500000 = 150%)
    uint256 liquidationThreshold;      // Liquidation threshold
    uint256 healthFactor;              // Health factor (1000000 = 1.0)
    uint256 maxWithdrawable;          // Maximum withdrawable collateral
    uint256 maxBorrowable;            // Maximum additional borrowable
    uint256 liquidationPrice;         // Exact liquidation price
    RiskLevel riskLevel;              // HEALTHY/WARNING/DANGER/CRITICAL
    uint256 timeToLiquidation;        // Estimated time in seconds
    bool isLiquidatable;              // Can be liquidated now?
}
```

### **Risk Levels**
| Level | Ratio | Color | Description |
|---|---|---|---|
| **HEALTHY** | >200% | 🟢 Green | Very safe position |
| **WARNING** | 150-200% | 🟡 Yellow | Attention required |
| **DANGER** | 120-150% | 🟠 Orange | High risk |
| **CRITICAL** | 110-120% | 🔴 Red | Very dangerous |
| **LIQUIDATABLE** | <110% | ⚫ Black | Active liquidation |

## 🔧 TECHNICAL COMPONENTS

### **1. RiskCalculator.sol**
```solidity
// Comprehensive risk calculations
function calculateRiskMetrics(uint256 positionId) external view returns (RiskMetrics memory)
function analyzePriceImpact(uint256 positionId) external view returns (PriceImpact memory)
function calculatePortfolioRisk(address user) external view returns (...)
function projectFutureRisk(uint256 positionId, uint256 timeInSeconds) external view returns (...)
```

### **2. Oracle Integration**
```solidity
// Real-time prices for calculations
function _getAssetValueInUSD(address asset, uint256 amount) internal view returns (uint256)
function getPriceMetrics(address asset) external view returns (uint256 price, int256 change24h, uint256 volatility)
```

### **3. Continuous Monitoring**
```solidity
// Automatic verification on each operation
modifier riskCheck(uint256 positionId) {
    _;
    if (canLiquidate(positionId)) {
        emit LiquidationWarning(positionId);
    }
}
```

## 📈 PRACTICAL EXAMPLES

### **Scenario 1: Healthy Position**
```
Collateral: 10 ETH @ $2,000 = $20,000
Loan: 8,000 USDC
Ratio: 250% ✅ HEALTHY
Health Factor: 2.27
Liquidation at: ETH < $960
```

### **Scenario 2: Position in Danger**
```
Collateral: 10 ETH @ $1,400 = $14,000
Loan: 8,200 USDC (including interest)
Ratio: 170% ⚠️ WARNING
Health Factor: 1.55
Liquidation at: ETH < $984
```

### **Scenario 3: Imminent Liquidation**
```
Collateral: 10 ETH @ $900 = $9,000
Loan: 8,500 USDC (including interest)
Ratio: 105% 🚨 LIQUIDATABLE
Health Factor: 0.95
Action: AUTOMATIC LIQUIDATION
```

## 🖥️ FRONTEND INTEGRATION

### **Reading Metrics**
```javascript
// Get complete metrics
const metrics = await riskCalculator.calculateRiskMetrics(positionId);

// Display in UI
displayRiskLevel(metrics.riskLevel);
showHealthFactor(metrics.healthFactor / 1000000);
displayLiquidationPrice(metrics.liquidationPrice);
```

### **Real-time Monitoring**
```javascript
// Event subscription
loanManager.on('RiskLevelChanged', (positionId, oldLevel, newLevel) => {
    updatePositionUI(positionId, newLevel);
    if (newLevel >= 3) showCriticalAlert(positionId);
});

// Periodic updates
setInterval(async () => {
    const positions = await loanManager.getUserPositions(userAddress);
    for (const positionId of positions) {
        const metrics = await riskCalculator.calculateRiskMetrics(positionId);
        updateDashboard(positionId, metrics);
    }
}, 30000); // Every 30 seconds
```

## 🛡️ IMPLEMENTED PROTECTIONS

### **1. Oracle Validation**
```solidity
require(priceData.isValid, "Invalid price data");
require(block.timestamp - priceData.timestamp <= MAX_PRICE_AGE, "Price too stale");
```

### **2. Overflow Prevention**
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

## 🚀 COMPETITIVE ADVANTAGES

### **vs Aave/Compound**
| Feature | Aave/Compound | VCOP |
|---|---|---|
| **Available metrics** | 3-5 basic | 15+ advanced |
| **Predictive calculations** | ❌ No | ✅ Yes |
| **Portfolio analysis** | ❌ Limited | ✅ Complete |
| **Future projection** | ❌ No | ✅ With interest |
| **Volatility analysis** | ❌ No | ✅ Yes |
| **Real-time** | ✅ Basic | ✅ Advanced |

### **Unique Advantages**
- ✅ **Future risk projection** with interest accumulation
- ✅ **Price impact analysis** for different scenarios
- ✅ **Dynamic health factor** considering multiple variables
- ✅ **Complete portfolio monitoring** aggregated
- ✅ **Time-to-liquidation estimation**

## 🔄 USE CASES

### **For End Users**
1. **Daily monitoring** of positions
2. **Early alerts** for risk
3. **Collateral optimization**
4. **Strategy planning**

### **For Professional Traders**
1. **Advanced technical analysis**
2. **Sophisticated risk management**
3. **Arbitrage** with precise metrics
4. **Strategy backtesting**

### **For Liquidators**
1. **Opportunity identification**
2. **Profitability calculation**
3. **Automated monitoring**
4. **Gas optimization**

## 🔗 RELATED LINKS

- 🏗️ [Architecture](../architecture/) - System design
- 🚀 [Deployment](../deployment/) - Implementation
- 📚 [Main Documentation](../README.md) - General index
- 🧪 [Examples](../../examples/) - Example code 