#!/bin/bash

# Script to extract ABIs from all deployed contracts
# Based on deployed-addresses.json

echo "🔧 Extracting ABIs for all deployed contracts..."

# Create abi directory if it doesn't exist
mkdir -p abi/extracted

# Function to extract ABI from compiled contract JSON
extract_abi() {
    local contract_path="$1"
    local output_name="$2"
    
    if [ -f "$contract_path" ]; then
        echo "📄 Extracting ABI for $output_name..."
        jq '.abi' "$contract_path" > "abi/extracted/${output_name}.json"
        echo "✅ ABI saved to abi/extracted/${output_name}.json"
    else
        echo "❌ Contract file not found: $contract_path"
    fi
}

echo ""
echo "=== EXTRACTING MOCK TOKENS ==="
extract_abi "out/MockETH.sol/MockETH.json" "MockETH"
extract_abi "out/MockWBTC.sol/MockWBTC.json" "MockWBTC"
extract_abi "out/MockUSDC.sol/MockUSDC.json" "MockUSDC"

echo ""
echo "=== EXTRACTING VCOP COLLATERAL SYSTEM ==="
extract_abi "out/VCOPCollateralized.sol/VCOPCollateralized.json" "VCOPCollateralized"
extract_abi "out/VCOPOracle.sol/VCOPOracle.json" "VCOPOracle"
extract_abi "out/VCOPPriceCalculator.sol/VCOPPriceCalculator.json" "VCOPPriceCalculator"
extract_abi "out/VCOPCollateralManager.sol/VCOPCollateralManager.json" "VCOPCollateralManager"
extract_abi "out/VCOPCollateralHook.sol/VCOPCollateralHook.json" "VCOPCollateralHook"

echo ""
echo "=== EXTRACTING CORE LENDING SYSTEM ==="
extract_abi "out/GenericLoanManager.sol/GenericLoanManager.json" "GenericLoanManager"
extract_abi "out/FlexibleLoanManager.sol/FlexibleLoanManager.json" "FlexibleLoanManager"
extract_abi "out/VaultBasedHandler.sol/VaultBasedHandler.json" "VaultBasedHandler"
extract_abi "out/MintableBurnableHandler.sol/MintableBurnableHandler.json" "MintableBurnableHandler"
extract_abi "out/FlexibleAssetHandler.sol/FlexibleAssetHandler.json" "FlexibleAssetHandler"
extract_abi "out/RiskCalculator.sol/RiskCalculator.json" "RiskCalculator"

echo ""
echo "=== EXTRACTING INTERFACES (Optional) ==="
extract_abi "out/IAssetHandler.sol/IAssetHandler.json" "IAssetHandler"
extract_abi "out/ILoanManager.sol/ILoanManager.json" "ILoanManager"
extract_abi "out/IOracle.sol/IOracle.json" "IOracle"

echo ""
echo "📋 SUMMARY OF EXTRACTED ABIs:"
echo "=============================================="
echo "📁 Mock Tokens:"
echo "   - MockETH.json"
echo "   - MockWBTC.json" 
echo "   - MockUSDC.json"
echo ""
echo "📁 VCOP Collateral System:"
echo "   - VCOPCollateralized.json"
echo "   - VCOPOracle.json"
echo "   - VCOPPriceCalculator.json"
echo "   - VCOPCollateralManager.json"
echo "   - VCOPCollateralHook.json"
echo ""
echo "📁 Core Lending System:"
echo "   - GenericLoanManager.json"
echo "   - FlexibleLoanManager.json"
echo "   - VaultBasedHandler.json"
echo "   - MintableBurnableHandler.json"
echo "   - FlexibleAssetHandler.json"
echo "   - RiskCalculator.json"
echo ""
echo "📁 Interfaces:"
echo "   - IAssetHandler.json"
echo "   - ILoanManager.json"
echo "   - IOracle.json"
echo ""
echo "🎯 All ABIs extracted to: abi/extracted/"
echo ""
echo "📋 Contract Addresses from Deployment:"
cat deployed-addresses.json | jq .
echo ""
echo "✨ ABI extraction completed successfully!" 