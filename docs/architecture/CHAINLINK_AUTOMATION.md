# 🤖 Chainlink Automation System for VCOP Collateral

## 📋 Table of Contents
1. [System Overview](#-system-overview)
2. [Architecture Components](#-architecture-components)
3. [How It Works](#-how-it-works)
4. [Technical Deep Dive](#-technical-deep-dive)
5. [Configuration Guide](#-configuration-guide)
6. [Deployment Instructions](#-deployment-instructions)
7. [Monitoring & Troubleshooting](#-monitoring--troubleshooting)
8. [Advanced Features](#-advanced-features)

---

## 🚀 System Overview

The VCOP Collateral Automation System uses **Chainlink Automation v2.25.0** to automatically liquidate under-collateralized loan positions. The system operates 24/7 without human intervention, protecting the protocol from bad debt.

### 🎯 What Problems Does This Solve?

1. **24/7 Monitoring**: Continuously checks loan positions for liquidation opportunities
2. **Instant Price Response**: Reacts immediately to market price changes that affect collateral values
3. **Gas Efficiency**: Optimized batch processing reduces transaction costs
4. **Risk Management**: Multi-tier risk assessment prevents protocol losses
5. **Vault Integration**: Uses protocol's own liquidity for liquidations (no external liquidity required)

### 🔑 Key Benefits

- **Automated Protection**: No manual intervention needed
- **Cost Effective**: Chainlink Automation pays for gas from LINK tokens
- **Reliable**: Chainlink's proven infrastructure ensures uptime
- **Scalable**: Handles multiple loan managers simultaneously
- **Smart**: Dynamic risk assessment and priority-based liquidations

---

## 🏗️ Architecture Components

### Core Components Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    CHAINLINK AUTOMATION                    │
├─────────────────────┬───────────────────────────────────────┤
│   Custom Logic      │        Log Trigger                    │
│   Automation        │        Automation                     │
└─────────────────────┴───────────────────────────────────────┘
          │                           │
          ▼                           ▼
┌─────────────────────┐   ┌───────────────────────────┐
│ LoanAutomation      │   │ PriceChangeLogTrigger     │
│ KeeperOptimized     │   │                           │
└─────────────────────┘   └───────────────────────────┘
          │                           │
          └─────────────┬─────────────┘
                        ▼
              ┌─────────────────────┐
              │ LoanManagerAutomation│
              │ Adapter             │
              └─────────────────────┘
                        │
                        ▼
              ┌─────────────────────┐
              │ FlexibleLoanManager │
              │ (Your Protocol)     │
              └─────────────────────┘
```

### 1. **LoanAutomationKeeperOptimized** - The Scheduled Monitor

**Purpose**: Regularly scans loan positions and liquidates risky ones
**Trigger Type**: Custom Logic Automation (Time-based)
**Location**: `src/automation/core/LoanAutomationKeeperOptimized.sol`

**What it does:**
- Runs every few minutes (configurable)
- Scans batches of loan positions
- Identifies positions that can be liquidated
- Executes liquidations in order of risk priority
- Tracks performance metrics

**Key Fix**: Handles position ID mapping correctly (IDs start from 1, not 0)

### 2. **PriceChangeLogTrigger** - The Price Watcher

**Purpose**: Instantly responds to price changes that affect collateral values
**Trigger Type**: Log Trigger Automation (Event-based)
**Location**: `src/automation/core/PriceChangeLogTrigger.sol`

**What it does:**
- Listens for `TokenPriceUpdated` events from DynamicPriceRegistry
- Calculates price change percentage
- Determines urgency level based on change magnitude
- Triggers immediate liquidations for affected positions
- Activates "volatility mode" for extreme price moves

### 3. **LoanManagerAutomationAdapter** - The Protocol Bridge

**Purpose**: Connects Chainlink Automation with your FlexibleLoanManager
**Interface**: Implements `ILoanAutomation`
**Location**: `src/automation/core/LoanManagerAutomationAdapter.sol`

**What it does:**
- Maintains a live list of all active loan positions
- Calculates risk levels for positions
- Executes vault-funded liquidations
- Provides position health data
- Tracks liquidation success rates

### 4. **IAutomationRegistry** - The Manager Registry

**Purpose**: Manages which loan managers are monitored by automation
**Type**: Interface for registration system
**Location**: `src/automation/interfaces/IAutomationRegistry.sol`

**What it manages:**
- List of registered loan managers
- Priority levels for each manager
- Configuration settings (batch sizes, risk thresholds)
- Active/inactive status

---

## 🔄 How It Works

### The Two Automation Types Explained

#### 🕐 Custom Logic Automation (Scheduled Scanning)

This runs like a cron job, checking positions at regular intervals:

```
Time: 9:00 AM → Chainlink calls checkUpkeep()
                     ↓
               Scan positions 1-25
                     ↓
              Find 3 risky positions
                     ↓
              Execute liquidations
                     ↓
Time: 9:05 AM → Chainlink calls checkUpkeep()
                     ↓
               Scan positions 26-50
                     ↓
                   ... continues ...
```

#### ⚡ Log Trigger Automation (Event-Based Response)

This reacts instantly to price changes:

```
ETH price drops 8% → DynamicPriceRegistry emits event
                            ↓
                    Chainlink detects event
                            ↓
                   Calculate urgency (8% = "Urgent")
                            ↓
                Check all ETH-related positions
                            ↓
                 Liquidate risky positions immediately
```

### Complete System Flow

Here's what happens from start to finish:

#### Scenario 1: Scheduled Check (Custom Logic)

1. **Timer Triggers**: Chainlink calls `checkUpkeep()` every 5 minutes
2. **Position Query**: Get positions 1-25 from LoanManagerAdapter
3. **Risk Assessment**: Check each position's collateralization ratio
4. **Risk Prioritization**: Sort positions by risk level (highest first)
5. **Liquidation Execution**: Call `vaultFundedAutomatedLiquidation()` for risky positions
6. **Cooldown Applied**: Mark liquidated positions with cooldown to prevent spam
7. **Metrics Updated**: Record success/failure rates and gas usage

#### Scenario 2: Price Event Response (Log Trigger)

1. **Price Change**: DynamicPriceRegistry updates ETH price (down 10%)
2. **Event Detection**: Chainlink detects `TokenPriceUpdated` event
3. **Impact Analysis**: 10% change = "Immediate" urgency level
4. **Strategy Determination**: Use enhanced liquidation parameters
5. **Targeted Liquidation**: Focus on ETH-collateralized positions
6. **Volatility Mode**: Activate special mode for 1 hour if change ≥ 10%
7. **Execution**: Liquidate all affected risky positions immediately

### Position ID Mapping (Important Technical Detail)

**The Problem**: FlexibleLoanManager position IDs start from 1, but arrays start from 0.

**The Solution**: The keeper automatically converts:
- `startIndex=0` in checkData → `startPositionId=1` when querying positions
- This ensures we don't miss position ID 1 when scanning

**Example**:
```solidity
// In checkData: startIndex=0, batchSize=25
// Internally converts to: startPositionId=1, endPositionId=25
// Queries positions with IDs: 1, 2, 3, ..., 25
```

---

## 🔧 Technical Deep Dive

### Smart Contract Architecture

#### LoanAutomationKeeperOptimized.sol
```solidity
contract LoanAutomationKeeperOptimized is AutomationCompatible, Ownable {
    
    // Core configuration
    uint256 public minRiskThreshold = 85;        // Only liquidate if risk ≥ 85%
    uint256 public maxPositionsPerBatch = 20;    // Process 20 positions per upkeep
    uint256 public liquidationCooldown = 300;    // 5-minute cooldown between attempts
    
    // Registered loan managers
    mapping(address => bool) public registeredManagers;
    mapping(address => uint256) public managerPriority;
    
    // The main automation functions
    function checkUpkeep(bytes calldata checkData) external view override;
    function performUpkeep(bytes calldata performData) external override;
}
```

**Key Features:**
- **Gas-Optimized Batching**: Processes positions in small batches to avoid gas limits
- **Risk-Based Prioritization**: Always liquidates highest-risk positions first
- **Cooldown Protection**: Prevents repeated liquidation attempts on the same position
- **Emergency Pause**: Owner can pause the system if needed

#### PriceChangeLogTrigger.sol
```solidity
contract PriceChangeLogTrigger is ILogAutomation, Ownable {
    
    // Multi-tier price change thresholds
    uint256 public priceChangeThreshold = 50000;   // 5% (base threshold)
    uint256 public urgentThreshold = 75000;        // 7.5% (urgent response)
    uint256 public immediateThreshold = 100000;    // 10% (immediate action)
    uint256 public criticalThreshold = 150000;     // 15% (critical emergency)
    
    // Volatility detection
    mapping(address => bool) public assetInVolatilityMode;
    uint256 public volatilityModeDuration = 3600;  // 1 hour
    
    // The main log automation functions
    function checkLog(Log calldata log, bytes calldata checkData) external override;
    function performUpkeep(bytes calldata performData) external override;
}
```

**Urgency Levels:**
- **5-7.4%**: Normal response, standard liquidation parameters
- **7.5-9.9%**: Urgent response, increased batch size
- **10-14.9%**: Immediate response, lower risk thresholds
- **15%+**: Critical response, maximum liquidation effort + volatility mode

#### LoanManagerAutomationAdapter.sol
```solidity
contract LoanManagerAutomationAdapter is ILoanAutomation, Ownable {
    
    // Position tracking for efficiency
    uint256[] public allPositionIds;
    mapping(uint256 => bool) public isPositionTracked;
    
    // Risk assessment thresholds
    uint256 public criticalRiskThreshold = 95;    // Immediate liquidation
    uint256 public dangerRiskThreshold = 85;      // High priority
    uint256 public warningRiskThreshold = 75;     // Standard priority
    
    // Core automation functions
    function isPositionAtRisk(uint256 positionId) external view returns (bool, uint256);
    function vaultFundedAutomatedLiquidation(uint256 positionId) external returns (bool, uint256);
}
```

**Risk Assessment Logic:**
```solidity
function isPositionAtRisk(uint256 positionId) external view returns (bool isAtRisk, uint256 riskLevel) {
    // Get collateralization ratio from FlexibleLoanManager
    uint256 ratio = loanManager.getCollateralizationRatio(positionId);
    
    if (ratio <= 1050000) {        // Below 105%
        riskLevel = 100;           // Critical risk
    } else if (ratio <= 1100000) { // Below 110%
        riskLevel = 95;            // Immediate danger
    } else if (ratio <= 1200000) { // Below 120%
        riskLevel = 85;            // High risk
    } else if (ratio <= 1350000) { // Below 135%
        riskLevel = 75;            // Moderate risk
    } else {
        riskLevel = 50;            // Low risk
    }
    
    isAtRisk = loanManager.canLiquidate(positionId);
}
```

### Vault-Funded Liquidations

The system uses **vault-funded liquidations**, which means:

1. **No External Liquidity Required**: The protocol's own vault provides liquidity
2. **Automatic Token Management**: Keeper doesn't need to hold any tokens
3. **Direct Integration**: Calls `FlexibleLoanManager.vaultFundedAutomatedLiquidation()`
4. **Efficient Execution**: Single transaction liquidates the position

**Benefits:**
- Keepers don't need to maintain token balances
- Lower barriers to entry for automation
- Protocol retains control over liquidation logic
- Reduced complexity and gas costs

---

## ⚙️ Configuration Guide

### Environment Variables Setup

Create a `.env` file with these variables:

```bash
# Required Contract Addresses
FLEXIBLE_LOAN_MANAGER=0x1234...               # Your FlexibleLoanManager address
DYNAMIC_PRICE_REGISTRY=0x5678...              # Your price oracle address
AUTOMATION_REGISTRY=0x91D4...                 # Chainlink's official registry (Base Sepolia)

# Automation Parameters
MIN_RISK_THRESHOLD=85                         # Liquidate positions with ≥85% risk
MAX_POSITIONS_PER_BATCH=25                    # Process 25 positions per upkeep
LIQUIDATION_COOLDOWN=300                      # 5-minute cooldown between attempts
MAX_GAS_PER_UPKEEP=2500000                   # Gas limit for each upkeep

# Price Change Thresholds (in basis points, 6 decimals)
PRICE_CHANGE_THRESHOLD=50000                  # 5% basic threshold
URGENT_THRESHOLD=75000                        # 7.5% urgent threshold
IMMEDIATE_THRESHOLD=100000                    # 10% immediate threshold
CRITICAL_THRESHOLD=150000                     # 15% critical threshold

# Volatility Detection
VOLATILITY_BOOST_THRESHOLD=100000             # 10% activates volatility mode
VOLATILITY_MODE_DURATION=3600                 # 1 hour volatility mode duration

# Network Configuration
RPC_URL=https://sepolia.base.org              # Base Sepolia RPC
PRIVATE_KEY=0xabcd...                         # Deployer private key
ETHERSCAN_API_KEY=ABC123...                   # For contract verification
```

### Contract Configuration Functions

#### Configure the Keeper
```solidity
// Set risk parameters
loanKeeper.setMinRiskThreshold(85);           // Only liquidate if risk ≥ 85%
loanKeeper.setMaxPositionsPerBatch(25);       // Process 25 positions per batch
loanKeeper.setLiquidationCooldown(300);       // 5-minute cooldown

// Register loan managers
loanKeeper.registerLoanManager(adapterAddress, 100);  // Priority 100 (highest)

// Emergency controls
loanKeeper.setEmergencyPause(false);          // Ensure system is active
```

#### Configure the Price Trigger
```solidity
// Set price change thresholds
priceLogTrigger.setPriceChangeThresholds(
    50000,   // 5% basic threshold
    75000,   // 7.5% urgent threshold
    100000,  // 10% immediate threshold
    150000   // 15% critical threshold
);

// Configure volatility mode
priceLogTrigger.setVolatilityParameters(
    100000,  // 10% activates volatility mode
    3600     // 1 hour duration
);

// Register loan managers
priceLogTrigger.registerLoanManager(adapterAddress, 100);
```

#### Configure the Adapter
```solidity
// Set risk assessment thresholds
loanAdapter.setRiskThresholds(
    95,  // Critical threshold (immediate liquidation)
    85,  // Danger threshold (high priority)
    75   // Warning threshold (standard priority)
);

// Set automation contract
loanAdapter.setAutomationContract(loanKeeperAddress);

// Initialize position tracking (for existing positions)
uint256[] memory existingPositions = getExistingPositions();
loanAdapter.initializePositionTracking(existingPositions);
```

---

## 🚀 Deployment Instructions

### Step 1: Deploy Contracts

```bash
# Deploy the complete automation system
forge script script/automation/DeployAutomationClean.s.sol \
    --broadcast \
    --verify \
    --rpc-url $RPC_URL \
    --etherscan-api-key $ETHERSCAN_API_KEY

# This deploys:
# - LoanAutomationKeeperOptimized
# - PriceChangeLogTrigger  
# - LoanManagerAutomationAdapter
```

### Step 2: Configure Contracts

```bash
# Configure the automation adapter
forge script script/automation/ConfigureAutomationAdapter.s.sol \
    --broadcast \
    --rpc-url $RPC_URL

# Configure the keeper
forge script script/automation/ConfigureAutomationKeeper.s.sol \
    --broadcast \
    --rpc-url $RPC_URL

# Configure the price trigger
forge script script/automation/ConfigurePriceLogTrigger.s.sol \
    --broadcast \
    --rpc-url $RPC_URL
```

### Step 3: Register with Chainlink Automation

#### Register Custom Logic Upkeep

1. Go to [Chainlink Automation App](https://automation.chain.link/)
2. Click "Register new Upkeep"
3. Select "Custom logic"
4. Fill in the details:

```
Contract Address: [LoanAutomationKeeperOptimized address]
Admin Address: [Your address]
Gas Limit: 2,500,000
Starting Balance: 10 LINK
Check Data: [Use generateOptimizedCheckData function result]
```

**Generate Check Data:**
```bash
# Generate checkData for registration
cast call $LOAN_AUTOMATION_KEEPER \
    "generateOptimizedCheckData(address,uint256,uint256)" \
    $LOAN_ADAPTER_ADDRESS \
    0 \
    25

# Use the returned bytes as "Check Data" in the Chainlink UI
```

#### Register Log Trigger Upkeep

1. In Chainlink Automation App, click "Register new Upkeep"
2. Select "Log trigger"
3. Fill in the details:

```
Contract Address: [PriceChangeLogTrigger address]
Admin Address: [Your address]  
Gas Limit: 2,000,000
Starting Balance: 5 LINK

Log Configuration:
- Emitting Contract Address: [DynamicPriceRegistry address]
- Topic 0: [TokenPriceUpdated event signature]
- Topic 1: (leave empty for all tokens)
```

**Get Event Signature:**
```bash
# Get the TokenPriceUpdated event signature
cast sig-event "TokenPriceUpdated(address,uint256,uint8)"
# Result: 0x1234... (use this as Topic 0)
```

### Step 4: Fund and Activate

1. **Fund Upkeeps**: Add LINK tokens to both upkeeps in the Chainlink UI
2. **Activate**: Ensure both upkeeps are "Active" in the dashboard
3. **Test**: Monitor the upkeeps for the first few executions

---

## 📊 Monitoring & Troubleshooting

### System Health Checks

#### Check Keeper Status
```bash
# Get keeper statistics
cast call $LOAN_AUTOMATION_KEEPER \
    "getStats()" \
    --rpc-url $RPC_URL

# Returns: (totalLiquidations, totalUpkeeps, lastExecution, averageGas, managersCount)
```

#### Check Adapter Status  
```bash
# Get position tracking stats
cast call $LOAN_ADAPTER \
    "getTrackingStats()" \
    --rpc-url $RPC_URL

# Returns: (totalTracked, totalAtRisk, totalLiquidatable, totalCritical, performanceStats)
```

#### Check Price Trigger Status
```bash
# Get price trigger statistics  
cast call $PRICE_CHANGE_LOG_TRIGGER \
    "getStatistics()" \
    --rpc-url $RPC_URL

# Returns: (totalTriggers, totalLiquidations, totalVolatility, lastTrigger, activeVolatileAssets)
```

### Common Issues and Solutions

#### Issue 1: Upkeep Not Executing
**Symptoms**: No recent executions in Chainlink dashboard
**Causes & Solutions**:
- **Insufficient LINK**: Add more LINK to upkeep balance
- **Gas limit too low**: Increase gas limit to 2.5M
- **Emergency pause active**: Call `setEmergencyPause(false)`
- **No liquidatable positions**: Normal if all positions are healthy

#### Issue 2: Liquidations Failing
**Symptoms**: Upkeep runs but no liquidations occur
**Causes & Solutions**:
- **Authorization missing**: Call `loanAdapter.setAutomationContract(keeperAddress)`
- **Insufficient vault liquidity**: Add liquidity to vault
- **Risk thresholds too high**: Lower `minRiskThreshold` 
- **Cooldown too long**: Reduce `liquidationCooldown`

#### Issue 3: Price Events Not Triggering
**Symptoms**: Price changes but no log triggers
**Causes & Solutions**:
- **Wrong event signature**: Verify Topic 0 matches TokenPriceUpdated
- **Wrong contract address**: Verify emitting contract is DynamicPriceRegistry  
- **Threshold too high**: Lower `priceChangeThreshold`
- **Emergency pause**: Call `setEmergencyPause(false)`

#### Issue 4: Position Tracking Out of Sync
**Symptoms**: Adapter reports wrong position counts
**Solution**:
```bash
# Sync position tracking
cast send $LOAN_ADAPTER \
    "syncPositionTracking()" \
    --private-key $PRIVATE_KEY \
    --rpc-url $RPC_URL
```

### Performance Monitoring

#### Key Metrics to Track

1. **Liquidation Success Rate**: Should be >90%
2. **Average Gas Usage**: Should be <2.5M per upkeep
3. **Response Time**: Price events should trigger within 1-2 blocks
4. **Position Coverage**: All active positions should be tracked

#### Setting Up Alerts

Monitor these events for alerts:
- `LiquidationAttempted` with `success=false`
- `EmergencyPaused` events
- Gas usage approaching limits
- LINK balance getting low

---

## 🎯 Advanced Features

### Multi-Tier Risk Assessment

The system uses sophisticated risk assessment:

```
Risk Level 100: Emergency liquidation (ratio ≤ 105%)
Risk Level 95:  Critical liquidation (ratio ≤ 110%)  
Risk Level 85:  High priority (ratio ≤ 120%)
Risk Level 75:  Standard priority (ratio ≤ 135%)
Risk Level 50:  Monitor only (ratio ≤ 150%)
```

### Volatility Mode

When price changes ≥10%, the system enters "volatility mode":
- **Duration**: 1 hour (configurable)
- **Effects**: Lower risk thresholds, larger batch sizes
- **Purpose**: Aggressive liquidation during market stress

### Gas Optimization

The system includes several gas optimizations:
- **Batch Processing**: Multiple positions per transaction
- **Early Termination**: Stops before running out of gas
- **Risk Prioritization**: Liquidates highest-risk positions first
- **Cooldown Prevention**: Avoids redundant liquidation attempts

### Vault Integration

The **vault-funded liquidation** feature:
- Uses protocol's own liquidity pool
- No external token requirements for keepers
- Automatic token management
- Seamless integration with FlexibleLoanManager

---

## 📈 System Specifications

### Chainlink Versions
- **AutomationCompatible**: v2.25.0
- **ILogAutomation**: v2.25.0
- **All interfaces**: Official Chainlink contracts

### Compatibility  
- **Solidity**: ^0.8.24 - ^0.8.26
- **FlexibleLoanManager**: ✅ Full integration
- **DynamicPriceRegistry**: ✅ Native support
- **Multi-Asset Support**: ✅ All supported tokens

### Performance Limits
- **Max Batch Size**: 100 positions per upkeep
- **Max Gas Limit**: 5,000,000 per upkeep  
- **Min Cooldown**: 60 seconds between liquidations
- **Max Managers**: Unlimited (subject to gas limits)

### Security Features
- **Owner Controls**: Emergency pause, parameter updates
- **Authorization**: Only authorized contracts can trigger liquidations
- **Cooldown Protection**: Prevents liquidation spam
- **Gas Reservation**: Prevents out-of-gas failures

---

## 🔗 Additional Resources

- [Chainlink Automation Docs](https://docs.chain.link/chainlink-automation)
- [Base Sepolia Automation Registry](https://sepolia.basescan.org/address/0x91D4a4C3D448c7f3CB477332B1c7D420a5810aC3)
- [FlexibleLoanManager Integration Guide](../../src/core/README.md)
- [DynamicPriceRegistry Documentation](../../src/interfaces/IPriceRegistry.sol)

---

*This automation system provides complete, reliable, and efficient liquidation management for the VCOP Collateral protocol.* 