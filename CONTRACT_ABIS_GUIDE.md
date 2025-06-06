# Guía Completa de Contratos y ABIs - Sistema VCOP Unificado

## 📋 Información del Despliegue

- **Red**: Base Sepolia
- **Chain ID**: 84532
- **Deployer**: `0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38`
- **Pool Manager**: `0x05E73354cFDd6745C338b50BcFDfA3Aa6fA03408`
- **Fecha de Despliegue**: 1749177750

## 🪙 Mock Tokens

### MockETH
- **Dirección**: `0x7c79c4ebD92837E95fd8B2c25975CE544Eb17D82`
- **ABI**: `abi/extracted/MockETH.json`
- **Función**: Token ERC20 que simula ETH para pruebas

### MockWBTC  
- **Dirección**: `0xE51293840CA88a5183fd0dc49eE2abaC480572c3`
- **ABI**: `abi/extracted/MockWBTC.json`
- **Función**: Token ERC20 que simula WBTC para pruebas

### MockUSDC
- **Dirección**: `0x6bf9aDaCefe6a159710094eA5334786E35EE73f9`
- **ABI**: `abi/extracted/MockUSDC.json`
- **Función**: Token ERC20 que simula USDC para pruebas

## 🎯 Sistema de Colateral VCOP

### VCOPCollateralized (Token VCOP)
- **Dirección**: `0xb70d3B325246b638787551E57bB880404b0Be611`
- **ABI**: `abi/extracted/VCOPCollateralized.json`
- **Función**: Token VCOP principal con funcionalidades de colateral

### VCOPOracle
- **Dirección**: `0xD217C3Ea3D4aB981c7E96754E7d2cC588d4773dB`
- **ABI**: `abi/extracted/VCOPOracle.json`
- **Función**: Oráculo de precios para VCOP/USD y USD/COP

### VCOPPriceCalculator
- **Dirección**: `0x8CE89692FBb96c5F4eBDCcBE706d3470d215Ee5F`
- **ABI**: `abi/extracted/VCOPPriceCalculator.json`
- **Función**: Calculadora de precios para operaciones de swap

### VCOPCollateralManager
- **Dirección**: `0x98D15b2ae44f9e2d8eE5C60c5B3d9DA475EAc8B3`
- **ABI**: `abi/extracted/VCOPCollateralManager.json`
- **Función**: Gestión de colateral y operaciones PSM

### VCOPCollateralHook
- **Dirección**: `0x72A41abE3d63f57D5ef475AC514a11efac1304c0`
- **ABI**: `abi/extracted/VCOPCollateralHook.json`
- **Función**: Hook de Uniswap V4 para gestión automática de colateral

## 🏦 Sistema Core de Préstamos

### GenericLoanManager
- **Dirección**: `0x787d48ba90a5Badb0A4ACaaD721FD63a3a5561DE`
- **ABI**: `abi/extracted/GenericLoanManager.json`
- **Función**: Gestor principal de préstamos genéricos

### FlexibleLoanManager
- **Dirección**: `0x63500615EE23a540257F7D32a2a762B461662369`
- **ABI**: `abi/extracted/FlexibleLoanManager.json`
- **Función**: Gestor de préstamos con mayor flexibilidad

### VaultBasedHandler
- **Dirección**: `0x41e0Bb71A57ecf69d19857f54e9C10F89c94B191`
- **ABI**: `abi/extracted/VaultBasedHandler.json`
- **Función**: Manejador de activos basado en vaults (ETH, WBTC, USDC)

### MintableBurnableHandler
- **Dirección**: `0x2890C2525f24924cFB989d7A5e6039fb721f06B9`
- **ABI**: `abi/extracted/MintableBurnableHandler.json`
- **Función**: Manejador para tokens mintables/quemables (VCOP)

### FlexibleAssetHandler
- **Dirección**: `0x75c88aaba7E4Ffa46Ca95673147DA8D6aE80b592`
- **ABI**: `abi/extracted/FlexibleAssetHandler.json`
- **Función**: Manejador flexible de activos

### RiskCalculator
- **Dirección**: `0x1CD4E00f22324720BFEca771ED652078fC3FB873`
- **ABI**: `abi/extracted/RiskCalculator.json`
- **Función**: Calculadora de riesgos para posiciones de préstamo

## 🔧 Interfaces (Opcional)

### IAssetHandler
- **ABI**: `abi/extracted/IAssetHandler.json`
- **Función**: Interfaz para manejadores de activos

### ILoanManager
- **ABI**: `abi/extracted/ILoanManager.json`
- **Función**: Interfaz para gestores de préstamos

