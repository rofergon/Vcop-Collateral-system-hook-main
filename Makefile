# 🚀 VCOP Collateral System - Enhanced Modular Makefile
# ======================================================
# Complete stack deployment with Chainlink automation

# Network configuration
RPC_URL := https://sepolia.base.org
MAINNET_RPC_URL := https://mainnet.base.org

# Load modules
include make/core.mk
include make/automation.mk
include make/testing.mk
include make/utils.mk
include make/avalanche.mk

.PHONY: help build clean

# ========================================
# 📚 HELP - Enhanced Commands
# ========================================

help:
	@echo ""
	@echo "VCOP COLLATERAL SYSTEM - Enhanced Commands"
	@echo "==========================================="
	@echo ""
	@echo "🎯 COMPLETE STACK DEPLOYMENT (RECOMMENDED)"
	@echo "deploy-full-stack             - Complete system + Chainlink automation"
	@echo "deploy-full-stack-mock        - Complete mock system + automation testing"
	@echo ""
	@echo "🏔️ AVALANCHE FUJI DEPLOYMENT"
	@echo "deploy-avalanche-full-stack-mock - ⭐ Complete system + AUTOMATIC tracking!"
	@echo "deploy-avalanche-complete-mock-high-gas - High gas version (if stuck)"
	@echo "deploy-avalanche-emergency-high-gas     - Emergency max gas version"
	@echo "check-avalanche-status           - Check Avalanche deployment status"
	@echo "check-avalanche-gas              - Check current gas prices"
	@echo "show-avalanche-info              - Show Avalanche network information"
	@echo ""
	@echo "🏔️ AVALANCHE TESTING"
	@echo "avalanche-quick-test             - ⭐ Complete test: mint tokens + create loan + crash market"
	@echo "mint-avalanche-test-tokens       - Mint test tokens (100 ETH, 500k USDC, 10 WBTC)"
	@echo "create-avalanche-test-loan       - Create test loan position (auto-mints tokens)"
	@echo "crash-avalanche-market           - Crash market prices by 50% (trigger liquidation)"
	@echo "increase-avalanche-market        - Increase market prices by 50% (reset test)"
	@echo "liquidate-avalanche-position     - Manually liquidate position"
	@echo "check-avalanche-balances         - Check your token balances"
	@echo "test-avalanche-automation        - Test automation with MockOracle"
	@echo "monitor-avalanche-automation     - Show automation dashboard links"
	@echo "generate-avalanche-checkdata     - Generate checkData for Chainlink registration"
	@echo "help-avalanche-testing           - Show detailed Avalanche testing help"
	@echo ""
	@echo "🚀 CORE SYSTEM DEPLOYMENT"
	@echo "deploy-complete               - Core system with real Oracle"
	@echo "deploy-complete-mock          - Core system with MockOracle for testing"
	@echo ""
	@echo "🤖 CHAINLINK AUTOMATION"
	@echo "deploy-automation-complete    - Complete Chainlink automation setup"
	@echo "deploy-automation             - Deploy automation contracts only"
	@echo "register-chainlink-upkeep     - Register with official Chainlink"
	@echo "configure-forwarder           - Configure Forwarder security"
	@echo ""
	@echo "🔧 TROUBLESHOOTING & FIXES"
	@echo "fix-vault-liquidity           - Fix 'ERC20InsufficientAllowance' error"
	@echo "fix-vault-allowances          - Fix vault allowances for automation (NEW)"
	@echo "configure-vault-automation    - Configure vault-funded liquidation"
	@echo ""
	@echo "🧪 TESTING & VERIFICATION"
	@echo "test-automation-flow          - Complete automation test flow"
	@echo "create-test-loan              - Create test loan position"
	@echo "liquidate-position            - Liquidate test position"
	@echo "crash-market                  - Crash market prices by 50% (NEW)"
	@echo "increase-market               - Increase market prices by 50% (NEW)"
	@echo ""
	@echo "🔍 STATUS & MONITORING"
	@echo "check-status                  - Check all deployment status"
	@echo "check-chainlink-status        - Check Chainlink upkeep status"
	@echo "check-addresses               - Show all contract addresses"
	@echo "test-oracle                   - Test Oracle functionality"
	@echo ""
	@echo "✅ CONTRACT VERIFICATION"
	@echo "verify-all-contracts-fixed    - ⭐ RECOMMENDED: Verify with correct constructor args"
	@echo "verify-contracts-sepolia-fixed - ⭐ RECOMMENDED: Verify on Base Sepolia (fixed)"
	@echo "verify-contracts-mainnet-fixed - ⭐ RECOMMENDED: Verify on Base Mainnet (fixed)"
	@echo "verify-all-contracts          - Basic verification (may fail on some contracts)"
	@echo "verify-contracts-sepolia      - Basic verification on Base Sepolia"
	@echo "verify-contracts-mainnet      - Basic verification on Base Mainnet"
	@echo "verify-contracts-custom       - Verify with JSON_FILE=path/to/file.json"
	@echo "show-deployed-addresses       - Show all deployed contract addresses"
	@echo "show-addresses-custom         - Show addresses with JSON_FILE=path/to/file.json"
	@echo ""
	@echo "🛠️ UTILITIES"
	@echo "build                         - Smart compilation"
	@echo "clean                         - Clean build artifacts"
	@echo "check-gas                     - Check gas prices"
	@echo ""
	@echo "📋 For detailed help: make help-[module]"
	@echo "   help-core         - Core deployment commands"
	@echo "   help-automation   - Automation commands"
	@echo "   help-testing      - Testing commands"
	@echo "   help-utils        - Utility commands"
	@echo "   help-avalanche    - Avalanche Fuji commands"
	@echo ""
	@echo "🌟 QUICK START GUIDES:"
	@echo "   Base Sepolia:    make deploy-full-stack-mock"
	@echo "   Avalanche Fuji:  make deploy-avalanche-full-stack-mock"
	@echo "   Verification:    make verify-all-contracts-fixed"
	@echo "   Test Avalanche:  make avalanche-quick-test"
	@echo ""
	@echo "❗ TROUBLESHOOTING:"
	@echo "   If upkeeps execute but positions don't liquidate:"
	@echo "   → make fix-vault-allowances (recommended)"
	@echo "   → make fix-vault-liquidity (alternative)"
	@echo "   If contract verification fails:"
	@echo "   → Use verify-all-contracts-fixed instead of verify-all-contracts"
	@echo "   If Avalanche deployment gets stuck with low gas:"
	@echo "   → Cancel (Ctrl+C) and try: make deploy-avalanche-complete-mock-high-gas"
	@echo "   → For emergency: make deploy-avalanche-emergency-high-gas"
	@echo "   If test-automation-flow fails:"
	@echo "   → Use avalanche-quick-test for Avalanche Fuji"
	@echo "   → Use test-automation-flow for Base Sepolia only"

