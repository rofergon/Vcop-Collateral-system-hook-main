# 🤖 Enhanced Chainlink Automation System

## 🚀 Overview

This is the **UPDATED** Chainlink Automation system, redesigned to work seamlessly with the new `FlexibleLoanManager`, `DynamicPriceRegistry`, and updated asset handlers. The system provides automated liquidation capabilities with intelligent risk assessment and dynamic price monitoring.

## 📋 Architecture

### Core Components

1. **LoanAutomationKeeper** - Enhanced main automation contract with priority-based liquidation
2. **LoanManagerAutomationAdapter** - Updated adapter for FlexibleLoanManager integration 
3. **PriceChangeLogTrigger** - Advanced log-based trigger with volatility detection
4. **AutomationRegistry** - Management and coordination of automation components

### Key Features ⚡

- **✅ Compatible with FlexibleLoanManager** - Works with the new ultra-flexible loan system
- **✅ Dynamic Price Integration** - Uses DynamicPriceRegistry for real-time pricing  
- **✅ Multi-tier Risk Assessment** - Critical/Immediate/Urgent/Normal liquidation levels
- **✅ Volatility Mode** - Special handling during high price volatility
- **✅ Priority-based Liquidation** - Liquidates highest risk positions first
- **✅ Gas Optimization** - Intelligent gas management and batch processing
- **✅ Enhanced Security** - Forwarder pattern and emergency pause mechanisms

## 🔧 Configuration

### Environment Variables

```bash
# Required
FLEXIBLE_LOAN_MANAGER=0x...        # Address of your FlexibleLoanManager
DYNAMIC_PRICE_REGISTRY=0x...       # Address of your DynamicPriceRegistry
PRIVATE_KEY=0x...                  # Deployer private key

# Optional (with defaults)
MAX_GAS_PER_UPKEEP=2500000        # Maximum gas per automation execution
MIN_RISK_THRESHOLD=75             # Minimum risk level for liquidation (%)
LIQUIDATION_COOLDOWN=180          # Cooldown between liquidation attempts (seconds)
ENABLE_VOLATILITY_MODE=true       # Enable enhanced volatility detection
```

### Risk Thresholds

The system uses a multi-tier risk assessment:

- **🔴 Critical (95%+)**: Immediate liquidation with maximum priority
- **🟠 Immediate (85-94%)**: High priority liquidation 
- **🟡 Urgent (75-84%)**: Standard priority liquidation
- **🟢 Normal (60-74%)**: Monitoring only
- **⚪ Safe (<60%)**: No action needed

## 🚀 Deployment

### 1. Deploy the System

```bash
# Set environment variables
export FLEXIBLE_LOAN_MANAGER=0x...
export DYNAMIC_PRICE_REGISTRY=0x...

# Deploy automation system
forge script script/automation/DeployAutomation.s.sol --broadcast --verify
```

### 2. Register with Chainlink Automation

#### Custom Logic Upkeep
- **Contract Address**: `LoanAutomationKeeper` address from deployment
- **checkData**: Generate using `loanKeeper.generateStandardCheckData(adapterAddress, 0, 25)`
- **Gas Limit**: 2,500,000 (recommended)

#### Log Trigger Upkeep  
- **Contract Address**: `PriceChangeLogTrigger` address from deployment
- **Log Filter**: Price update events from your DynamicPriceRegistry
- **Gas Limit**: 2,000,000 (recommended)

### 3. Fund Upkeeps

Send LINK tokens to your registered upkeeps through the Chainlink Automation UI.

## ⚙️ Configuration Functions

### LoanAutomationKeeper

```solidity
// Set risk thresholds
loanKeeper.setMinRiskThreshold(75);

// Configure gas limits
loanKeeper.setMaxGasPerUpkeep(2500000);
loanKeeper.setMaxPositionsPerBatch(25);

// Enable volatility monitoring
loanKeeper.setPriceVolatilityThreshold(50000); // 5%

// Emergency controls
loanKeeper.setEmergencyPause(true/false);
```

### LoanManagerAutomationAdapter

```solidity
// Set dynamic risk thresholds
loanAdapter.setRiskThresholds(
    95,  // Critical threshold
    85,  // Danger threshold  
    75   // Warning threshold
);

// Configure liquidation timing
loanAdapter.setLiquidationCooldown(180); // 3 minutes

// Connect to automation
loanAdapter.setAutomationContract(loanKeeperAddress);
```

### PriceChangeLogTrigger

```solidity
// Set price change thresholds
priceLogTrigger.setPriceChangeThresholds(
    50000,   // 5% basic
    75000,   // 7.5% urgent
    100000,  // 10% immediate
    150000   // 15% critical
);

// Configure volatility detection
priceLogTrigger.setVolatilityParameters(
    100000, // 10% volatility threshold
    3600    // 1 hour volatility duration
);

// Register loan managers
priceLogTrigger.registerLoanManager(adapterAddress, 100); // Priority 0-100
```

## 📊 Integration with FlexibleLoanManager

