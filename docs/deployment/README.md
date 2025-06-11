# 🚀 DEPLOYMENT AND IMPLEMENTATION

This section contains all documentation related to deployment, configuration and implementation of the protocol in production.

## 📁 CONTENT

### 🚀 [CORRECTED_SYSTEM_DEPLOYMENT.md](./SISTEMA_CORREGIDO_DESPLIEGUE.md) ⭐ **NEW**
**Complete Guide for Corrected Collateralized Lending System**

**Includes:**
- ✅ Complete corrected deployment procedure
- ✅ Automated oracle configuration
- ✅ Solution to hardcoded address problems
- ✅ Automated workflow without manual intervention
- ✅ System verification and testing
- ✅ Success metrics and validation

### 🚨 [TROUBLESHOOTING.md](./TROUBLESHOOTING.md) ⭐ **NEW**
**Common Problem Solutions**

**Includes:**
- ✅ "Insufficient collateral" error and its solution
- ✅ Oracle problems (incorrect prices)
- ✅ Obsolete hardcoded addresses
- ✅ Diagnostic and recovery commands
- ✅ Pre-deployment verification checklist

### ⚡ [QUICK_REFERENCE.md](./REFERENCIA_RAPIDA.md) ⭐ **NEW**
**Immediate Reference Commands and Values**

**Includes:**
- ✅ Essential deployment and testing commands
- ✅ Quick solutions to common problems
- ✅ Configuration values and oracle prices
- ✅ Address template for updates
- ✅ Quick verification checklist

### 📄 [DEPLOYMENT_INSTRUCTIONS.md](./INSTRUCCIONES_DESPLIEGUE.md) 🔄 **UPDATED**
**Deployment guide for VCOP and legacy systems**

**Includes:**
- ✅ Collateralized lending system (new)
- ✅ Automated configuration scripts
- ✅ Original VCOP system (legacy)
- ✅ Cross-references to new documentation

### 📄 [PSM-README.md](./PSM-README.md)
**Peg Stability Module - Configuration and operation**

**Includes:**
- ✅ Technical explanation of PSM
- ✅ Configuration parameters
- ✅ Integration with VCOPCollateralHook
- ✅ Stabilization mechanisms
- ✅ Monitoring and adjustments

## 🎯 DEPLOYMENT STRATEGY

### **Gradual Phase Approach**

#### **Phase 1: Core Infrastructure** 
```bash
# Base contracts
FlexibleLoanManager.sol
FlexibleAssetHandler.sol  
GenericOracle.sol
RiskCalculator.sol
```

#### **Phase 2: Asset Integration**
```bash
# Main asset configuration
VCOP (Mintable)
ETH (Vault-based)
WBTC (Vault-based)
USDC (Vault-based)
```

#### **Phase 3: Hook Integration**
```bash
# Uniswap v4 integration
VCOPCollateralHook.sol
PSM Configuration
Price Monitoring
```

#### **Phase 4: Advanced Features**
```bash
# Advanced features
Advanced risk metrics
Portfolio management
Liquidation automation
```

#### **Phase 5: Production Migration**
```bash
# Production migration
User migration tools
Interface upgrades
Legacy system sunset
```

## 🛠️ DEPLOYMENT TOOLS

### **Automated Scripts**
```bash
script/
├── deploy/
│   ├── DeployNewArchitecture.s.sol    # Complete deployment
│   ├── ConfigureAssets.s.sol          # Asset configuration
│   └── SetupOracles.s.sol             # Oracle configuration
├── configure/
│   ├── ConfigureVCOPSystem.sol        # VCOP system
│   └── SetupPSM.s.sol                 # PSM configuration
└── verify/
    ├── VerifyContracts.s.sol          # Automatic verification
    └── ValidateDeployment.s.sol       # Post-deployment validation
```

### **Network Configuration**

#### **Mainnet Production**
```solidity
// Conservative parameters
uint256 liquidationBonus = 50000;      // 5%
uint256 protocolFee = 5000;            // 0.5%
uint256 maxLoanAmount = 1000000e18;    // 1M tokens max
bool strictValidation = true;          // Strict validations
```

#### **Testnet Development**
```solidity
// Flexible parameters for testing
uint256 liquidationBonus = 100000;     // 10%
uint256 protocolFee = 10000;           // 1%
uint256 maxLoanAmount = 10000e18;      // 10K tokens max
bool strictValidation = false;         // Relaxed validations
```

## 📋 DEPLOYMENT CHECKLIST

### **Pre-Deployment**
- [ ] ✅ Complete security audit
- [ ] ✅ Exhaustive testnet testing
- [ ] ✅ Verified oracle configuration
- [ ] ✅ Defined network parameters
- [ ] ✅ Validated deployment scripts
- [ ] ✅ Prepared rollback plan

