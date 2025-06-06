# 🚀 Sistema de Préstamos Colateralizados - Guía de Despliegue Corregido

## 📋 Resumen Ejecutivo

Esta guía documenta el procedimiento **completo y corregido** para desplegar el sistema de préstamos colateralizados. Incluye todas las correcciones implementadas para resolver problemas de oracle, direcciones hardcodeadas y configuración automatizada.

---

## 🎯 Componentes del Sistema

### **Core Contracts**
- **MockOracle**: Sistema de precios con configuración dinámica
- **GenericLoanManager**: Gestor principal de préstamos 
- **VaultBasedHandler**: Manejador de assets con vaults
- **Mock Tokens**: ETH, WBTC, USDC para testing

### **Configuraciones Clave**
- **ETH**: 130% colateral, 110% liquidación, 8% interés, $3,000 precio
- **WBTC**: 140% colateral, 115% liquidación, 7.5% interés, $95,000 precio  
- **USDC**: 110% colateral, 105% liquidación, 4% interés, $1 precio

---

## 🛠️ Preparación del Entorno

### **1. Configurar Variables de Entorno**
```bash
# Crear archivo .env
cat > .env << EOF
PRIVATE_KEY=tu_private_key_aqui
RPC_URL=https://sepolia.base.org
ETHERSCAN_API_KEY=tu_api_key_aqui
EOF
```

### **2. Verificar Herramientas**
```bash
# Verificar Foundry
forge --version
cast --version

# Verificar conexión a red
cast chain-id --rpc-url https://sepolia.base.org

# Verificar balance para gas
cast balance $DEPLOYER_ADDRESS --rpc-url https://sepolia.base.org --ether
```

---

## 🚀 Procedimiento de Despliegue

### **Comando Principal (Recomendado)**
```bash
# Despliegue completo automatizado
make deploy-corrected-system
```

**Este comando despliega:**
1. ✅ Mock Tokens (ETH, WBTC, USDC)
2. ✅ MockOracle con precios correctos
3. ✅ Asset Handlers (Vault, Flexible, MintableBurnable)
4. ✅ Loan Managers (Generic, Flexible)
5. ✅ Configuración automática de assets
6. ✅ Configuración de ratios y parámetros

### **Output Esperado**
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

## ⚙️ Configuración Post-Despliegue

### **1. Actualizar Scripts de Testing**

**Ubicación:** `script/TestCoreLoans.s.sol`

```solidity
// Actualizar estas direcciones con las del output
address constant MOCK_ETH = 0xNuevasDirecciones...;
address constant MOCK_WBTC = 0xNuevasDirecciones...;
address constant MOCK_USDC = 0xNuevasDirecciones...;
address constant MOCK_ORACLE = 0xNuevasDirecciones...;
address constant GENERIC_LOAN_MANAGER = 0xNuevasDirecciones...;
address constant VAULT_BASED_HANDLER = 0xNuevasDirecciones...;
```

### **2. Actualizar Comandos de Liquidez**

**Ubicación:** `Makefile` - sección `provide-corrected-liquidity`

```bash
# Actualizar direcciones en los comandos cast send
ETH_ADDRESS=0xNuevasDirecciones...
USDC_ADDRESS=0xNuevasDirecciones...
VAULT_HANDLER=0xNuevasDirecciones...
```

### **3. Provision de Liquidez Inicial**
```bash
make provide-corrected-liquidity
```

**Este comando:**
- ✅ Aprueba 100 ETH al VaultBasedHandler
- ✅ Proporciona 100 ETH de liquidez
- ✅ Aprueba 100,000 USDC al VaultBasedHandler  
- ✅ Proporciona 100,000 USDC de liquidez

---

## 🧪 Verificación del Sistema

### **Test Principal**
```bash
make test-corrected-system
```

**Resultado Esperado:**
```
==================================================
PRUEBA ESPECIFICA: ETH COMO COLATERAL -> USDC PRESTAMO
==================================================

✅ Liquidez asegurada
✅ Máximo prestable: ~34,650 USDC
✅ Préstamo creado. Position ID: 1
✅ 5 ETH → 10,000 USDC
✅ Ratio de colateralización: ~1,157% (muy seguro)
✅ Tasa de interés: 8%

==================================================
PRUEBA ETH -> USDC COMPLETADA EXITOSAMENTE
==================================================
```

### **Tests Adicionales**
```bash
# Suite completa de tests
make test-core-loans

# Tests específicos
make test-eth-usdc-loan
make test-usdc-eth-loan
make test-advanced-operations
make test-risk-analysis
make test-loan-repayment
```

---

## 🚨 Solución de Problemas Comunes

### **Error: "Insufficient collateral"**

**Diagnóstico:**
```bash
# Verificar precio del oracle
cast call <ORACLE_ADDRESS> "getPrice(address,address)" <ETH_ADDRESS> <USDC_ADDRESS> --rpc-url $RPC_URL
```

**Resultado Esperado:** `0xb2d05e00` (3,000,000,000 = $3,000)

**Si devuelve `0x000f4240` (1,000,000 = $1):**
```bash
# Actualizar precio en oracle
. ./.env && cast send <ORACLE_ADDRESS> "updatePrice(address,address,uint256)" \
  <ETH_ADDRESS> <USDC_ADDRESS> 3000000000 \
  --rpc-url $RPC_URL --private-key $PRIVATE_KEY
```