### Position Tracking

The adapter automatically tracks positions from the FlexibleLoanManager:

```solidity
// Initialize position tracking for existing positions
uint256[] memory existingPositions = getExistingPositionIds();
loanAdapter.initializePositionTracking(existingPositions);

// Automatic tracking for new positions (integrate in loan manager)
loanAdapter.addPositionToTracking(newPositionId);
```

### Risk Assessment

The system uses the FlexibleLoanManager's built-in functions:

- `canLiquidate(positionId)` - Direct liquidation eligibility
- `getCollateralizationRatio(positionId)` - Real-time health factor
- `liquidatePosition(positionId)` - Automated liquidation execution

## 🔥 Dynamic Price Integration

### Price Registry Connection

The system automatically monitors price changes from DynamicPriceRegistry:

```solidity
// The system listens for TokenPriceUpdated events
event TokenPriceUpdated(address indexed token, uint256 newPrice, uint8 decimals);
```

### Volatility Detection

When price changes exceed thresholds, the system:

1. **Activates Volatility Mode** - Enhanced monitoring for 1 hour
2. **Reduces Risk Thresholds** - More aggressive liquidation
3. **Increases Batch Sizes** - Processes more positions per execution
4. **Prioritizes High-Risk Positions** - Liquidates critical positions first

## 📈 Monitoring & Analytics

### Get System Statistics

```solidity
// Automation performance
(uint256 totalLiquidations, uint256 totalUpkeeps, uint256 avgPositions, uint256 lastExecution) = 
    loanKeeper.getAutomationStats();

// Position tracking stats
(uint256 tracked, uint256 atRisk, uint256 liquidatable, uint256 critical, uint256 performance) = 
    loanAdapter.getTrackingStats();

// Price monitoring stats
(uint256 triggers, uint256 liquidations, uint256 volatilityEvents, uint256 lastTrigger) = 
    priceLogTrigger.getStatistics();
```

### Real-time Position Monitoring

```solidity
// Get all positions at risk
(uint256[] memory riskPositions, uint256[] memory riskLevels) = 
    loanAdapter.getPositionsAtRisk();

// Check specific position
(bool isAtRisk, uint256 riskLevel) = loanAdapter.isPositionAtRisk(positionId);
```

## 🚨 Emergency Procedures

### Emergency Pause

```solidity
// Pause all automation systems
forge script script/automation/DeployAutomation.s.sol:DeployAutomation --sig "emergencyPauseAll()"

// Resume after fixing issues
forge script script/automation/DeployAutomation.s.sol:DeployAutomation --sig "resumeAutomation()"
```

### Manual Liquidation

If automation fails, positions can still be liquidated manually:

```solidity
// Direct liquidation through FlexibleLoanManager
flexibleLoanManager.liquidatePosition(positionId);
```

## 🔍 Troubleshooting

### Common Issues

1. **Upkeep Not Triggering**
   - Check LINK balance in upkeep
   - Verify checkData format
   - Ensure positions exist and are at risk

2. **Liquidations Failing**
   - Check liquidation cooldown periods
   - Verify position is still liquidatable
   - Ensure sufficient gas limits

3. **Price Triggers Not Working**
   - Verify log filter configuration
   - Check price change thresholds
   - Ensure DynamicPriceRegistry is emitting events

### Debug Functions

```solidity
// Test checkUpkeep manually
bytes memory checkData = loanKeeper.generateStandardCheckData(adapterAddress, 0, 25);
(bool needed, bytes memory performData) = loanKeeper.checkUpkeep(checkData);

// Check position health
(address borrower, uint256 collateralValue, uint256 debtValue, uint256 healthFactor) = 
    loanAdapter.getPositionHealthData(positionId);
```

## 🎯 Best Practices

### Gas Optimization

- **Batch Size**: Start with 25 positions per batch, adjust based on gas usage
- **Risk Thresholds**: Use 75% minimum to balance safety vs. efficiency  
- **Cooldown Periods**: 3 minutes minimum to prevent spam

### Risk Management

- **Monitor Volatility Mode**: Check when assets enter high volatility periods
- **Track Failure Rates**: Monitor liquidation success rates
- **Emergency Planning**: Have manual liquidation procedures ready

### Performance Tuning

- **Adjust Thresholds**: Fine-tune based on market conditions
- **Monitor Gas Usage**: Optimize batch sizes for cost efficiency
- **Track Statistics**: Use analytics to improve system performance

## 📚 Additional Resources

- [Chainlink Automation Documentation](https://docs.chain.link/chainlink-automation)
- [FlexibleLoanManager Guide](../core/README.md)
- [DynamicPriceRegistry Documentation](../interfaces/IPriceRegistry.sol)

## 🤝 Support

For technical support or questions about the automation system:

1. Check the troubleshooting section above
2. Review system logs and events
3. Test with manual function calls
4. Verify all configuration parameters

The enhanced automation system is designed to work seamlessly with your updated lending protocol while providing maximum flexibility and safety for automated liquidations. 