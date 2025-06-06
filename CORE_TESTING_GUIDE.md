# Guía de Pruebas del Sistema Core

## 📋 Resumen

Esta guía describe cómo probar el sistema de préstamos core con las monedas mock desplegadas en Base Sepolia. El sistema permite intercambiar el orden de los activos para probar diferentes combinaciones de colateral y préstamos.

## 🏗️ Contratos Desplegados

### Tokens Mock
- **MockETH:** `0x21756f22e0945Ed3faB38D05Cf8E933845a60622`
- **MockWBTC:** `0xfb5810A37Eb47df5a498673237eD16ace3600162`
- **MockUSDC:** `0x9B051Dbf5bbFA94c9F18617a2D10AC9614D41d6c`

### Contratos Core
- **VaultBasedHandler:** `0x26a5B76417f4b12131542CEfd9083e70c9E647B1`
- **GenericLoanManager:** `0x374A7b5353F2E1E002Af4DD02138183776037Ea2`
- **FlexibleLoanManager:** `0x8F25AF7A087AC48f13f841C9d241A2094301547b`

## 🧪 Pruebas Disponibles

### 1. Pruebas Básicas de Préstamos

#### ETH como Colateral → USDC como Préstamo
```bash
make test-eth-usdc-loan
```
- **Colateral:** 5 ETH
- **Préstamo:** 10,000 USDC
- **LTV Máximo:** 70%
- **Tasa de Interés:** 8% anual

#### USDC como Colateral → ETH como Préstamo
```bash
make test-usdc-eth-loan
```
- **Colateral:** 20,000 USDC
- **Préstamo:** 3 ETH
- **LTV Máximo:** 65%
- **Tasa de Interés:** 7.5% anual

### 2. Suite Completa de Pruebas
```bash
make test-core-loans
```

Esta ejecuta todos los tests incluyendo:
- Creación de préstamos con ambas combinaciones
- Operaciones avanzadas (agregar/retirar colateral)
- Análisis de riesgo básico
- Simulación de acumulación de intereses
- Pago y cierre de posiciones

### 3. Pruebas Específicas

#### Operaciones Avanzadas
```bash
make test-advanced-operations
```
- Agregar colateral adicional a posiciones existentes
- Simular paso del tiempo (30 días)
- Actualizar y calcular intereses acumulados
- Intentar retirar colateral (sujeto a ratios de colateralización)

#### Análisis de Riesgo
```bash
make test-risk-analysis
```
- Calcular ratios de colateralización
- Evaluar estado de riesgo (SALUDABLE, ADVERTENCIA, PELIGRO, CRÍTICO, LIQUIDABLE)
- Verificar si posiciones son liquidables
- Análisis de deuda total e intereses

#### Pago y Cierre
```bash
make test-loan-repayment
```
- Pago completo de préstamos
- Pago parcial cuando hay fondos insuficientes
- Recuperación automática de colateral
- Cierre de posiciones

## 🔧 Configuración de Liquidez

### Asegurar Liquidez Antes de Pruebas

#### ETH
```bash
make provide-eth-liquidity
```

#### WBTC
```bash
make provide-wbtc-liquidity
```

#### USDC
```bash
make provide-usdc-liquidity
```

### Verificar Estado del Sistema
```bash
make check-tokens    # Verificar balances del deployer
make check-vault     # Verificar liquidez en vaults
```

## 📊 Configuraciones de Activos

| Asset | Collateral Ratio | Liquidation Ratio | Interest Rate | Estado |
|-------|------------------|-------------------|---------------|---------|
| **ETH** | 130% | 110% | 8% | ✅ Configurado |
| **WBTC** | 140% | 115% | 7.5% | ⚠️ Requiere configuración |
| **USDC** | 110% | 105% | 4% | ✅ Configurado |

## 🎯 Escenarios de Prueba

### Escenario 1: Préstamo Saludable
```bash
# ETH → USDC con ratio alto
make test-eth-usdc-loan
```
- ✅ Ratio inicial ~200%+
- ✅ Muy bajo riesgo de liquidación
- ✅ Permite retirar colateral parcial

