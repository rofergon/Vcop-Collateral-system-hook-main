# 🚨 Troubleshooting - Collateralized Loan System

## 📋 Common Problems and Solutions

This guide documents all issues encountered during development and their verified solutions.

---

## 🔥 Error: "Insufficient collateral"

### **Symptoms**
```bash
Error: script failed: Insufficient collateral
make: *** [Makefile:228: test-corrected-system] Error 1
```

### **Root Cause**
Oracle returning incorrect price for ETH (returns $1 instead of $3,000)

### **Diagnosis**
```bash
# Verify oracle price
cast call <ORACLE_ADDRESS> "getPrice(address,address)" <ETH_ADDRESS> <USDC_ADDRESS> --rpc-url $RPC_URL
```

**Results:**
- ✅ **Correct**: `0xb2d05e00` (3,000,000,000 = $3,000)
- ❌ **Incorrect**: `0x000f4240` (1,000,000 = $1)

### **Verified Solution**
```bash
# Manually update price in oracle
. ./.env && cast send <ORACLE_ADDRESS> "updatePrice(address,address,uint256)" \
  <ETH_ADDRESS> <USDC_ADDRESS> 3000000000 \
  --rpc-url $RPC_URL --private-key $PRIVATE_KEY

# Also update inverse price
. ./.env && cast send <ORACLE_ADDRESS> "updatePrice(address,address,uint256)" \
  <USDC_ADDRESS> <ETH_ADDRESS> 333 \
  --rpc-url $RPC_URL --private-key $PRIVATE_KEY
```

---

## 📁 Error: "vm.writeFile not allowed"

### **Symptoms**
```bash
Error: You have a restriction on `ffi` and `fs_permission`, so `vm.writeFile` is not allowed
```

### **Root Cause**
Foundry blocks file writing for security

### **Implemented Solution**
✅ **Fixed in code** - Replaced `vm.writeFile` with `console.log`:

```solidity
// ❌ Before (caused error)
vm.writeFile("latest-deployment.json", json);

// ✅ After (works)
console.log("=== DEPLOYMENT ADDRESSES (Copy these for tests) ===");
console.log("MOCK_ETH:", mockETH);
console.log("MOCK_USDC:", mockUSDC);
```

**Affected file:** `script/deploy/DeploySimpleCore.s.sol`

---

## 🔗 Error: Obsolete Hardcoded Addresses

### **Symptoms**
Oracle called with incorrect addresses in traces:
```bash
[4965] MockOracle::getPrice(..., 0x06c61154F530BC1c9D5E0ecFc855Fb744Bc6d5Cc) [staticcall]
```

### **Root Cause**
`_getAssetValue` function in GenericLoanManager with obsolete hardcoded addresses

### **Affected Files**
- `src/core/GenericLoanManager.sol` - lines 389-415

### **Verified Solution**
```solidity
// In src/core/GenericLoanManager.sol
function _getAssetValue(address asset, uint256 amount) internal view returns (uint256) {
    // ✅ Update with correct USDC address
    address usdcAddress = 0xe981A9ef78BA6E852FceE8221Ac731ed8d1a73b4; // NEW
    
    // ✅ Update ETH and WBTC addresses
    if (asset == 0xcEA74D109F9B6F6c17Bf0dA4BE7a1a279e89a11f) { // ETH NEW
        return (amount * priceInUsdc) / 1e18;
    }
    else if (asset == 0xB42c21ae911C889a887f79dE329bEf8fa0a83Ab8) { // WBTC NEW
        return (amount * priceInUsdc) / 1e8;
    }
}
```

**Command to apply:**
```bash
# Redeploy after fixing
make deploy-corrected-system
```

---

## 💧 Error: "No liquidity available"

### **Symptoms**
```bash
ETH Vault: 0 ETH
USDC Vault: 0 USDC
```

### **Diagnosis**
```bash
# Verify vault liquidity
cast call <VAULT_HANDLER> "getAvailableLiquidity(address)" <TOKEN_ADDRESS> --rpc-url $RPC_URL
```

### **Solution**
```bash
# Provide initial liquidity
make provide-corrected-liquidity
```

**Expected result:**
```bash
✅ Liquidity provided successfully!
   ETH Vault: 100 ETH
   USDC Vault: 100,000 USDC
```

---

## 🔑 Error: "a value is required for '--private-key'"

### **Symptoms**
```bash
error: a value is required for '--private-key <RAW_PRIVATE_KEY>' but none was supplied
```

