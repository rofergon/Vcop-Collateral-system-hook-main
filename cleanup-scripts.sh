#!/bin/bash

echo "🧹 CLEANING UP SCRIPT DIRECTORY FOR deploy-complete ONLY"
echo "========================================================"
echo ""
echo "This script will remove ALL unnecessary scripts and keep ONLY"
echo "the essential scripts needed for 'make deploy-complete' to work."
echo ""
echo "SCRIPTS TO KEEP (Essential for deploy-complete):"
echo "✅ script/deploy/DeployUnifiedSystem.s.sol"
echo "✅ script/deploy/DeployOnlyOracle.s.sol"
echo "✅ script/DeployRewardSystem.s.sol"
echo "✅ script/config/ConfigureChainlinkOracle.s.sol"
echo "✅ script/config/ConfigureVCOPPrice.s.sol"
echo "✅ script/test/TestChainlinkOracle.s.sol"
echo "✅ script/CheckOracleStatus.s.sol"
echo "✅ script/base/ (configuration files)"
echo "✅ script/generated/ (auto-generated addresses)"
echo "✅ script/utils/ (utility scripts)"
echo ""
echo "SCRIPTS TO DELETE (Not needed for deploy-complete):"
echo "❌ All liquidation test scripts"
echo "❌ All PSM scripts"
echo "❌ All VCOP loan scripts"
echo "❌ All experimental scripts"
echo "❌ All helper scripts except essential ones"
echo ""

read -p "Do you want to proceed with the cleanup? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Cleanup cancelled"
    exit 1
fi

echo ""
echo "🗂️  Creating backup of current script directory..."
cp -r script script_backup_$(date +%Y%m%d_%H%M%S)
echo "✅ Backup created"

echo ""
echo "🧹 Starting cleanup..."

# Create array of files to keep
declare -a KEEP_FILES=(
    # Deploy scripts (essential)
    "script/deploy/DeployUnifiedSystem.s.sol"
    "script/deploy/DeployOnlyOracle.s.sol"
    "script/DeployRewardSystem.s.sol"
    
    # Config scripts (essential)
    "script/config/ConfigureChainlinkOracle.s.sol"
    "script/config/ConfigureVCOPPrice.s.sol"
    
    # Test scripts (for verification only)
    "script/test/TestChainlinkOracle.s.sol"
    
    # Status/Check scripts (essential)
    "script/CheckOracleStatus.s.sol"
    
    # Keep essential directories (entire directories)
    "script/base/"
    "script/generated/"
    "script/utils/"
)

# Create array of files/directories to explicitly delete
declare -a DELETE_PATTERNS=(
    # Liquidation scripts
    "*Liquidation*"
    "*liquidation*"
    
    # PSM scripts
    "*PSM*"
    "*Psm*"
    "CustomPsmSwap*"
    "PsmSwap*"
    "PsmCheck*"
    
    # VCOP Loan scripts
    "TestVCOPLoans*"
    "TestVCOPLiquidation*"
    
    # Aggressive test scripts
    "AggressiveLiquidation*"
    "CreateHighInterest*"
    "CreateRealLiquidable*"
    "CreateTrulyRisky*"
    "DirectLiquidation*"
    "ForceLiquidation*"
    "ForceUpdate*"
    
    # Simple test scripts
    "SimpleToken*"
    "TestSimple*"
    "TestCore*"
    
    # Archive and experimental
    "archive/"
    "mocks/"
    "monitor/"
    "helpers/"
    "VCOPSwaping/"
    
    # Configuration scripts not needed
    "Configure*Assets*"
    "Configure*System*"
    "Configure*Vault*"
    "Finish*"
    "Fix*"
    "Set*"
    
    # Diagnostic scripts
    "Diagnostic*"
    "Check*NewOracle*"
    "Update*Oracle*"
    "Update*Permissions*"
    
    # Deploy scripts not needed
    "DeployCompleteSystem*"
    "DeployChainlinkOracle*"
    "DeployFullSystem*"
    "DeployLiquidation*"
    "DeployMainnet*"
    "DeployMock*"
    "DeployVCOP*"
    
    # Test scripts not essential
    "Test*Calculator*"
    "Test*VCOP*Oracle*"
    "Test*VCOP*Price*"
    "Check*VCOP*"
    
    # Miscellaneous
    "03_Swap*"
    "ProvideLiquidity*"
    "ReadPoolState*"
    "ReadVCOP*"
    "NewOracle*"
    "Custom*"
    "*.sh"
)

echo "🗑️  Deleting unnecessary scripts..."

# Delete files matching patterns
cd script || exit 1

for pattern in "${DELETE_PATTERNS[@]}"; do
    find . -name "$pattern" -type f -print0 | while IFS= read -r -d '' file; do
        if [[ -f "$file" ]]; then
            echo "❌ Deleting: $file"
            rm "$file"
        fi
    done
    
    find . -name "$pattern" -type d -print0 | while IFS= read -r -d '' dir; do
        if [[ -d "$dir" ]]; then
            echo "❌ Deleting directory: $dir"
            rm -rf "$dir"
        fi
    done
done

# Also delete specific files not covered by patterns
SPECIFIC_DELETE=(
    "CheckNewOracle.s.sol"
    "ConfigureAssetsForLiquidation.s.sol"
    "ConfigureAssetsForEasyLiquidation.s.sol"
    "DeployFullSystemFixedParidad.s.sol"
    "DeployMockUSDC.s.sol"
    "DeployVCOPBase.sol"
    "DeployVCOPCollateral.sol"
    "DeployVCOPCollateralHook.s.sol"
    "MainnetCommands.sh"
    "README.md"
    "config/EnableChainlinkOracle.s.sol"
)

for file in "${SPECIFIC_DELETE[@]}"; do
    if [[ -f "$file" ]]; then
        echo "❌ Deleting: $file"
        rm "$file"
    fi
done

cd ..

echo ""
echo "🧹 Cleaning up empty directories..."
find script -type d -empty -delete 2>/dev/null || true

echo ""
echo "✅ CLEANUP COMPLETED!"
echo "====================="
echo ""
echo "📁 REMAINING SCRIPTS:"
find script -name "*.sol" -type f | sort
echo ""
echo "📁 REMAINING DIRECTORIES:"
find script -type d | sort
echo ""
echo "🎯 VERIFICATION: Essential scripts for 'make deploy-complete':"
for file in "${KEEP_FILES[@]}"; do
    if [[ "$file" == */ ]]; then
        # Directory check
        if [[ -d "$file" ]]; then
            echo "✅ $file (directory exists)"
        else
            echo "❌ $file (directory missing)"
        fi
    else
        # File check
        if [[ -f "$file" ]]; then
            echo "✅ $file"
        else
            echo "❌ $file (MISSING - deploy-complete will fail!)"
        fi
    fi
done
echo ""
echo "🚀 Your script directory is now optimized for 'make deploy-complete' only!"
echo "💾 Backup saved as: script_backup_$(date +%Y%m%d_%H%M%S)/"
echo ""
echo "Next steps:"
echo "1. Run: make deploy-complete"
echo "2. Test the deployment"
echo "3. If you need other scripts later, restore from backup" 