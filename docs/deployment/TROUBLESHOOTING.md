# 🚨 Troubleshooting - Sistema de Préstamos Colateralizados

## 📋 Problemas Comunes y Soluciones

Esta guía documenta todos los problemas encontrados durante el desarrollo y sus soluciones verificadas.

---

## 🔥 Error: "Insufficient collateral"

### **Síntomas**
```bash
Error: script failed: Insufficient collateral
make: *** [Makefile:228: test-corrected-system] Error 1
```

### **Causa Raíz**
Oracle devolviendo precio incorrecto para ETH (devuelve $1 en lugar de $3,000)

### **Diagnóstico**
```bash
# Verificar precio del oracle
cast call <ORACLE_ADDRESS> "getPrice(address,address)" <ETH_ADDRESS> <USDC_ADDRESS> --rpc-url $RPC_URL
```

**Resultados:**
- ✅ **Correcto**: `0xb2d05e00` (3,000,000,000 = $3,000)
- ❌ **Incorrecto**: `0x000f4240` (1,000,000 = $1)

### **Solución Verificada**
```bash
# Actualizar precio manualmente en oracle
. ./.env && cast send <ORACLE_ADDRESS> "updatePrice(address,address,uint256)" \
  <ETH_ADDRESS> <USDC_ADDRESS> 3000000000 \
  --rpc-url $RPC_URL --private-key $PRIVATE_KEY

# También actualizar precio inverso
. ./.env && cast send <ORACLE_ADDRESS> "updatePrice(address,address,uint256)" \
  <USDC_ADDRESS> <ETH_ADDRESS> 333 \
  --rpc-url $RPC_URL --private-key $PRIVATE_KEY
```

---

## 📁 Error: "vm.writeFile not allowed"

### **Síntomas**
```bash
Error: You have a restriction on `ffi` and `fs_permission`, so `vm.writeFile` is not allowed
```

### **Causa Raíz**
Foundry bloquea escritura de archivos por seguridad

### **Solución Implementada**
✅ **Corregido en el código** - Reemplazado `vm.writeFile` con `console.log`:

```solidity
// ❌ Antes (causaba error)
vm.writeFile("latest-deployment.json", json);

// ✅ Después (funciona)
console.log("=== DEPLOYMENT ADDRESSES (Copy these for tests) ===");
console.log("MOCK_ETH:", mockETH);
console.log("MOCK_USDC:", mockUSDC);
```

**Archivo afectado:** `script/deploy/DeploySimpleCore.s.sol`

---

## 🔗 Error: Direcciones Hardcodeadas Obsoletas

### **Síntomas**
Oracle llamado con direcciones incorrectas en traces:
```bash
[4965] MockOracle::getPrice(..., 0x06c61154F530BC1c9D5E0ecFc855Fb744Bc6d5Cc) [staticcall]
```

### **Causa Raíz**
Función `_getAssetValue` en GenericLoanManager con direcciones hardcodeadas obsoletas

### **Archivos Afectados**
- `src/core/GenericLoanManager.sol` - líneas 389-415

### **Solución Verificada**
```solidity
// En src/core/GenericLoanManager.sol
function _getAssetValue(address asset, uint256 amount) internal view returns (uint256) {
    // ✅ Actualizar con dirección USDC correcta
    address usdcAddress = 0xe981A9ef78BA6E852FceE8221Ac731ed8d1a73b4; // NUEVA
    
    // ✅ Actualizar direcciones ETH y WBTC
    if (asset == 0xcEA74D109F9B6F6c17Bf0dA4BE7a1a279e89a11f) { // ETH NUEVA
        return (amount * priceInUsdc) / 1e18;
    }
    else if (asset == 0xB42c21ae911C889a887f79dE329bEf8fa0a83Ab8) { // WBTC NUEVA
        return (amount * priceInUsdc) / 1e8;
    }
}
```

**Comando para aplicar:**
```bash
# Redesplegar después de corregir
make deploy-corrected-system
```

---

## 💧 Error: "No liquidity available"

### **Síntomas**
```bash
ETH Vault: 0 ETH
USDC Vault: 0 USDC
```

### **Diagnóstico**
```bash
# Verificar liquidez en vault
cast call <VAULT_HANDLER> "getAvailableLiquidity(address)" <TOKEN_ADDRESS> --rpc-url $RPC_URL
```

### **Solución**
```bash
# Proporcionar liquidez inicial
make provide-corrected-liquidity
```

**Resultado esperado:**
```bash
✅ Liquidity provided successfully!
   ETH Vault: 100 ETH
   USDC Vault: 100,000 USDC
```

---

## 🔑 Error: "a value is required for '--private-key'"

### **Síntomas**
```bash
error: a value is required for '--private-key <RAW_PRIVATE_KEY>' but none was supplied
```

### **Causa**
Variables de entorno no cargadas correctamente

