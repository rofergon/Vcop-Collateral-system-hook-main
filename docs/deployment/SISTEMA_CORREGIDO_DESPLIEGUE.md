# 🚀 Collateralized Loan System - Corrected Deployment Guide

## ⚡ **NEW: AUTOMATED COMMANDS** (RECOMMENDED)

### **🎯 Ultra-Fast Deployment**
```bash
# ✅ NEW: One-command complete deployment (recommended)
make deploy-complete
```
**Includes:** Core + VCOP + Rewards + Auto-configuration + Authorization

### **🧪 Ultra-Fast Testing**
```bash
# ✅ NEW: One-command complete testing (recommended) 
make test-all
```
**Tests:** Rewards + Core + VCOP systems comprehensively

> **💡 TIP**: For new deployments, use the commands above. The detailed procedures below are for reference and specific scenarios.

---

## 📋 Executive Summary

This guide documents the **complete and corrected** procedure for deploying the collateralized loan system. It includes all implemented fixes to resolve oracle issues, hardcoded addresses, and automated configuration.

---

## 🎯 System Components

### **Core Contracts**
- **MockOracle**: Price system with dynamic configuration
- **GenericLoanManager**: Main loan manager
- **VaultBasedHandler**: Asset handler with vaults
- **Mock Tokens**: ETH, WBTC, USDC for testing

### **Key Configurations**
- **ETH**: 130% collateral, 110% liquidation, 8% interest, $3,000 price
- **WBTC**: 140% collateral, 115% liquidation, 7.5% interest, $95,000 price
- **USDC**: 110% collateral, 105% liquidation, 4% interest, $1 price

---

## 🛠️ Environment Preparation

### **1. Configure Environment Variables**
```bash
# Create .env file
cat > .env << EOF
PRIVATE_KEY=your_private_key_here
RPC_URL=https://sepolia.base.org
ETHERSCAN_API_KEY=your_api_key_here
EOF
```

### **2. Verify Tools**
```bash
# Verify Foundry
forge --version
cast --version

# Verify network connection
cast chain-id --rpc-url https://sepolia.base.org

# Verify gas balance
cast balance $DEPLOYER_ADDRESS --rpc-url https://sepolia.base.org --ether
```

---

## 🚀 Deployment Procedure

### **🔥 NEW: Complete Automated Deployment (RECOMMENDED)**
```bash
# ✅ NEW: Complete automated deployment + configuration + authorization
make deploy-complete
```

**This NEW command automatically:**
1. ✅ Compiles contracts with optimizations
2. ✅ Deploys unified system (Core + VCOP + Rewards)
3. ✅ Configures all system integrations and authorizations
4. ✅ Verifies deployment status
5. ✅ Updates deployed-addresses.json automatically

### **Legacy: Manual Deployment (For Reference)**

#### **Main Command (Original)**
```bash
# Original automated deployment
make deploy-corrected-system
```

**This command deploys:**
1. ✅ Mock Tokens (ETH, WBTC, USDC)
2. ✅ MockOracle with correct prices
3. ✅ Asset Handlers (Vault, Flexible, MintableBurnable)
4. ✅ Loan Managers (Generic, Flexible)
5. ✅ Automatic asset configuration
6. ✅ Ratio and parameter configuration

#### **Expected Output**
```
=== DEPLOYMENT ADDRESSES (Copy these for tests) ===
MOCK_ETH: 0xAbC123...
MOCK_WBTC: 0xDeF456...
MOCK_USDC: 0x789GhI...
MOCK_ORACLE: 0xJkL012...
GENERIC_LOAN_MANAGER: 0xMnO345...
FLEXIBLE_LOAN_MANAGER: 0xPqR678...
VAULT_BASED_HANDLER: 0xStU901...
```

---

## ⚙️ Post-Deployment Configuration

> **💡 NOTE**: If using `make deploy-complete`, most configuration is automatic. These steps are for manual deployments.

### **1. Update Test Scripts**

**Location:** `script/TestCoreLoans.s.sol`

```solidity
// Update these addresses with the output ones
address constant MOCK_ETH = 0xNewAddresses...;
address constant MOCK_WBTC = 0xNewAddresses...;
address constant MOCK_USDC = 0xNewAddresses...;
address constant MOCK_ORACLE = 0xNewAddresses...;
address constant GENERIC_LOAN_MANAGER = 0xNewAddresses...;
address constant VAULT_BASED_HANDLER = 0xNewAddresses...;
```

### **2. Update Liquidity Commands**

