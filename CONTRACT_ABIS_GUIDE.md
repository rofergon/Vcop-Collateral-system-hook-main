# 🔗 Contract ABIs Guide

## 📋 Introduction

This guide contains all the ABIs (Application Binary Interfaces) of the contracts in the VCOP system, their deployment addresses, and how to use them for frontend integration.

## 🏗️ Test Tokens (Mocks)

### MockETH  
- **Address**: `0x8b0A9d01Bb8f6E4B2B5C8AE4D6e4CF8A3fD5e9bE`
- **ABI**: `abi/extracted/MockETH.json`
- **Function**: ERC20 token that simulates ETH for testing

### MockWBTC
- **Address**: `0x2f6B1AD6E7C9F5B1E8D4A3b6C5e8F9A2B3c4D5E6`
- **ABI**: `abi/extracted/MockWBTC.json`
- **Function**: ERC20 token that simulates WBTC for testing

### MockUSDC
- **Address**: `0x6bf9aDaCefe6a159710094eA5334786E35EE73f9`
- **ABI**: `abi/extracted/MockUSDC.json`
- **Function**: ERC20 token that simulates USDC for testing

## 🎯 VCOP Collateral System

### VCOPCollateralized (VCOP Token)
- **Address**: `0xb70d3B325246b638787551E57bB880404b0Be611`
- **ABI**: `abi/extracted/VCOPCollateralized.json`
- **Function**: Main VCOP token with collateral functionalities

### VCOPOracle
- **Address**: `0xD217C3Ea3D4aB981c7E96754E7d2cC588d4773dB`
- **ABI**: `abi/extracted/VCOPOracle.json`
- **Function**: Price oracle for VCOP/USD and USD/COP

### VCOPPriceCalculator
- **Address**: `0x8CE89692FBb96c5F4eBDCcBE706d3470d215Ee5F`
- **ABI**: `abi/extracted/VCOPPriceCalculator.json`
- **Function**: Price calculator for swap operations

### VCOPCollateralManager
- **Address**: `0x98D15b2ae44f9e2d8eE5C60c5B3d9DA475EAc8B3`
- **ABI**: `abi/extracted/VCOPCollateralManager.json`
- **Function**: Collateral management and PSM operations

### VCOPCollateralHook
- **Address**: `0x72A41abE3d63f57D5ef475AC514a11efac1304c0`
- **ABI**: `abi/extracted/VCOPCollateralHook.json`
- **Function**: Uniswap V4 hook for automatic collateral management

## 🏦 Core Lending System

### GenericLoanManager
- **Address**: `0x787d48ba90a5Badb0A4ACaaD721FD63a3a5561DE`
- **ABI**: `abi/extracted/GenericLoanManager.json`
- **Function**: Main generic loan manager

### FlexibleLoanManager
- **Address**: `0x63500615EE23a540257F7D32a2a762B461662369`
- **ABI**: `abi/extracted/FlexibleLoanManager.json`
- **Function**: Loan manager with greater flexibility

### VaultBasedHandler
- **Address**: `0x41e0Bb71A57ecf69d19857f54e9C10F89c94B191`
- **ABI**: `abi/extracted/VaultBasedHandler.json`
- **Function**: Vault-based asset handler (ETH, WBTC, USDC)

### MintableBurnableHandler
- **Address**: `0x2890C2525f24924cFB989d7A5e6039fb721f06B9`
- **ABI**: `abi/extracted/MintableBurnableHandler.json`
- **Function**: Handler for mintable/burnable tokens (VCOP)

### FlexibleAssetHandler
- **Address**: `0x75c88aaba7E4Ffa46Ca95673147DA8D6aE80b592`
- **ABI**: `abi/extracted/FlexibleAssetHandler.json`
- **Function**: Flexible asset handler

### RiskCalculator
- **Address**: `0x1CD4E00f22324720BFEca771ED652078fC3FB873`
- **ABI**: `abi/extracted/RiskCalculator.json`
- **Function**: Risk calculator for loan positions

## 🔧 Interfaces (Optional)

### IAssetHandler
- **ABI**: `abi/extracted/IAssetHandler.json`
- **Function**: Interface for asset handlers

### ILoanManager
- **ABI**: `abi/extracted/ILoanManager.json`
- **Function**: Interface for loan managers

### IOracle
- **ABI**: `abi/extracted/IOracle.json`
- **Function**: Interface for price oracles

## 🛠️ How to Use the ABIs

### 1. File Locations
All ABIs are available in: `abi/extracted/`

### 2. JavaScript/TypeScript Integration
```javascript
// Example of ABI loading
const fs = require('fs');
const vcopTokenABI = JSON.parse(fs.readFileSync('abi/extracted/VCOPCollateralized.json', 'utf8'));
const oracleABI = JSON.parse(fs.readFileSync('abi/extracted/VCOPOracle.json', 'utf8'));

// Use with ethers.js
const { ethers } = require('ethers');
const provider = new ethers.providers.JsonRpcProvider('https://sepolia.base.org');
const vcopContract = new ethers.Contract('0xb70d3B325246b638787551E57bB880404b0Be611', vcopTokenABI, provider);
```

### 3. Python Integration (web3.py)
```python
import json
from web3 import Web3

# Load ABI
with open('abi/extracted/VCOPCollateralized.json', 'r') as f:
    vcop_abi = json.load(f)

# Connect to network
w3 = Web3(Web3.HTTPProvider('https://sepolia.base.org'))
vcop_contract = w3.eth.contract(address='0xb70d3B325246b638787551E57bB880404b0Be611', abi=vcop_abi)
```

### 4. Contract Verification
```bash
# Verify a contract on the explorer
forge verify-contract [CONTRACT_ADDRESS] --constructor-args [ARGS] --etherscan-api-key [API_KEY]
```

## 📊 Asset Configuration

### Collateral Ratios
- **ETH**: 130% collateral, 110% liquidation, 8% interest
- **WBTC**: 140% collateral, 115% liquidation, 7.5% interest  
- **USDC**: 110% collateral, 105% liquidation, 4% interest

### Oracle Prices (6 decimals)
- **ETH/USDC**: 2,500.000000 USD
- **WBTC/USDC**: 45,000.000000 USD
- **USDC/USDC**: 1.000000 USD
- **USD/COP**: 4,200.000000 COP

## 🧪 Available Test Commands

```bash
# Core system tests
make test-core-loans          # Complete lending system tests
make test-eth-usdc-loan       # ETH->USDC loan
make test-usdc-eth-loan       # USDC->ETH loan

# VCOP system tests
make test-loans               # VCOP loan tests
make test-liquidation         # Liquidation tests
make test-psm                 # PSM tests

# Verifications
make check-new-oracle         # Check oracle prices
make check-addresses          # Show deployed addresses
make check-tokens             # Check token balances
```

## 🔄 Regenerate ABIs

If you need to regenerate the ABIs after code changes:

```bash
# Recompile contracts
forge build

# Extract ABIs again
./tools/extract-abis.sh
```

## 📁 File Structure

```
abi/
├── extracted/                 # Automatically extracted ABIs
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
└── [previous ABI files]

deployed-addresses.json        # Deployed contract addresses
tools/extract-abis.sh               # Script to extract ABIs
```

## 🎯 Next Steps

1. **Frontend Integration**: Use the ABIs to create user interfaces
2. **Testing**: Run the available test commands
3. **Verification**: Verify contracts on block explorers
4. **Monitoring**: Implement contract event monitoring

---

*📝 Note: This system is deployed on Base Sepolia for testing. For production, use the corresponding mainnet commands.* 