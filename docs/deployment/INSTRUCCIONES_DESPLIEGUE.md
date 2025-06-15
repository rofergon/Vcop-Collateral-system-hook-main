# 📋 VCOP System Deployment Instructions

## 🚀 **NEW AUTOMATED DEPLOYMENT** (RECOMMENDED)

### **🎯 One-Command Complete Deployment**
```bash
# ✅ COMPLETE AUTOMATED DEPLOYMENT + CONFIGURATION + AUTHORIZATION
make deploy-complete
```

**What this command does automatically:**
- ✅ **Compiles** all contracts with optimizations
- ✅ **Deploys** unified system (Core + VCOP + Rewards)
- ✅ **Configures** all system integrations and authorizations
- ✅ **Verifies** deployment status
- ✅ **Updates** deployed-addresses.json automatically

### **🧪 One-Command Complete Testing**
```bash
# ✅ RUN ALL TESTS (Rewards + Core + VCOP)
make test-all
```

**What this command tests:**
- ✅ **Reward System** functionality and integration
- ✅ **Core Lending** system with multiple assets
- ✅ **VCOP Loan** system with PSM
- ✅ **Complete workflow** verification

### **⚡ Quick Start (2 Commands Only)**
```bash
# 1. Deploy everything
make deploy-complete

# 2. Test everything
make test-all
```

---

## 🏗️ **DEPLOYED SYSTEMS OVERVIEW**

| System | Status | Main Command | Description |
|---------|--------|--------------|-------------|
| **🔥 Ultra-Flexible Lending** | ✅ **ACTIVE** | `make deploy-complete` | **ZERO ratio limits, ANY assets** |
| **🎁 Advanced Rewards** | ✅ **ACTIVE** | Included in deploy-complete | **Direct VCOP minting rewards** |
| **📊 Risk Calculator** | ✅ **ACTIVE** | Included in deploy-complete | **50+ real-time metrics** |
| **🔒 PSM Stability** | ✅ **ACTIVE** | Included in deploy-complete | **VCOP price stabilization** |
| Legacy VCOP | 🔄 Deprecated | Manual scripts | Old system |

---

## 🔧 **ADDITIONAL TESTING COMMANDS**

### **Core System Testing**
```bash
# Test core lending with multiple assets
make test-core-loans

# Test ETH collateral -> USDC loan
make test-eth-usdc-loan

# Test USDC collateral -> ETH loan  
make test-usdc-eth-loan

# Test advanced operations (add/withdraw collateral)
make test-advanced-operations

# Test risk analysis and calculations
make test-risk-analysis

# Test loan repayment and closure
make test-loan-repayment
```

### **VCOP & PSM Testing**
```bash
# Test complete loan cycle
make test-loans

# Test liquidation mechanism
make test-liquidation

# Test PSM functionality
make test-psm

# Check PSM status and prices
make check-psm
make check-prices
```

### **Reward System Testing**
```bash
# Test reward system functionality
make test-rewards

# Test reward system integration
make test-rewards-integration

# Test all reward functionality
make test-rewards-all
```

---

## 📊 **SYSTEM VERIFICATION COMMANDS**

```bash
# Check all deployed contract addresses
make check-addresses

# Check deployment status with dynamic addresses
make check-deployment-status

# Verify all system authorizations
make verify-system-authorizations

# Check deployer balances
make check-balance
make check-tokens
```

---

## 💰 **LIQUIDITY PROVISION COMMANDS**

```bash
# Provide ETH liquidity to vaults
make provide-eth-liquidity

# Provide WBTC liquidity to vaults
make provide-wbtc-liquidity

# Provide USDC liquidity to vaults
make provide-usdc-liquidity

# Check vault information
make check-vault
```

---

## 🔄 **PSM SWAP COMMANDS**

### **Testnet (Base Sepolia)**
```bash
# Swap VCOP for USDC
make swap-vcop-to-usdc AMOUNT=100000000  # 100 VCOP

# Swap USDC for VCOP
make swap-usdc-to-vcop AMOUNT=100000000  # 100 USDC

# Check PSM status and reserves
make check-psm

# Check current prices
make check-prices
```

