# 🧹 Script Directory - Clean Version (deploy-complete only)

This directory has been cleaned up to contain **ONLY** the essential scripts needed for `make deploy-complete`.

## 📁 Structure

```
script/
├── base/                           # Base configuration files
│   ├── Config.sol                  # Basic configuration
│   ├── Constants.sol               # System constants
│   ├── PoolManagerAddresses.sol    # Pool manager addresses
│   └── PositionManagerAddresses.sol # Position manager addresses
├── config/                         # Configuration scripts
│   ├── ConfigureChainlinkOracle.s.sol # Configure Chainlink Oracle
│   └── ConfigureVCOPPrice.s.sol       # Configure VCOP price
├── deploy/                         # Deployment scripts
│   ├── DeployOnlyOracle.s.sol         # Deploy standalone Oracle
│   └── DeployUnifiedSystem.s.sol      # Deploy complete unified system
├── generated/                      # Auto-generated addresses (empty until deployment)
├── test/                          # Essential test scripts
│   └── TestChainlinkOracle.s.sol     # Test Chainlink Oracle functionality
├── utils/                         # Utility scripts
│   └── UpdateDeployedAddresses.s.sol # Update deployment addresses
├── CheckOracleStatus.s.sol        # Check Oracle status and health
└── DeployRewardSystem.s.sol       # Deploy reward system
```

## 🚀 Essential Scripts for `make deploy-complete`

### Deploy Phase
1. **DeployUnifiedSystem.s.sol** - Main deployment script (Core + VCOP)
2. **DeployRewardSystem.s.sol** - Deploy and configure reward system  
3. **DeployOnlyOracle.s.sol** - Deploy Chainlink Oracle

### Configuration Phase
4. **ConfigureChainlinkOracle.s.sol** - Configure Oracle with Chainlink feeds
5. **ConfigureVCOPPrice.s.sol** - Configure VCOP price fallback

### Verification Phase
6. **TestChainlinkOracle.s.sol** - Test Oracle functionality
7. **CheckOracleStatus.s.sol** - Health check for Oracle

### Support Files
- **base/** - Configuration constants and addresses
- **utils/** - Address update utilities
- **generated/** - Auto-generated deployment addresses (created during deployment)

## ✅ What was removed

- ❌ All liquidation test scripts (40+ files)
- ❌ All PSM scripts (10+ files)  
- ❌ All VCOP loan test scripts (15+ files)
- ❌ All experimental scripts (20+ files)
- ❌ All helper/diagnostic scripts (30+ files)
- ❌ Archive and development folders

## 💾 Backup

A complete backup of all removed scripts was saved to:
`script_backup_YYYYMMDD_HHMMSS/`

## 🎯 Usage

```bash
# Deploy complete system
make deploy-complete

# Deploy optimized version  
make deploy-complete-optimized

# Test the deployed system
make test-chainlink-oracle
```

## 🔄 Restore Scripts (if needed)

If you need any of the removed scripts later:

```bash
# Find your backup
ls -la script_backup_*/

# Restore specific script
cp script_backup_*/SomeScript.s.sol script/

# Restore entire backup
mv script/ script_clean/
mv script_backup_*/ script/
```

---

**Total scripts before cleanup:** 80+ files  
**Total scripts after cleanup:** 12 files  
**Space saved:** ~2MB  
**Functionality:** 100% compatible with `make deploy-complete` 