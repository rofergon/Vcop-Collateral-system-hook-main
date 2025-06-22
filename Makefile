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
	@echo "configure-vault-automation    - Configure vault-funded liquidation"
	@echo ""
	@echo "🧪 TESTING & VERIFICATION"
	@echo "test-automation-flow          - Complete automation test flow"
	@echo "create-test-loan              - Create test loan position"
	@echo "liquidate-position            - Liquidate test position"
	@echo ""
	@echo "🔍 STATUS & MONITORING"
	@echo "check-status                  - Check all deployment status"
	@echo "check-chainlink-status        - Check Chainlink upkeep status"
	@echo "check-addresses               - Show all contract addresses"
	@echo "test-oracle                   - Test Oracle functionality"
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
	@echo ""
	@echo "🌟 QUICK START GUIDES:"
	@echo "   Production:  make deploy-full-stack"
	@echo "   Testing:     make deploy-full-stack-mock"
	@echo ""
	@echo "❗ TROUBLESHOOTING:"
	@echo "   If upkeeps execute but positions don't liquidate:"
	@echo "   → make fix-vault-liquidity"

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