### **Mainnet (Base)**
```bash
# Swap VCOP for USDC on mainnet
make swap-vcop-to-usdc-mainnet AMOUNT=100000000

# Swap USDC for VCOP on mainnet
make swap-usdc-to-vcop-mainnet AMOUNT=100000000

# Check PSM status on mainnet
make check-psm-mainnet

# Check prices on mainnet
make check-prices-mainnet
```

---

## 🛠️ **LEGACY SYSTEMS** (For Reference)

> **⚠️ IMPORTANT**: The following are legacy systems. Use the new automated commands above for current deployments.

### **Original VCOP System (Deprecated)**

#### **1. Deploy Base Contracts**
```bash
forge script script/DeployVCOPBase.sol:DeployVCOPBase --via-ir --broadcast --fork-url https://sepolia.base.org
```

#### **2. Configure the System**
```bash
forge script script/ConfigureVCOPSystem.sol:ConfigureVCOPSystem --via-ir --broadcast --fork-url https://sepolia.base.org
```

### **Fixed System Deployment (Deprecated)**
```bash
# Deploy fixed system to Sepolia
make deploy-fixed-system

# Deploy to Base Mainnet
make deploy-mainnet
```

---

## 🎯 **DEVELOPMENT WORKFLOW**

### **1. Fresh Development Setup**
```bash
# Deploy everything fresh
make deploy-complete

# Run complete test suite
make test-all

# Check all addresses
make check-addresses
```

### **2. After Code Changes**
```bash
# Rebuild and redeploy
forge build
make deploy-complete

# Verify with tests
make test-all
```

### **3. Production Deployment**
```bash
# For mainnet deployment (modify RPC in Makefile)
make deploy-complete

# Verify mainnet PSM
make check-psm-mainnet
```

---

## 📚 **DOCUMENTATION REFERENCES**

- 📄 **[FLEXIBILIDAD_MAXIMA.md](../architecture/FLEXIBILIDAD_MAXIMA.md)** - Ultra-flexible lending system documentation
- 📄 **[NUEVA_ARQUITECTURA.md](../architecture/NUEVA_ARQUITECTURA.md)** - Complete architecture documentation
- 📄 **[PSM-README.md](./PSM-README.md)** - Peg Stability Module configuration
- 📄 **[README.md](./README.md)** - General deployment documentation

---

## 🆘 **TROUBLESHOOTING**

### **Common Issues**

#### **Deployment Fails**
```bash
# Clean transactions and retry
make clean-txs
make deploy-complete
```

#### **Authorization Issues**
```bash
# Fix system authorizations
make configure-system-integration
make verify-system-authorizations
```

#### **Testing Fails**
```bash
# Check balances
make check-balance
make check-tokens

# Provide liquidity if needed
make provide-eth-liquidity
make provide-usdc-liquidity
```

#### **PSM Issues**
```bash
# Check PSM status
make check-psm
make check-prices

# Update oracle if needed
make update-oracle
```

---

## ✅ **SUCCESS INDICATORS**

After running `make deploy-complete`, you should see:
- ✅ All contracts deployed successfully
- ✅ All authorizations configured
- ✅ deployed-addresses.json updated
- ✅ System integration verified

After running `make test-all`, you should see:
- ✅ Reward system tests pass
- ✅ Core lending tests pass  
- ✅ VCOP loan tests pass
- ✅ PSM functionality tests pass

---

## 🚀 **NEXT STEPS**

1. **Deploy**: `make deploy-complete`
2. **Test**: `make test-all`
3. **Verify**: `make check-addresses`
4. **Provide Liquidity**: `make provide-eth-liquidity` (if needed)
5. **Start Using**: System ready for ultra-flexible lending!

**🎉 The system is now ready for professional DeFi lending with ZERO ratio restrictions!** 