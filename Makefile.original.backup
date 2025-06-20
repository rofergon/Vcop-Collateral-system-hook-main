# 🚀 VCOP Collateral System - Clean Modular Makefile
# =====================================================
# Essential commands only - modules loaded from make/

# Network configuration
RPC_URL := https://sepolia.base.org
MAINNET_RPC_URL := https://mainnet.base.org

# Load modules
include make/core.mk
include make/automation.mk
include make/testing.mk
include make/utils.mk

.PHONY: help build clean

# ========================================
# 📚 HELP - Essential Commands Only
# ========================================

help:
	@echo ""
	@echo "VCOP COLLATERAL SYSTEM - Essential Commands"
	@echo "============================================"
	@echo ""
	@echo "🚀 MAIN DEPLOYMENT"
	@echo "make deploy-complete          - Complete deployment (recommended)"
	@echo "make deploy-complete-mock     - Deploy with MockOracle for testing"
	@echo "make deploy-automation        - Deploy Chainlink Automation"
	@echo "make deploy-automation-mock   - Deploy automation for mock system"
	@echo ""
	@echo "🧪 TESTING"
	@echo "make test-automation-flow     - Complete automation test flow"
	@echo "make create-test-loan         - Create test loan position"
	@echo "make liquidate-position       - Liquidate test position"
	@echo ""
	@echo "🔍 STATUS & VERIFICATION"
	@echo "make check-status             - Check deployment status"
	@echo "make check-addresses          - Show all contract addresses"
	@echo "make test-oracle              - Test Oracle functionality"
	@echo ""
	@echo "🛠️ UTILITIES"
	@echo "make build                    - Smart compilation"
	@echo "make clean                    - Clean build artifacts"
	@echo "make check-gas                - Check gas prices"
	@echo ""
	@echo "📋 For detailed help: make help-[module]"
	@echo "   help-core     - Core deployment commands"
	@echo "   help-automation - Automation commands"
	@echo "   help-testing  - Testing commands"
	@echo "   help-utils    - Utility commands"

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

# Main deployment with real oracle
deploy: deploy-complete

# Test deployment with mock oracle
deploy-test: deploy-complete-mock

# Quick status check
status: check-status

# Quick test
test: test-automation-flow