### **Cause**
Environment variables not loaded correctly

### **Solution**
```bash
# Load environment variables first
. ./.env && cast send ...

# Or verify .env exists and has PRIVATE_KEY
cat .env | grep PRIVATE_KEY
```

---

## 🌐 Error: Network Connection Issues

### **Symptoms**
```bash
Error: Failed to get chain ID
```

### **Diagnosis**
```bash
# Verify connectivity
cast chain-id --rpc-url https://sepolia.base.org
```

### **Solutions**
1. **Verify RPC URL**: Use official Base Sepolia
2. **Check internet**: Ping the URL
3. **Check rate limits**: Wait and retry

---

## 📊 Incorrect Ratios in Output

### **Symptoms**
Extremely high or low collateralization ratio

### **Problematic Example**
```bash
Collateralization ratio: 11579208923731619542357098500868790785326998466564056403945758400791312963 %
```

### **Cause**
Incorrect decimal calculations or overflow

### **Verification**
```bash
# Ratio should be around 150% (1500000 in internal format)
# For 5 ETH ($15,000) → 10,000 USDC = 150% ratio
```

### **Solution**
✅ **Verified working** with corrected oracle:
- 5 ETH × $3,000 = $15,000 collateral
- 10,000 USDC loan
- Ratio = $15,000 / $10,000 = 150%

---

## 🔄 Error: "Position not active"

### **Symptoms**
Error when trying to operate with loan position

### **Diagnosis**
```bash
# Verify position status
cast call <LOAN_MANAGER> "getPosition(uint256)" <POSITION_ID> --rpc-url $RPC_URL
```

### **Common Causes**
1. Incorrect Position ID
2. Loan already closed/liquidated
3. Error in loan creation

### **Solution**
```bash
# Create new position if needed
make test-corrected-system
```

---

## ⛽ Error: "Insufficient gas"

### **Symptoms**
```bash
Error: Transaction failed with out of gas
```

### **Solution**
```bash
# Verify gas balance
cast balance <DEPLOYER_ADDRESS> --rpc-url $RPC_URL --ether

# Should have at least 0.01 ETH for complete deployment
```

---

## 🔧 Useful Diagnostic Commands

### **Verify System Status**
```bash
# General status
make check-system-status

# Verify specific oracle
cast call <ORACLE_ADDRESS> "getPrice(address,address)" <ETH> <USDC> --rpc-url $RPC_URL

# Verify liquidity
cast call <VAULT_HANDLER> "getAvailableLiquidity(address)" <TOKEN> --rpc-url $RPC_URL

# Verify balances
cast call <TOKEN_ADDRESS> "balanceOf(address)" <DEPLOYER_ADDRESS> --rpc-url $RPC_URL
```

### **Verify Configurations**
```bash
# Verify asset configuration
cast call <VAULT_HANDLER> "getAssetConfig(address)" <TOKEN_ADDRESS> --rpc-url $RPC_URL

# Verify if asset is supported
cast call <VAULT_HANDLER> "isAssetSupported(address)" <TOKEN_ADDRESS> --rpc-url $RPC_URL
```

---

## 📋 Diagnostic Checklist

### **Before Seeking Help**
- [ ] Environment variables configured? (`cat .env`)
- [ ] Sufficient gas balance? (`cast balance ...`)
- [ ] Network accessible? (`cast chain-id --rpc-url ...`)
- [ ] Addresses updated? (verify test scripts)
- [ ] Oracle working? (`cast call oracle getPrice ...`)
- [ ] Liquidity provided? (`make provide-corrected-liquidity`)

### **Information to Include in Reports**
1. **Exact command executed**
2. **Complete error** (not just final message)
3. **Deployed contract addresses**
4. **Diagnostic command output**
5. **Network and chain ID**

---

## 🚀 Quick Recovery Commands

```bash
# Complete system reset
make deploy-corrected-system      # 1. Redeploy
make provide-corrected-liquidity  # 2. Provide liquidity
make test-corrected-system        # 3. Verify operation

# Fix oracle only
. ./.env && cast send <ORACLE> "updatePrice(address,address,uint256)" \
  <ETH> <USDC> 3000000000 --rpc-url $RPC_URL --private-key $PRIVATE_KEY

# Provide liquidity only
make provide-corrected-liquidity

# Testing only
make test-corrected-system
```

---

**✅ With this guide, most problems can be resolved quickly**

If the problem persists after following this guide, it may be a new issue requiring additional investigation. 