### Escenario 2: Préstamo Conservador
```bash
# USDC → ETH con términos conservadores
make test-usdc-eth-loan
```
- ✅ Ratio inicial ~150-180%
- ⚠️ Riesgo moderado
- 🔄 Requiere monitoreo

### Escenario 3: Operaciones de Gestión
```bash
# Pruebas de gestión activa
make test-advanced-operations
```
- 📈 Agregar colateral para mejorar ratio
- ⏰ Simular acumulación de intereses
- 📉 Intentar retiros de colateral

## 🚨 Funcionalidades del Sistema de Riesgo

### Niveles de Riesgo
- **SALUDABLE** (>200%): ✅ Sin riesgo de liquidación
- **ADVERTENCIA** (150-200%): ⚠️ Monitoreo recomendado
- **PELIGRO** (120-150%): 🔴 Riesgo alto
- **CRÍTICO** (110-120%): 🚨 Riesgo muy alto
- **LIQUIDABLE** (<110%): ⚡ Sujeto a liquidación

### Desplegar RiskCalculator (Opcional)
```bash
make deploy-risk-calculator
```

El RiskCalculator proporciona:
- 📊 Métricas de riesgo detalladas
- 💹 Análisis de impacto de precios
- 🔮 Proyecciones de riesgo futuro
- 📈 Análisis de portfolio

## 💡 Casos de Uso y Ejemplos

### 1. Usuario Conservador
- Usa USDC como colateral (estable)
- Pide préstamo en ETH para exposición
- Mantiene ratios >200%

### 2. Usuario Agresivo
- Usa ETH como colateral (volátil)
- Pide préstamo en USDC (estable)
- Opera con ratios 120-150%

### 3. Arbitrajista
- Intercambia entre posiciones
- Usa ganancias para agregar colateral
- Maneja múltiples posiciones

## 🔄 Flujo de Pruebas Recomendado

### Paso 1: Preparación
```bash
make check-addresses
make check-balance
make check-tokens
```

### Paso 2: Asegurar Liquidez
```bash
make provide-eth-liquidity
make provide-usdc-liquidity
```

### Paso 3: Pruebas Básicas
```bash
make test-eth-usdc-loan
make test-usdc-eth-loan
```

### Paso 4: Pruebas Avanzadas
```bash
make test-advanced-operations
make test-risk-analysis
```

### Paso 5: Cierre y Limpieza
```bash
make test-loan-repayment
```

## 📝 Logs y Debugging

### Verbose Output
Todos los comandos de prueba incluyen `-vv` para output detallado:
```bash
forge script script/TestSimpleLoans.s.sol --rpc-url $RPC_URL --broadcast -vv
```

### Información Mostrada
- ✅ Estado de inicialización
- 💰 Balances antes y después
- 📊 Detalles de posiciones creadas
- 🧮 Cálculos de ratios y riesgos
- ⚠️ Errores y advertencias
- 🔄 Resultados de operaciones

## 🛠️ Solución de Problemas

### Error: "Insufficient liquidity"
```bash
# Proporcionar más liquidez
make provide-eth-liquidity
make provide-usdc-liquidity
```

### Error: "Asset not supported"
- Verificar que el asset esté configurado en VaultBasedHandler
- Verificar direcciones de contratos en el script

### Error: "Insufficient collateral"
- Ajustar amounts en el script
- Verificar balances del deployer

### Error: "LTV exceeds maximum"
- Reducir loan amount o aumentar collateral amount
- Verificar configuraciones de LTV en el script

## 📞 Soporte

- **Contratos:** Desplegados en Base Sepolia testnet
- **Gas:** Configurado para testnet
- **Tokens:** Mock tokens para pruebas únicamente
- **Documentación:** Ver `DEPLOYMENT_SUMMARY.md` para detalles completos

---

**⚠️ Importante:** Este sistema está en Base Sepolia testnet únicamente. No usar en mainnet sin auditorías de seguridad completas. 