**Location:** `Makefile` - `provide-corrected-liquidity` section

```bash
# Update addresses in cast send commands
ETH_ADDRESS=0xNewAddresses...
USDC_ADDRESS=0xNewAddresses...
VAULT_HANDLER=0xNewAddresses...
```

### **3. Initial Liquidity Provision**
```bash
# For automated systems (NEW)
make provide-eth-liquidity
make provide-usdc-liquidity

# For legacy systems
make provide-corrected-liquidity
```

**This command:**
- ✅ Approves 100 ETH to VaultBasedHandler
- ✅ Provides 100 ETH liquidity
- ✅ Approves 100,000 USDC to VaultBasedHandler
- ✅ Provides 100,000 USDC liquidity

---

## 🧪 System Verification

### **🔥 NEW: Complete Testing (RECOMMENDED)**
```bash
# ✅ NEW: Run all tests (Rewards + Core + VCOP)
make test-all
```

**This NEW command tests:**
- ✅ **Reward System** functionality and integration
- ✅ **Core Lending** system with multiple assets
- ✅ **VCOP Loan** system with PSM
- ✅ **Complete workflow** verification

### **Legacy: Manual Testing (For Reference)**

#### **Main Test**
```bash
make test-corrected-system
```

**Expected Result:**
```
==================================================
SPECIFIC TEST: ETH AS COLLATERAL -> USDC LOAN
==================================================

✅ Liquidity secured
✅ Maximum loanable: ~34,650 USDC
✅ Loan created. Position ID: 1
✅ 5 ETH → 10,000 USDC
✅ Collateralization ratio: ~1,157% (very safe)
✅ Interest rate: 8%

==================================================
ETH -> USDC TEST COMPLETED SUCCESSFULLY
==================================================
```

#### **Additional Tests**
```bash
# Complete test suite
make test-core-loans

# Specific tests
make test-eth-usdc-loan
make test-usdc-eth-loan
make test-advanced-operations
make test-risk-analysis
make test-loan-repayment
```

---

## 🚨 Common Problem Solutions

### **Error: "Insufficient collateral"**

**Diagnosis:**
```bash
# Verify oracle price
cast call <ORACLE_ADDRESS> "getPrice(address,address)" <ETH_ADDRESS> <USDC_ADDRESS> --rpc-url $RPC_URL
```

**Expected Result:** `0xb2d05e00` (3,000,000,000 = $3,000)

**If returns `0x000f4240` (1,000,000 = $1):**
```bash
# Update oracle price
. ./.env && cast send <ORACLE_ADDRESS> "updatePrice(address,address,uint256)" \
  <ETH_ADDRESS> <USDC_ADDRESS> 3000000000 \
  --rpc-url $RPC_URL --private-key $PRIVATE_KEY
```

### **Error: Incorrect Hardcoded Addresses**

**Symptom:** Oracle called with obsolete addresses

**Solution:**
1. Check `src/core/GenericLoanManager.sol` function `_getAssetValue`
2. Update hardcoded addresses:
```solidity
address usdcAddress = 0xNEW_USDC_ADDRESS;
if (asset == 0xNEW_ETH_ADDRESS) { // Update ETH
if (asset == 0xNEW_WBTC_ADDRESS) { // Update WBTC
```
3. Redeploy: `make deploy-complete` (NEW) or `make deploy-corrected-system` (legacy)

### **Error: "No liquidity available"**

**Verification:**
```bash
cast call <VAULT_HANDLER> "getAvailableLiquidity(address)" <TOKEN_ADDRESS> --rpc-url $RPC_URL
```

**Solution:**
```bash
# For NEW systems
make provide-eth-liquidity
make provide-usdc-liquidity

# For legacy systems
make provide-corrected-liquidity
```

---

## 🔧 Maintenance Commands

### **NEW: System Monitoring**
```bash
make check-addresses           # All deployed contract addresses  
make check-deployment-status   # Deployment status with dynamic addresses
make verify-system-authorizations # Verify all system authorizations
make check-balance             # Deployer balance
make check-tokens             # Token balances
```

### **Legacy: System Monitoring**
```bash
make check-system-status    # General status
make check-tokens          # Token balances
make check-vault           # Vault information
make check-balance         # Deployer balance
```

### **Address Management**
```bash
make update-addresses      # Address management helper
```

### **Block Explorer Verification**
```bash
make verify-contract
# Follow instructions to verify contracts
```

---

## 📊 System Parameters