### **During Deployment**
- [ ] ⚙️ Deploy base contracts
- [ ] ⚙️ Configure asset handlers
- [ ] ⚙️ Configure oracles
- [ ] ⚙️ Verify contracts on etherscan
- [ ] ⚙️ Configure PSM
- [ ] ⚙️ Integration testing

### **Post-Deployment**
- [ ] ✅ Functionality verification
- [ ] ✅ Metrics monitoring
- [ ] ✅ Updated documentation
- [ ] ✅ Updated user interfaces
- [ ] ✅ User communication
- [ ] ✅ 24/7 continuous monitoring

## 🔧 TECHNICAL CONFIGURATION

### **Environment Variables**
```bash
# Network configuration
ETHEREUM_RPC_URL=https://mainnet.infura.io/v3/YOUR_KEY
POLYGON_RPC_URL=https://polygon-mainnet.infura.io/v3/YOUR_KEY
BSC_RPC_URL=https://bsc-dataseed.binance.org/

# Deployment keys
DEPLOYER_PRIVATE_KEY=0x...
MULTISIG_ADDRESS=0x...

# Verification configuration
ETHERSCAN_API_KEY=YOUR_ETHERSCAN_KEY
POLYGONSCAN_API_KEY=YOUR_POLYGONSCAN_KEY

# Oracles
CHAINLINK_ETH_USD=0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
CHAINLINK_BTC_USD=0xF4030086522a5bEEa4988F8cA5B36dbC97BeE88c
```

### **Gas Configuration**
```solidity
// Gas optimization per network
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

## 🔍 VALIDATION AND TESTING

### **Automated Testing**
```bash
# Complete test suite
forge test --fork-url $ETHEREUM_RPC_URL
forge test --fork-url $POLYGON_RPC_URL
forge test --fork-url $BSC_RPC_URL

# Component-specific tests
forge test --match-contract FlexibleLoanManagerTest
forge test --match-contract RiskCalculatorTest
forge test --match-contract AssetHandlerTest
```

### **Post-Deployment Verification**
```solidity
// Automatic validation script
contract ValidateDeployment {
    function validateFullSystem() external {
        // 1. Verify deployed contracts
        require(address(loanManager) != address(0), "LoanManager not deployed");
        require(address(assetHandler) != address(0), "AssetHandler not deployed");
        
        // 2. Verify configurations
        require(loanManager.protocolFee() == EXPECTED_FEE, "Wrong protocol fee");
        
        // 3. Basic functionality testing
        testCreateLoan();
        testLiquidation();
        testRiskCalculations();
        
        // 4. Verify integrations
        testOracleIntegration();
        testPSMFunctionality();
    }
}
```

## 📊 POST-DEPLOYMENT MONITORING

### **Key Metrics**
```javascript
// Monitoring dashboard
const metrics = {
    totalValueLocked: await getTVL(),
    activeLoans: await getActiveLoansCount(),
    liquidationsLast24h: await getLiquidations24h(),
    healthFactorDistribution: await getHealthFactorStats(),
    protocolRevenue: await getProtocolRevenue(),
    gasUsageOptimization: await getGasMetrics()
};
```

### **Alert System**
```javascript
// Automated alert system
const alerts = {
    lowHealthFactors: checkLowHealthFactors(),      // < 1.2
    oracleFailures: checkOracleStatus(),           // Price feed issues
    liquidationBacklog: checkLiquidationQueue(),   // > 10 pending
    unusualVolume: checkVolumeSpikes(),            // > 10x normal
    contractPause: checkEmergencyState()           // System paused
};
```

### **Performance Monitoring**
```solidity
// On-chain performance tracking
contract PerformanceMonitor {
    mapping(bytes32 => uint256) public functionCosts;
    mapping(address => uint256) public userGasSavings;
    
    function trackGasUsage(string memory functionName) external {
        uint256 gasStart = gasleft();
        // Function execution
        uint256 gasUsed = gasStart - gasleft();
        functionCosts[keccak256(abi.encode(functionName))] = gasUsed;
    }
}
```

## 🔄 UPGRADE STRATEGY

### **Contract Upgradeability**
```solidity
// Proxy pattern for upgrades
contract VCOPProxy {
    address public implementation;
    address public admin;
    
    function upgrade(address newImplementation) external onlyAdmin {
        implementation = newImplementation;
        emit Upgraded(newImplementation);
    }
}
```

### **Migration Process**
```bash
# Staged migration process
1. Deploy new contracts alongside old ones
2. Test new contracts with limited functionality
3. Gradually migrate user positions
4. Sunset old contracts after full migration
5. Update all external integrations
```

## 🔗 RELATED LINKS

- 🏗️ [Architecture](../architecture/) - System design
- 📊 [Risk Management](../risk-management/) - Risk calculations
- 📚 [Main Documentation](../README.md) - General index
- 🧪 [Examples](../../examples/) - Code examples 
- 📜 [Scripts](../../script/) - Scripts de despliegue 