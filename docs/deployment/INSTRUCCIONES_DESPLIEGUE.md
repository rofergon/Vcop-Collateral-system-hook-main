# 📋 VCOP System Deployment Instructions

> **⚠️ IMPORTANT**: For the **corrected collateralized loan system**, please refer to the new guide:  
> 📄 **[SISTEMA_CORREGIDO_DESPLIEGUE.md](./SISTEMA_CORREGIDO_DESPLIEGUE.md)**

---

## 🚀 Collateralized Loan System (Updated)

### **Simplified Command (Recommended)**
```bash
# Automated complete deployment of the corrected system
make deploy-corrected-system
```

### **Complete Automated Workflow**
```bash
# Deploy + Configure + Test automatically
make deploy-and-auto-test
```

### **System Verification**
```bash
# Test the deployed system
make test-corrected-system
```

---

## 🔧 Original VCOP System (Legacy)

To run the deployment of the original VCOP system in two parts, follow these steps:

### **1. Deploy Base Contracts**

```bash
forge script script/DeployVCOPBase.sol:DeployVCOPBase --via-ir --broadcast --fork-url https://sepolia.base.org
```

This command will deploy:
- Simulated USDC
- VCOP Token
- VCOP Oracle
- Collateral Manager

### **2. Configure the System**

```bash
forge script script/ConfigureVCOPSystem.sol:ConfigureVCOPSystem --via-ir --broadcast --fork-url https://sepolia.base.org
```

This second command will configure:
- The Uniswap v4 hook
- Cross-references between contracts
- System collaterals and parameters
- The Uniswap v4 pool and initial liquidity
- The Price Stability Module (PSM)

### **Advantages of this separation**

1. **Enhanced security**: Reduces the risk of issues with private keys by limiting the scope of each script.
2. **Better error recovery**: If there's a problem in the second part, there's no need to redeploy all contracts.
3. **Code clarity**: Each script has a well-defined responsibility.
4. **Permission control**: The second script verifies owners before proceeding with configuration.

---

## 📚 Related Documentation

- 📄 **[SISTEMA_CORREGIDO_DESPLIEGUE.md](./SISTEMA_CORREGIDO_DESPLIEGUE.md)** - Complete guide for the corrected system
- 📄 **[PSM-README.md](./PSM-README.md)** - Peg Stability Module configuration
- 📄 **[README.md](./README.md)** - General deployment documentation

---

## 🎯 Available Systems

| System | Command | Status | Documentation |
|---------|---------|--------|---------------|
| **Collateralized Loans** | `make deploy-corrected-system` | ✅ **Active** | [SISTEMA_CORREGIDO_DESPLIEGUE.md](./SISTEMA_CORREGIDO_DESPLIEGUE.md) |
| Original VCOP | Manual scripts | 🔄 Legacy | This page |
| PSM Module | See PSM-README.md | 📋 Documented | [PSM-README.md](./PSM-README.md) | 