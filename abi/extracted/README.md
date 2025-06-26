# ABIs de Contratos VCOP para Frontend

Este directorio contiene todos los ABIs (Application Binary Interfaces) necesarios para interactuar con los contratos desplegados del sistema VCOP desde el frontend.

## 📁 Estructura de Archivos

- `frontend-config.json` - Configuración principal con direcciones y mapeo de ABIs
- `contract-summary.json` - Resumen completo del deployment
- `*.json` - Archivos ABI individuales para cada contrato

## 🚀 Uso en Frontend

### 1. Configuración Básica (JavaScript/TypeScript)

```javascript
import frontendConfig from './abi/extracted/frontend-config.json';

// Cargar ABI de un contrato específico
async function loadContractABI(contractName) {
  const config = frontendConfig.contracts[contractName];
  if (!config) {
    throw new Error(`Contract ${contractName} not found`);
  }
  
  const abiResponse = await fetch(`./abi/extracted/${config.abi}`);
  const abi = await abiResponse.json();
  
  return {
    address: config.address,
    abi: abi
  };
}

// Ejemplo de uso
const vcopToken = await loadContractABI('VCOPCollateralized');
console.log('VCOP Token Address:', vcopToken.address);
```

### 2. Usando con Ethers.js

```javascript
import { ethers } from 'ethers';
import frontendConfig from './abi/extracted/frontend-config.json';
import vcopABI from './abi/extracted/VCOPCollateralized.json';

// Configurar provider (Base Sepolia)
const provider = new ethers.providers.JsonRpcProvider('https://sepolia.base.org');

// Crear instancia del contrato VCOP
const vcopContract = new ethers.Contract(
  frontendConfig.contracts.VCOPCollateralized.address,
  vcopABI,
  provider
);

// Leer balance de VCOP
async function getVCOPBalance(userAddress) {
  const balance = await vcopContract.balanceOf(userAddress);
  // VCOP tiene 6 decimales
  return ethers.utils.formatUnits(balance, 6);
}

// Leer información del token
async function getTokenInfo() {
  const [name, symbol, decimals, totalSupply] = await Promise.all([
    vcopContract.name(),
    vcopContract.symbol(),
    vcopContract.decimals(),
    vcopContract.totalSupply()
  ]);
  
  return {
    name,
    symbol,
    decimals,
    totalSupply: ethers.utils.formatUnits(totalSupply, decimals)
  };
}
```

### 3. Usando con Web3.js

```javascript
import Web3 from 'web3';
import frontendConfig from './abi/extracted/frontend-config.json';
import vcopABI from './abi/extracted/VCOPCollateralized.json';

// Configurar Web3
const web3 = new Web3('https://sepolia.base.org');

// Crear instancia del contrato
const vcopContract = new web3.eth.Contract(
  vcopABI,
  frontendConfig.contracts.VCOPCollateralized.address
);

// Ejemplo de lectura
async function getVCOPInfo() {
  const totalSupply = await vcopContract.methods.totalSupply().call();
  const name = await vcopContract.methods.name().call();
  const symbol = await vcopContract.methods.symbol().call();
  
  return { totalSupply, name, symbol };
}
```

### 4. Interacción con Loan Manager

```javascript
import flexibleLoanManagerABI from './abi/extracted/FlexibleLoanManager.json';

// Crear contrato de gestión de préstamos
const loanManager = new ethers.Contract(
  frontendConfig.contracts.FlexibleLoanManager.address,
  flexibleLoanManagerABI,
  signer // Necesita un signer para transacciones
);

// Obtener posiciones de un usuario
async function getUserPositions(userAddress) {
  try {
    const positions = await loanManager.getUserPositions(userAddress);
    return positions;
  } catch (error) {
    console.error('Error getting positions:', error);
    return [];
  }
}

// Crear un nuevo préstamo
async function createLoan(loanTerms) {
  try {
    const tx = await loanManager.createLoan(loanTerms);
    const receipt = await tx.wait();
    console.log('Loan created:', receipt.transactionHash);
    return receipt;
  } catch (error) {
    console.error('Error creating loan:', error);
    throw error;
  }
}
```

### 5. Monitoreo de Precios con Oracle

```javascript
import mockOracleABI from './abi/extracted/MockVCOPOracle.json';

const oracle = new ethers.Contract(
  frontendConfig.contracts.MockVCOPOracle.address,
  mockOracleABI,
  provider
);

// Obtener precios actuales
async function getCurrentPrices() {
  try {
    const [usdToCop, vcopToCop, vcopToUsd] = await Promise.all([
      oracle.getUsdToCopRateView(),
      oracle.getVcopToCopRateView(),
      oracle.getVcopToUsdPrice()
    ]);
    
    return {
      usdToCop: ethers.utils.formatUnits(usdToCop, 6),
      vcopToCop: ethers.utils.formatUnits(vcopToCop, 6),
      vcopToUsd: ethers.utils.formatUnits(vcopToUsd, 6)
    };
  } catch (error) {
    console.error('Error getting prices:', error);
    return null;
  }
}

// Escuchar eventos de cambio de precio
function subscribeToPriceUpdates() {
  oracle.on('VcopToUsdRateUpdated', (oldRate, newRate, event) => {
    console.log('Price updated:', {
      oldPrice: ethers.utils.formatUnits(oldRate, 6),
      newPrice: ethers.utils.formatUnits(newRate, 6),
      blockNumber: event.blockNumber
    });
  });
}
```

## 📋 Contratos Principales

### Tokens
- **MockETH** - Token ETH de prueba
- **MockWBTC** - Token WBTC de prueba  
- **MockUSDC** - Token USDC de prueba
- **VCOPCollateralized** - Token VCOP principal

### Sistema de Colateral VCOP
- **MockVCOPOracle** - Oracle para precios (testing)
- **VCOPCollateralManager** - Gestión de colateral
- **VCOPCollateralHook** - Hook de Uniswap v4

### Sistema de Préstamos
- **FlexibleLoanManager** - Gestión flexible de préstamos
- **GenericLoanManager** - Gestión genérica de préstamos
- **FlexibleAssetHandler** - Manejo de activos flexibles
- **VaultBasedHandler** - Manejo basado en vault

### Automatización
- **LoanAutomationKeeperOptimized** - Keeper optimizado
- **LoanManagerAutomationAdapter** - Adaptador de automatización

## 🌐 Red de Deployment

**Red:** Base Sepolia Testnet
**RPC URL:** `https://sepolia.base.org`
**Chain ID:** `84532`

## 🔗 Links Útiles

- [Base Sepolia Explorer](https://sepolia.basescan.org/)
- [Base Bridge](https://bridge.base.org/)
- [Documentación Base](https://docs.base.org/)

## ⚠️ Notas Importantes

1. Todos los contratos están desplegados en **Base Sepolia** (testnet)
2. Los tokens mock son solo para testing
3. Los precios en el oracle mock se pueden manipular para pruebas
4. Usar siempre las direcciones del archivo `frontend-config.json`
5. VCOP usa 6 decimales (no 18 como ETH)

## 🛠️ Troubleshooting

### Error: "Contract not deployed"
- Verificar que estás conectado a Base Sepolia
- Confirmar las direcciones en `frontend-config.json`

### Error: "Invalid ABI"
- Asegurar que el archivo ABI se carga correctamente
- Verificar que el contrato existe en la dirección especificada

### Error: "Insufficient permissions"
- Algunos métodos requieren que el usuario sea owner o tenga permisos específicos
- Revisar los roles y permisos del contrato 