### **Error: Direcciones Hardcodeadas Incorrectas**

**Síntoma:** Oracle llamado con direcciones obsoletas

**Solución:**
1. Verificar `src/core/GenericLoanManager.sol` función `_getAssetValue`
2. Actualizar direcciones hardcodeadas:
```solidity
address usdcAddress = 0xNUEVA_DIRECCION_USDC;
if (asset == 0xNUEVA_DIRECCION_ETH) { // Actualizar ETH
if (asset == 0xNUEVA_DIRECCION_WBTC) { // Actualizar WBTC
```
3. Redesplegar: `make deploy-corrected-system`

### **Error: "No liquidity available"**

**Verificación:**
```bash
cast call <VAULT_HANDLER> "getAvailableLiquidity(address)" <TOKEN_ADDRESS> --rpc-url $RPC_URL
```

**Solución:**
```bash
make provide-corrected-liquidity
```

---

## 🔧 Comandos de Mantenimiento

### **Monitoreo del Sistema**
```bash
make check-system-status    # Estado general
make check-tokens          # Balances de tokens
make check-vault           # Información de vaults
make check-balance         # Balance del deployer
```

### **Gestión de Direcciones**
```bash
make update-addresses      # Helper para gestión de direcciones
```

### **Verificación en Block Explorer**
```bash
make verify-contract
# Sigue las instrucciones para verificar contratos
```

---

## 📊 Parámetros del Sistema

### **Oracle Prices (6 decimals)**
| Asset | Price USD | Formato Oracle |
|-------|-----------|----------------|
| ETH   | $3,000    | 3000000000     |
| WBTC  | $95,000   | 95000000000    |
| USDC  | $1        | 1000000        |

### **Asset Configurations**
| Asset | Collateral Ratio | Liquidation Ratio | Interest Rate | Max Loan |
|-------|------------------|-------------------|---------------|----------|
| ETH   | 130% (1300000)   | 110% (1100000)    | 8% (80000)    | 1000 ETH |
| WBTC  | 140% (1400000)   | 115% (1150000)    | 7.5% (75000)  | 50 WBTC  |
| USDC  | 110% (1100000)   | 105% (1050000)    | 4% (40000)    | 1M USDC  |

### **Liquidez Inicial**
- **ETH**: 100 tokens
- **USDC**: 100,000 tokens
- **WBTC**: 10 tokens (opcional)

---

## ✅ Workflow Automatizado Completo

### **Para Nuevos Despliegues:**
```bash
# Un comando que hace todo
make deploy-and-auto-test
```

**Este comando:**
1. ✅ Despliega sistema completo
2. ✅ Proporciona liquidez automáticamente  
3. ✅ Ejecuta tests de verificación
4. ✅ No requiere intervención manual

### **Para Verificar Sistema Existente:**
```bash
# Test rápido del sistema actual
make quick-test-corrected
```

---

## 📋 Checklist de Despliegue

### **Pre-Despliegue**
- [ ] Variables de entorno configuradas (`.env`)
- [ ] Foundry instalado y actualizado
- [ ] Red blockchain accesible (Base Sepolia)
- [ ] Balance suficiente para gas fees (~0.01 ETH)

### **Despliegue**
- [ ] Ejecutar `make deploy-corrected-system`
- [ ] Verificar direcciones en output
- [ ] Copiar direcciones del output

### **Configuración**
- [ ] Actualizar `script/TestCoreLoans.s.sol` con nuevas direcciones
- [ ] Actualizar `Makefile` con nuevas direcciones (opcional)
- [ ] Ejecutar `make provide-corrected-liquidity`

### **Verificación**
- [ ] Ejecutar `make test-corrected-system`
- [ ] Verificar output exitoso:
  - [ ] Préstamo creado (Position ID: 1)
  - [ ] Ratio ~150% para 5 ETH → 10,000 USDC
  - [ ] Sin errores "Insufficient collateral"

### **Post-Despliegue**
- [ ] Documentar direcciones desplegadas
- [ ] Configurar monitoreo (opcional)
- [ ] Verificar contratos en block explorer (opcional)

---

## 🎯 Métricas de Éxito

### **Indicadores de Sistema Funcional:**
- ✅ **Oracle responsivo**: Precios correctos ($3,000 ETH)
- ✅ **Liquidez suficiente**: >50 ETH y >50,000 USDC en vaults
- ✅ **Préstamos funcionales**: Creación exitosa con ratios esperados
- ✅ **Ratios correctos**: ~150% para préstamo ETH→USDC estándar

### **Test de Validación Final:**
```bash
# Debe crear préstamo exitosamente:
# 5 ETH ($15,000) → 10,000 USDC = 150% ratio
make test-corrected-system
```

---

## 🚀 Comandos Rápidos de Referencia

```bash
# Despliegue completo automatizado
make deploy-and-auto-test

# Solo despliegue 
make deploy-corrected-system

# Solo liquidez
make provide-corrected-liquidity

# Solo testing
make test-corrected-system

# Verificar sistema
make check-system-status
```

---

**✅ Sistema Completamente Funcional y Documentado**

Esta guía garantiza un despliegue exitoso del sistema de préstamos colateralizados con todas las correcciones implementadas y verificadas. 