### IOracle
- **ABI**: `abi/extracted/IOracle.json`
- **Función**: Interfaz para oráculos de precios

## 🛠️ Cómo Usar los ABIs

### 1. Archivos de Ubicación
Todos los ABIs están disponibles en: `abi/extracted/`

### 2. Integración en JavaScript/TypeScript
```javascript
// Ejemplo de carga de ABI
const fs = require('fs');
const vcopTokenABI = JSON.parse(fs.readFileSync('abi/extracted/VCOPCollateralized.json', 'utf8'));
const oracleABI = JSON.parse(fs.readFileSync('abi/extracted/VCOPOracle.json', 'utf8'));

// Usar con ethers.js
const { ethers } = require('ethers');
const provider = new ethers.providers.JsonRpcProvider('https://sepolia.base.org');
const vcopContract = new ethers.Contract('0xb70d3B325246b638787551E57bB880404b0Be611', vcopTokenABI, provider);
```

### 3. Integración en Python (web3.py)
```python
import json
from web3 import Web3

# Cargar ABI
with open('abi/extracted/VCOPCollateralized.json', 'r') as f:
    vcop_abi = json.load(f)

# Conectar a la red
w3 = Web3(Web3.HTTPProvider('https://sepolia.base.org'))
vcop_contract = w3.eth.contract(address='0xb70d3B325246b638787551E57bB880404b0Be611', abi=vcop_abi)
```

### 4. Verificación de Contratos
```bash
# Verificar un contrato en el explorador
forge verify-contract [CONTRACT_ADDRESS] --constructor-args [ARGS] --etherscan-api-key [API_KEY]
```

## 📊 Configuración de Activos

### Ratios de Colateral
- **ETH**: 130% colateral, 110% liquidación, 8% interés
- **WBTC**: 140% colateral, 115% liquidación, 7.5% interés  
- **USDC**: 110% colateral, 105% liquidación, 4% interés

### Precios Oracle (6 decimales)
- **ETH/USDC**: 2,500.000000 USD
- **WBTC/USDC**: 45,000.000000 USD
- **USDC/USDC**: 1.000000 USD
- **USD/COP**: 4,200.000000 COP

## 🧪 Comandos de Prueba Disponibles

```bash
# Pruebas del sistema core
make test-core-loans          # Pruebas completas del sistema de préstamos
make test-eth-usdc-loan       # Préstamo ETH->USDC
make test-usdc-eth-loan       # Préstamo USDC->ETH

# Pruebas del sistema VCOP
make test-loans               # Pruebas de préstamos VCOP
make test-liquidation         # Pruebas de liquidación
make test-psm                 # Pruebas PSM

# Verificaciones
make check-new-oracle         # Verificar precios del oráculo
make check-addresses          # Mostrar direcciones desplegadas
make check-tokens             # Verificar balances de tokens
```

## 🔄 Regenerar ABIs

Si necesitas regenerar los ABIs después de cambios en el código:

```bash
# Recompilar contratos
forge build

# Extraer ABIs nuevamente
./extract-abis.sh
```

## 📁 Estructura de Archivos

```
abi/
├── extracted/                 # ABIs extraídos automáticamente
│   ├── MockETH.json
│   ├── MockWBTC.json
│   ├── MockUSDC.json
│   ├── VCOPCollateralized.json
│   ├── VCOPOracle.json
│   ├── VCOPPriceCalculator.json
│   ├── VCOPCollateralManager.json
│   ├── VCOPCollateralHook.json
│   ├── GenericLoanManager.json
│   ├── FlexibleLoanManager.json
│   ├── VaultBasedHandler.json
│   ├── MintableBurnableHandler.json
│   ├── FlexibleAssetHandler.json
│   ├── RiskCalculator.json
│   ├── IAssetHandler.json
│   ├── ILoanManager.json
│   └── IOracle.json
└── [archivos ABI anteriores]

deployed-addresses.json        # Direcciones de contratos desplegados
extract-abis.sh               # Script para extraer ABIs
```

## 🎯 Próximos Pasos

1. **Integración Frontend**: Usar los ABIs para crear interfaces de usuario
2. **Pruebas**: Ejecutar los comandos de prueba disponibles
3. **Verificación**: Verificar contratos en exploradores de bloques
4. **Monitoreo**: Implementar monitoreo de eventos de contratos

---

*📝 Nota: Este sistema está desplegado en Base Sepolia para pruebas. Para producción, usar los comandos de mainnet correspondientes.* 