### **Solución**
```bash
# Cargar variables de entorno primero
. ./.env && cast send ...

# O verificar que .env existe y tiene PRIVATE_KEY
cat .env | grep PRIVATE_KEY
```

---

## 🌐 Error: Network Connection Issues

### **Síntomas**
```bash
Error: Failed to get chain ID
```

### **Diagnóstico**
```bash
# Verificar conectividad
cast chain-id --rpc-url https://sepolia.base.org
```

### **Soluciones**
1. **Verificar RPC URL**: Usar Base Sepolia oficial
2. **Verificar internet**: Ping a la URL
3. **Verificar rate limits**: Esperar y reintentar

---

## 📊 Ratios Incorrectos en Output

### **Síntomas**
Ratio de colateralización extremadamente alto o bajo

### **Ejemplo Problemático**
```bash
Ratio de colateralizacion: 11579208923731619542357098500868790785326998466564056403945758400791312963 %
```

### **Causa**
Cálculos con decimales incorrectos o overflow

### **Verificación**
```bash
# El ratio debe estar cerca de 150% (1500000 en formato interno)
# Para 5 ETH ($15,000) → 10,000 USDC = 150% ratio
```

### **Solución**
✅ **Verificado funcionando** con oracle corregido:
- 5 ETH × $3,000 = $15,000 colateral
- 10,000 USDC préstamo  
- Ratio = $15,000 / $10,000 = 150%

---

## 🔄 Error: "Position not active" 

### **Síntomas**
Error al intentar operar con posición de préstamo

### **Diagnóstico**
```bash
# Verificar estado de la posición
cast call <LOAN_MANAGER> "getPosition(uint256)" <POSITION_ID> --rpc-url $RPC_URL
```

### **Causas Comunes**
1. Position ID incorrecto
2. Préstamo ya cerrado/liquidado
3. Error en la creación del préstamo

### **Solución**
```bash
# Crear nueva posición si es necesario
make test-corrected-system
```

---

## ⛽ Error: "Insufficient gas"

### **Síntomas**
```bash
Error: Transaction failed with out of gas
```

### **Solución**
```bash
# Verificar balance para gas
cast balance <DEPLOYER_ADDRESS> --rpc-url $RPC_URL --ether

# Debe tener al menos 0.01 ETH para despliegue completo
```

---

## 🔧 Comandos de Diagnóstico Útiles

### **Verificar Estado del Sistema**
```bash
# Estado general
make check-system-status

# Verificar oracle específico
cast call <ORACLE_ADDRESS> "getPrice(address,address)" <ETH> <USDC> --rpc-url $RPC_URL

# Verificar liquidez
cast call <VAULT_HANDLER> "getAvailableLiquidity(address)" <TOKEN> --rpc-url $RPC_URL

# Verificar balances
cast call <TOKEN_ADDRESS> "balanceOf(address)" <DEPLOYER_ADDRESS> --rpc-url $RPC_URL
```

### **Verificar Configuraciones**
```bash
# Verificar configuración de asset
cast call <VAULT_HANDLER> "getAssetConfig(address)" <TOKEN_ADDRESS> --rpc-url $RPC_URL

# Verificar si asset está soportado
cast call <VAULT_HANDLER> "isAssetSupported(address)" <TOKEN_ADDRESS> --rpc-url $RPC_URL
```

---

## 📋 Checklist de Diagnóstico

### **Antes de Buscar Ayuda**
- [ ] ¿Variables de entorno configuradas? (`cat .env`)
- [ ] ¿Balance suficiente para gas? (`cast balance ...`)
- [ ] ¿Red accesible? (`cast chain-id --rpc-url ...`)
- [ ] ¿Direcciones actualizadas? (verificar scripts de test)
- [ ] ¿Oracle funcionando? (`cast call oracle getPrice ...`)
- [ ] ¿Liquidez proporcionada? (`make provide-corrected-liquidity`)

### **Información a Incluir en Reportes**
1. **Comando exacto ejecutado**
2. **Error completo** (no solo el mensaje final)
3. **Direcciones de contratos** desplegados
4. **Output del comando de diagnóstico**
5. **Network y chain ID**

---

## 🚀 Comandos de Recuperación Rápida

```bash
# Reset completo del sistema
make deploy-corrected-system      # 1. Redesplegar
make provide-corrected-liquidity  # 2. Proporcionar liquidez
make test-corrected-system        # 3. Verificar funcionamiento

# Solo arreglar oracle
. ./.env && cast send <ORACLE> "updatePrice(address,address,uint256)" \
  <ETH> <USDC> 3000000000 --rpc-url $RPC_URL --private-key $PRIVATE_KEY

# Solo proporcionar liquidez
make provide-corrected-liquidity

# Solo testing
make test-corrected-system
```

---

**✅ Con esta guía, la mayoría de problemas pueden resolverse rápidamente**

Si el problema persiste después de seguir esta guía, es posible que sea un problema nuevo que requiera investigación adicional. 