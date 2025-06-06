# ⚡ Referencia Rápida - Sistema de Préstamos Colateralizados

## 🚀 Comandos Esenciales

### **Despliegue Completo**
```bash
# Un comando que hace todo (RECOMENDADO)
make deploy-and-auto-test

# Solo despliegue
make deploy-corrected-system

# Solo testing
make test-corrected-system
```

### **Configuración Post-Despliegue**
```bash
# Proporcionar liquidez inicial
make provide-corrected-liquidity

# Verificar estado del sistema
make check-system-status
```

### **Comandos de Diagnóstico**
```bash
# Verificar precio del oracle
cast call <ORACLE> "getPrice(address,address)" <ETH> <USDC> --rpc-url $RPC_URL

# Verificar liquidez en vault
cast call <VAULT> "getAvailableLiquidity(address)" <TOKEN> --rpc-url $RPC_URL

# Verificar balance para gas
cast balance <DEPLOYER> --rpc-url $RPC_URL --ether
```

## 🔧 Soluciones Rápidas

### **Error "Insufficient collateral"**
```bash
# Arreglar precio en oracle
. ./.env && cast send <ORACLE> "updatePrice(address,address,uint256)" \
  <ETH> <USDC> 3000000000 --rpc-url $RPC_URL --private-key $PRIVATE_KEY
```

### **Sin liquidez**
```bash
make provide-corrected-liquidity
```

### **Reset completo**
```bash
make deploy-corrected-system
make provide-corrected-liquidity
make test-corrected-system
```

## 📊 Valores de Referencia

### **Precios Oracle (6 decimals)**
- **ETH**: 3000000000 ($3,000)
- **WBTC**: 95000000000 ($95,000)  
- **USDC**: 1000000 ($1)

### **Configuraciones Asset**
| Asset | Ratio Colateral | Ratio Liquidación | Interés |
|-------|-----------------|-------------------|---------|
| ETH   | 130% (1300000)  | 110% (1100000)    | 8%      |
| WBTC  | 140% (1400000)  | 115% (1150000)    | 7.5%    |
| USDC  | 110% (1100000)  | 105% (1050000)    | 4%      |

### **Test Estándar: ETH → USDC**
- **Colateral**: 5 ETH ($15,000)
- **Préstamo**: 10,000 USDC  
- **Ratio Esperado**: ~150%
- **Máximo Prestable**: ~$11,538

## 🎯 Direcciones Template

```solidity
// Actualizar en script/TestCoreLoans.s.sol
address constant MOCK_ETH = 0x...;
address constant MOCK_WBTC = 0x...;
address constant MOCK_USDC = 0x...;
address constant MOCK_ORACLE = 0x...;
address constant GENERIC_LOAN_MANAGER = 0x...;
address constant VAULT_BASED_HANDLER = 0x...;
```

## ✅ Checklist Rápido

### **Pre-Despliegue**
- [ ] `.env` configurado
- [ ] Balance ≥ 0.01 ETH
- [ ] Red accesible

### **Post-Despliegue**  
- [ ] Copiar direcciones del output
- [ ] Actualizar `TestCoreLoans.s.sol`
- [ ] Ejecutar `make test-corrected-system`
- [ ] Verificar préstamo exitoso

## 📚 Documentación Relacionada

- 📄 **[SISTEMA_CORREGIDO_DESPLIEGUE.md](./SISTEMA_CORREGIDO_DESPLIEGUE.md)** - Guía completa
- 🚨 **[TROUBLESHOOTING.md](./TROUBLESHOOTING.md)** - Solución de problemas
- 📄 **[INSTRUCCIONES_DESPLIEGUE.md](./INSTRUCCIONES_DESPLIEGUE.md)** - Sistemas legacy 