### **Oracle Prices (6 decimals)**
| Asset | Price USD | Oracle Format |
|-------|-----------|---------------|
| ETH   | $3,000    | 3000000000    |
| WBTC  | $95,000   | 95000000000   |
| USDC  | $1        | 1000000       |

### **Asset Configurations**
| Asset | Collateral Ratio | Liquidation Ratio | Interest Rate | Max Loan |
|-------|------------------|-------------------|---------------|----------|
| ETH   | 130% (1300000)   | 110% (1100000)    | 8% (80000)    | 1000 ETH |
| WBTC  | 140% (1400000)   | 115% (1150000)    | 7.5% (75000)  | 50 WBTC  |
| USDC  | 110% (1100000)   | 105% (1050000)    | 4% (40000)    | 1M USDC  |

### **Initial Liquidity**
- **ETH**: 100 tokens
- **USDC**: 100,000 tokens
- **WBTC**: 10 tokens (optional)

---

## ✅ Complete Automated Workflow

### **🔥 NEW: For New Deployments (RECOMMENDED):**
```bash
# One-command deployment + testing
make deploy-complete && make test-all
```

**This approach:**
1. ✅ Deploys complete system automatically
2. ✅ Configures all integrations automatically
3. ✅ Tests all functionality comprehensively
4. ✅ No manual intervention required

### **Legacy: For New Deployments:**
```bash
# One command that does everything
make deploy-and-auto-test
```

**This command:**
1. ✅ Deploys complete system
2. ✅ Provides liquidity automatically
3. ✅ Runs verification tests
4. ✅ No manual intervention required

### **To Verify Existing System:**
```bash
# NEW: Quick comprehensive test
make test-all

# Legacy: Quick test of current system
make quick-test-corrected
```

---

## 📋 Deployment Checklist

### **Pre-Deployment**
- [ ] Environment variables configured (`.env`)
- [ ] Foundry installed and updated
- [ ] Blockchain network accessible (Base Sepolia)
- [ ] Sufficient balance for gas fees (~0.01 ETH)

### **🔥 NEW: Automated Deployment**
- [ ] Run `make deploy-complete`
- [ ] Run `make test-all` for verification
- [ ] Check `make check-addresses` for deployed contracts
- [ ] Provide liquidity if needed: `make provide-eth-liquidity`

### **Legacy: Manual Deployment**
- [ ] Run `make deploy-corrected-system`
- [ ] Verify addresses in output
- [ ] Copy addresses from output

### **Legacy: Configuration**
- [ ] Update `script/TestCoreLoans.s.sol` with new addresses
- [ ] Update `Makefile` with new addresses (optional)
- [ ] Run `make provide-corrected-liquidity`

### **Verification**
- [ ] Run `make test-all` (NEW) or `make test-corrected-system` (legacy)
- [ ] Verify successful output:
  - [ ] Loan created (Position ID: 1)
  - [ ] Ratio ~150% for 5 ETH → 10,000 USDC
  - [ ] No "Insufficient collateral" errors

### **Post-Deployment**
- [ ] Document deployed addresses
- [ ] Configure monitoring (optional)
- [ ] Verify contracts on block explorer (optional)

---

## 🎯 Success Metrics

### **Functional System Indicators:**
- ✅ **Responsive Oracle**: Correct prices ($3,000 ETH)
- ✅ **Sufficient Liquidity**: >50 ETH and >50,000 USDC in vaults
- ✅ **Functional Loans**: Successful creation with expected ratios
- ✅ **Correct Ratios**: ~150% for standard ETH→USDC loan

### **Final Validation Test:**
```bash
# NEW: Comprehensive validation
make test-all

# Legacy: Specific validation  
# Should create loan successfully:
# 5 ETH ($15,000) → 10,000 USDC = 150% ratio
make test-corrected-system
```

---

## 🚀 Quick Reference Commands

### **🔥 NEW: Automated Commands (RECOMMENDED)**
```bash
# Complete automated deployment + configuration + authorization
make deploy-complete

# Complete automated testing (all systems)
make test-all

# Check deployment status
make check-addresses
make check-deployment-status
```

### **Legacy: Manual Commands (For Reference)**
```bash
# Complete automated deployment
make deploy-and-auto-test

# Deployment only
make deploy-corrected-system

# Liquidity only
make provide-corrected-liquidity

# Testing only
make test-corrected-system

# Verify system
make check-system-status
```

---

**✅ Fully Functional and Documented System**

This guide ensures successful deployment of the collateralized loan system with all implemented and verified fixes. Use the NEW automated commands for the best experience. 