# ========================================
# 🔨 BASIC BUILD COMMANDS
# ========================================

build:
	@echo "🔨 Smart compilation..."
	@forge build

clean:
	@echo "🧹 Cleaning build artifacts..."
	@forge clean

# ========================================
# 🚀 MAIN DEPLOYMENT SHORTCUTS
# ========================================

# Main deployment with real oracle + automation
deploy: deploy-full-stack

# Test deployment with mock oracle + automation
deploy-test: deploy-full-stack-mock

# Quick status check
status: check-status

# Quick test
test: test-automation-flow

# Crash market prices
crash-market:
	@echo "💥 Crashing market prices..."
	@eval $$(cat .env) && forge script script/test/CrashMarket.s.sol:CrashMarket \
		--rpc-url $$RPC_URL \
		--private-key $$PRIVATE_KEY \
		--broadcast \
		-vvv

# Increase market prices
increase-market:
	@echo "📈 Increasing market prices..."
	@eval $$(cat .env) && forge script script/test/IncreaseMarket.s.sol:IncreaseMarket \
		--rpc-url $$RPC_URL \
		--private-key $$PRIVATE_KEY \
		--broadcast \
		-vvv

# ========================================
# 🔍 VERIFICATION COMMANDS
# ========================================

# Verify all contracts dynamically from deployed-addresses-mock.json
verify-all-contracts:
	@echo "🔍 Verificando todos los contratos de forma dinámica..."
	@chmod +x tools/verify-all-contracts.sh
	@./tools/verify-all-contracts.sh

# Verify all contracts with improved constructor arguments (RECOMMENDED)
verify-all-contracts-fixed:
	@echo "🔍 Verificando todos los contratos con argumentos mejorados..."
	@chmod +x tools/verify-all-contracts-fixed.sh
	@./tools/verify-all-contracts-fixed.sh

# Verify contracts for Base Sepolia (testnet)
verify-contracts-sepolia:
	@echo "🔍 Verificando contratos en Base Sepolia..."
	@CHAIN_ID=84532 ./tools/verify-all-contracts.sh

# Verify contracts for Base Sepolia with fixed constructor args (RECOMMENDED)
verify-contracts-sepolia-fixed:
	@echo "🔍 Verificando contratos en Base Sepolia (versión mejorada)..."
	@CHAIN_ID=84532 ./tools/verify-all-contracts-fixed.sh

# Verify contracts for Base Mainnet
verify-contracts-mainnet:
	@echo "🔍 Verificando contratos en Base Mainnet..."
	@CHAIN_ID=8453 ./tools/verify-all-contracts.sh

# Verify contracts for Base Mainnet with fixed constructor args (RECOMMENDED)
verify-contracts-mainnet-fixed:
	@echo "🔍 Verificando contratos en Base Mainnet (versión mejorada)..."
	@CHAIN_ID=8453 ./tools/verify-all-contracts-fixed.sh

# Verify with custom JSON file
verify-contracts-custom:
	@echo "🔍 Verificando contratos desde archivo personalizado..."
	@if [ -z "$(JSON_FILE)" ]; then \
		echo "❌ Error: Especifica JSON_FILE=path/to/file.json"; \
		exit 1; \
	fi
	@JSON_FILE=$(JSON_FILE) ./tools/verify-all-contracts.sh

# Show all deployed addresses from JSON
show-deployed-addresses:
	@echo "📋 Mostrando todas las direcciones desplegadas..."
	@chmod +x tools/show-deployed-addresses.sh
	@./tools/show-deployed-addresses.sh

# Show addresses from custom JSON file
show-addresses-custom:
	@echo "📋 Mostrando direcciones desde archivo personalizado..."
	@if [ -z "$(JSON_FILE)" ]; then \
		echo "❌ Error: Especifica JSON_FILE=path/to/file.json"; \
		exit 1; \
	fi
	@JSON_FILE=$(JSON_FILE) ./tools/show-deployed-addresses.sh

# Generate checkData for Avalanche Chainlink registration
generate-avalanche-checkdata:
	@echo "🔗 Generating checkData for Avalanche Fuji Chainlink registration..."
	@forge script script/automation/GenerateAvalancheCheckData.s.sol:GenerateAvalancheCheckData \
		--rpc-url https://api.avax-test.network/ext/bc/C/rpc \
		-vvv