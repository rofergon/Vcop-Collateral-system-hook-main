# ⚡ Quick Reference - Collateralized Loan System

## 🚀 Essential Commands

### **Complete Deployment**
```bash
# One command that does everything (RECOMMENDED)
make deploy-and-auto-test

# Deployment only
make deploy-corrected-system

# Testing only
make test-corrected-system
```

### **Post-Deployment Configuration**
```bash
# Provide initial liquidity
make provide-corrected-liquidity

# Verify system status
make check-system-status
```

### **Diagnostic Commands**
```bash
# Verify oracle price
cast call <ORACLE> "getPrice(address,address)" <ETH> <USDC> --rpc-url $RPC_URL

# Verify vault liquidity
cast call <VAULT> "getAvailableLiquidity(address)" <TOKEN> --rpc-url $RPC_URL

# Verify gas balance
cast balance <DEPLOYER> --rpc-url $RPC_URL --ether
```

## 🔧 Quick Solutions

### **Error "Insufficient collateral"**
```bash
# Fix oracle price
. ./.env && cast send <ORACLE> "updatePrice(address,address,uint256)" \
  <ETH> <USDC> 3000000000 --rpc-url $RPC_URL --private-key $PRIVATE_KEY
```

### **No liquidity**
```bash
make provide-corrected-liquidity
```

### **Complete reset**
```bash
make deploy-corrected-system
make provide-corrected-liquidity
make test-corrected-system
```

## 📊 Reference Values

### **Oracle Prices (6 decimals)**
- **ETH**: 3000000000 ($3,000)
- **WBTC**: 95000000000 ($95,000)
- **USDC**: 1000000 ($1)

### **Asset Configurations**
| Asset | Collateral Ratio | Liquidation Ratio | Interest |
|-------|------------------|-------------------|----------|
| ETH   | 130% (1300000)   | 110% (1100000)    | 8%       |
| WBTC  | 140% (1400000)   | 115% (1150000)    | 7.5%     |
| USDC  | 110% (1100000)   | 105% (1050000)    | 4%       |

### **Standard Test: ETH → USDC**
- **Collateral**: 5 ETH ($15,000)
- **Loan**: 10,000 USDC
- **Expected Ratio**: ~150%
- **Maximum Loanable**: ~$11,538

## 🎯 Address Template

```solidity
// Update in script/TestCoreLoans.s.sol
address constant MOCK_ETH = 0x...;
address constant MOCK_WBTC = 0x...;
address constant MOCK_USDC = 0x...;
address constant MOCK_ORACLE = 0x...;
address constant GENERIC_LOAN_MANAGER = 0x...;
address constant VAULT_BASED_HANDLER = 0x...;
```

## ✅ Quick Checklist

### **Pre-Deployment**
- [ ] `.env` configured
- [ ] Balance ≥ 0.01 ETH
- [ ] Network accessible

### **Post-Deployment**
- [ ] Copy addresses from output
- [ ] Update `TestCoreLoans.s.sol`
- [ ] Run `make test-corrected-system`
- [ ] Verify successful loan

## 📚 Related Documentation

- 📄 **[SISTEMA_CORREGIDO_DESPLIEGUE.md](./SISTEMA_CORREGIDO_DESPLIEGUE.md)** - Complete guide
- 🚨 **[TROUBLESHOOTING.md](./TROUBLESHOOTING.md)** - Problem solving
- 📄 **[INSTRUCCIONES_DESPLIEGUE.md](./INSTRUCCIONES_DESPLIEGUE.md)** - Legacy systems 