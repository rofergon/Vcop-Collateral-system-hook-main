#!/bin/bash

# Script para verificación de contratos Core en Base Sepolia
ETHERSCAN_API_KEY="${ETHERSCAN_API_KEY:-IS3DBRSG4KAU2T8BS54ECSD2TKSIT9T9CI}"

# Direcciones de los contratos desplegados en Base Sepolia
MOCK_ETH_ADDRESS="0x21756f22e0945Ed3faB38D05Cf8E933845a60622"
MOCK_WBTC_ADDRESS="0xfb5810A37Eb47df5a498673237eD16ace3600162"
MOCK_USDC_ADDRESS="0x9B051Dbf5bbFA94c9F18617a2D10AC9614D41d6c"
MINTABLE_BURNABLE_HANDLER_ADDRESS="0xCE64416861e2CbF0A6eF144b3720798cFfAcd1dB"
VAULT_BASED_HANDLER_ADDRESS="0x26a5B76417f4b12131542CEfd9083e70c9E647B1"
FLEXIBLE_ASSET_HANDLER_ADDRESS="0xFB0c77510218EcBF47B26150CEf4085Cc7d36a7b"
GENERIC_LOAN_MANAGER_ADDRESS="0x374A7b5353F2E1E002Af4DD02138183776037Ea2"
FLEXIBLE_LOAN_MANAGER_ADDRESS="0x8F25AF7A087AC48f13f841C9d241A2094301547b"
DEPLOYER_ADDRESS="0xA6B3D200cD34ca14d7579DAc8B054bf50a62c37c"

echo "Verificando contratos Core en Base Sepolia..."
echo "Mock ETH: $MOCK_ETH_ADDRESS"
echo "Mock WBTC: $MOCK_WBTC_ADDRESS"
echo "Mock USDC: $MOCK_USDC_ADDRESS"
echo "MintableBurnableHandler: $MINTABLE_BURNABLE_HANDLER_ADDRESS"
echo "VaultBasedHandler: $VAULT_BASED_HANDLER_ADDRESS"
echo "FlexibleAssetHandler: $FLEXIBLE_ASSET_HANDLER_ADDRESS"
echo "GenericLoanManager: $GENERIC_LOAN_MANAGER_ADDRESS"
echo "FlexibleLoanManager: $FLEXIBLE_LOAN_MANAGER_ADDRESS"

# 1. Verificar Mock ETH
echo -e "\nVerificando Mock ETH..."
forge verify-contract \
    --chain-id 84532 \
    --compiler-version 0.8.26 \
    --etherscan-api-key $ETHERSCAN_API_KEY \
    --watch \
    $MOCK_ETH_ADDRESS \
    src/mocks/MockETH.sol:MockETH

# 2. Verificar Mock WBTC
echo -e "\nVerificando Mock WBTC..."
forge verify-contract \
    --chain-id 84532 \
    --compiler-version 0.8.26 \
    --etherscan-api-key $ETHERSCAN_API_KEY \
    --watch \
    $MOCK_WBTC_ADDRESS \
    src/mocks/MockWBTC.sol:MockWBTC

# 3. Verificar Mock USDC
echo -e "\nVerificando Mock USDC..."
forge verify-contract \
    --chain-id 84532 \
    --compiler-version 0.8.26 \
    --etherscan-api-key $ETHERSCAN_API_KEY \
    --watch \
    $MOCK_USDC_ADDRESS \
    src/mocks/MockUSDC.sol:MockUSDC

# 4. Verificar MintableBurnableHandler
echo -e "\nVerificando MintableBurnableHandler..."
forge verify-contract \
    --chain-id 84532 \
    --compiler-version 0.8.26 \
    --etherscan-api-key $ETHERSCAN_API_KEY \
    --watch \
    $MINTABLE_BURNABLE_HANDLER_ADDRESS \
    src/core/MintableBurnableHandler.sol:MintableBurnableHandler

# 5. Verificar VaultBasedHandler
echo -e "\nVerificando VaultBasedHandler..."
forge verify-contract \
    --chain-id 84532 \
    --compiler-version 0.8.26 \
    --etherscan-api-key $ETHERSCAN_API_KEY \
    --watch \
    $VAULT_BASED_HANDLER_ADDRESS \
    src/core/VaultBasedHandler.sol:VaultBasedHandler

# 6. Verificar FlexibleAssetHandler
echo -e "\nVerificando FlexibleAssetHandler..."
forge verify-contract \
    --chain-id 84532 \
    --compiler-version 0.8.26 \
    --etherscan-api-key $ETHERSCAN_API_KEY \
    --watch \
    $FLEXIBLE_ASSET_HANDLER_ADDRESS \
    src/core/FlexibleAssetHandler.sol:FlexibleAssetHandler

# 7. Verificar GenericLoanManager
echo -e "\nVerificando GenericLoanManager..."
forge verify-contract \
    --chain-id 84532 \
    --compiler-version 0.8.26 \
    --constructor-args $(cast abi-encode "constructor(address,address)" $DEPLOYER_ADDRESS $DEPLOYER_ADDRESS) \
    --etherscan-api-key $ETHERSCAN_API_KEY \
    --watch \
    $GENERIC_LOAN_MANAGER_ADDRESS \
    src/core/GenericLoanManager.sol:GenericLoanManager

# 8. Verificar FlexibleLoanManager
echo -e "\nVerificando FlexibleLoanManager..."
forge verify-contract \
    --chain-id 84532 \
    --compiler-version 0.8.26 \
    --constructor-args $(cast abi-encode "constructor(address,address)" $DEPLOYER_ADDRESS $DEPLOYER_ADDRESS) \
    --etherscan-api-key $ETHERSCAN_API_KEY \
    --watch \
    $FLEXIBLE_LOAN_MANAGER_ADDRESS \
    src/core/FlexibleLoanManager.sol:FlexibleLoanManager

echo -e "\n¡Verificación de contratos Core completada!"
echo -e "\nPuedes revisar los contratos verificados en:"
echo "https://sepolia.basescan.org/address/$MOCK_ETH_ADDRESS"
echo "https://sepolia.basescan.org/address/$MOCK_WBTC_ADDRESS"
echo "https://sepolia.basescan.org/address/$MOCK_USDC_ADDRESS"
echo "https://sepolia.basescan.org/address/$MINTABLE_BURNABLE_HANDLER_ADDRESS"
echo "https://sepolia.basescan.org/address/$VAULT_BASED_HANDLER_ADDRESS"
echo "https://sepolia.basescan.org/address/$FLEXIBLE_ASSET_HANDLER_ADDRESS"
echo "https://sepolia.basescan.org/address/$GENERIC_LOAN_MANAGER_ADDRESS"
echo "https://sepolia.basescan.org/address/$FLEXIBLE_LOAN_MANAGER_ADDRESS" 