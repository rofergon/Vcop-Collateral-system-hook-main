# 🛠️ Tools Directory

This directory contains all shell scripts and utility tools for the VCOP Collateral System.

## 📁 Script Organization

All shell scripts have been moved here from the root directory to maintain better organization and reduce clutter.

### 🔧 Core Deployment Tools
- `verify-core-contracts.sh` - Verify deployed core contracts on Base Sepolia
- `verify-contracts.sh` - Verify contracts on Base Mainnet
- `update-oracle-addresses.sh` - Update deployed-addresses.json with latest addresses
- `get-addresses.sh` - Extract and display contract addresses

### 🤖 Automation Tools
- `setup-chainlink-automation.sh` - Configure Chainlink automation environment
- `update-automation-addresses.sh` - Update addresses after automation deployment
- `update-automation-addresses-mock.sh` - Update mock automation addresses
- `update-env-forwarder.sh` - Update .env file with Chainlink Forwarder address
- `monitor-live-upkeep.sh` - Interactive monitoring tool for live Chainlink upkeeps

### 🧪 Testing Tools
- `test-automation.sh` - Complete automation flow test
- `test-automation-now.sh` - Local automation testing (no Chainlink required)
- `test-automation-complete.sh` - Complete automation test with mock oracle
- `runVCOPTest.sh` - Run VCOP system tests
- `runSimple.sh` - Run simplified tests

### 📊 Analysis & Monitoring
- `read-vcop-pool.sh` - Read current VCOP pool price information
- `extract-abis.sh` - Extract contract ABIs for integration

### 🧹 Maintenance
- `cleanup-makefile.sh` - Clean up Makefile configurations
- `cleanup-scripts.sh` - Comprehensive script cleanup tool
- `deployVCOP.sh` - Simple VCOP deployment script

## 🚀 Usage

All scripts should be run from the project root directory:

```bash
# From project root
./tools/script-name.sh
```

## 📝 Integration

These scripts are integrated with the main Makefile system:
- Referenced in `make/automation.mk`
- Used in various deployment and testing workflows
- Documentation updated in `CONTRACT_ABIS_GUIDE.md` and `README.md`

## ⚠️ Important Notes

- All scripts maintain their original functionality
- Path references have been updated throughout the project
- Scripts should be executable: `chmod +x tools/*.sh`
- Always run from project root directory for proper environment loading 