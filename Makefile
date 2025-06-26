# 🚀 VCOP Collateral System - Production Makefile
# ======================================================
# Streamlined version with essential commands only

# Network configuration
RPC_URL := https://sepolia.base.org
MAINNET_RPC_URL := https://mainnet.base.org

.PHONY: help build clean deploy status test

# ========================================
# 📚 HELP - Essential Commands
# ========================================

help:
	@echo ""
	@echo "VCOP COLLATERAL SYSTEM - Essential Commands"
	@echo "==========================================="
	@echo ""
	@echo "🚀 DEPLOYMENT"
	@echo "deploy-full-stack        - Complete system + Chainlink automation"
	@echo "deploy-core-only         - Core system only (no automation)"
	@echo ""
	@echo "🧪 TESTING"
	@echo "create-test-loan         - Create test loan position"
	@echo "crash-market             - Crash market prices to trigger liquidation"
	@echo "increase-market          - Restore market prices to normal"
	@echo "check-upkeep             - Check your Chainlink upkeep status"
	@echo ""
	@echo "🔍 MONITORING"
	@echo "status                   - Check deployment status"
	@echo "check-chainlink          - Check Chainlink automation status"
	@echo "show-addresses           - Show all contract addresses"
	@echo ""
	@echo "✅ VERIFICATION"
	@echo "verify-contracts         - Verify contracts on Base Sepolia"
	@echo ""
	@echo "🛠️ UTILITIES"
	@echo "build                    - Compile contracts"
	@echo "clean                    - Clean build artifacts"
	@echo ""
	@echo "🌟 QUICK START:"
	@echo "   make deploy-full-stack   (for complete deployment)"
	@echo "   make create-test-loan    (create test position)"
	@echo "   make crash-market        (trigger automation)"
	@echo "   make check-upkeep        (verify automation worked)"

# ========================================
# 🔨 BASIC COMMANDS
# ========================================

build:
	@echo "🔨 Compiling contracts..."
	@forge build

clean:
	@echo "🧹 Cleaning build artifacts..."
	@forge clean

# ========================================
# 🚀 DEPLOYMENT COMMANDS
# ========================================

# Complete deployment with automation
deploy-full-stack:
	@echo "🚀 DEPLOYING COMPLETE VCOP STACK"
	@echo "================================"
	@echo "This will deploy:"
	@echo "1. Core VCOP lending system with Mock Oracle"
	@echo "2. Chainlink Automation contracts"
	@echo "3. Configure vault-funded liquidation"
	@echo ""
	@read -p "Continue? (y/N): " confirm && [ "$$confirm" = "y" ] || exit 1
	@echo ""
	@echo "📦 Building contracts..."
	@forge build
	@echo ""
	@echo "🚀 Step 1: Deploying core system..."
	@forge script script/deploy/DeployUnifiedSystemMock.s.sol:DeployUnifiedSystemMock \
		--rpc-url $(RPC_URL) --broadcast --legacy --gas-price 2000000000 --slow
	@echo ""
	@echo "🔧 Step 2: Configuring Mock Oracle..."
	@. ./.env && forge script script/config/ConfigureMockOracle.s.sol:ConfigureMockOracle \
		--rpc-url $$RPC_URL --private-key $$PRIVATE_KEY --broadcast --legacy --gas-price 2000000000 --slow
	@echo ""
	@echo "🔗 Step 3: Configuring Asset Handlers..."
	@. ./.env && forge script script/test/ConfigureAssetHandlers.s.sol:ConfigureAssetHandlers \
		--rpc-url $$RPC_URL --private-key $$PRIVATE_KEY --broadcast --legacy --gas-price 2000000000 --slow
	@echo ""
	@echo "🤖 Step 4: Deploying Automation..."
	@. ./.env && \
	export ORACLE_ADDRESS=$$(jq -r '.vcopCollateral.mockVcopOracle' deployed-addresses-mock.json) && \
	export FLEXIBLE_LOAN_MANAGER_ADDRESS=$$(jq -r '.coreLending.flexibleLoanManager' deployed-addresses-mock.json) && \
	export PRICE_REGISTRY_ADDRESS=$$(jq -r '.coreLending.dynamicPriceRegistry' deployed-addresses-mock.json) && \
	forge script script/automation/DeployAutomationMock.s.sol:DeployAutomationMock \
		--rpc-url $$RPC_URL --private-key $$PRIVATE_KEY --broadcast --legacy --gas-price 2000000000 --slow
	@echo ""
	@echo "💰 Step 5: Adding vault liquidity..."
	@. ./.env && forge script script/automation/AddVaultLiquidity.s.sol:AddVaultLiquidity \
		--rpc-url $$RPC_URL --private-key $$PRIVATE_KEY --broadcast --legacy --gas-price 2000000000 --slow
	@echo ""
	@echo "🔧 Step 6: Configuring vault automation..."
	@. ./.env && forge script script/automation/AuthorizeKeeperInVault.s.sol:AuthorizeKeeperInVault \
		--rpc-url $$RPC_URL --private-key $$PRIVATE_KEY --broadcast --legacy --gas-price 2000000000 --slow
	@echo ""
	@echo "✅ Step 7: Updating addresses..."
	@chmod +x tools/update-automation-addresses-mock.sh && ./tools/update-automation-addresses-mock.sh
	@echo ""
	@echo "🎉 DEPLOYMENT COMPLETE!"
	@echo "======================="
	@echo "✅ System ready for automation testing"
	@echo "📋 Your Chainlink Automation contract: $$(jq -r '.automation.automationKeeper' deployed-addresses-mock.json)"
	@echo ""
	@echo "🎯 NEXT STEPS:"
	@echo "1. Register your automation contract at: https://automation.chain.link/"
	@echo "2. Test with: make create-test-loan && make crash-market"
	@echo "3. Verify contracts: make verify-contracts"

# Core system only (no automation)
deploy-core-only:
	@echo "🚀 DEPLOYING CORE SYSTEM ONLY"
	@echo "============================="
	@forge build
	@forge script script/deploy/DeployUnifiedSystemMock.s.sol:DeployUnifiedSystemMock \
		--rpc-url $(RPC_URL) --broadcast --legacy --gas-price 2000000000 --slow
	@. ./.env && forge script script/config/ConfigureMockOracle.s.sol:ConfigureMockOracle \
		--rpc-url $$RPC_URL --private-key $$PRIVATE_KEY --broadcast --legacy --gas-price 2000000000 --slow
	@echo "✅ Core system deployed!"

# ========================================
# 🧪 TESTING COMMANDS
# ========================================

# Create test loan position
create-test-loan:
	@echo "🧪 CREATING TEST LOAN POSITION"
	@echo "============================="
	@if [ ! -f "deployed-addresses-mock.json" ]; then \
		echo "❌ System not deployed! Run: make deploy-full-stack"; \
		exit 1; \
	fi
	@. ./.env && \
	export LOAN_MANAGER_ADDRESS=$$(jq -r '.coreLending.flexibleLoanManager' deployed-addresses-mock.json) && \
	export COLLATERAL_TOKEN_ADDRESS=$$(jq -r '.tokens.mockETH' deployed-addresses-mock.json) && \
	export LOAN_TOKEN_ADDRESS=$$(jq -r '.tokens.mockUSDC' deployed-addresses-mock.json) && \
	forge script script/test/CreateTestLoanPosition.s.sol \
		--rpc-url $(RPC_URL) --private-key $$PRIVATE_KEY --broadcast --gas-price 2000000000
	@echo "✅ Test position created!"

# Crash market prices to trigger automation
crash-market:
	@echo "💥 CRASHING MARKET PRICES"
	@echo "========================"
	@if [ ! -f "deployed-addresses-mock.json" ]; then \
		echo "❌ System not deployed! Run: make deploy-full-stack"; \
		exit 1; \
	fi
	@. ./.env && forge script script/test/CrashMarket.s.sol:CrashMarket \
		--rpc-url $$RPC_URL --private-key $$PRIVATE_KEY --broadcast --gas-price 2000000000
	@echo "✅ Market crashed! Your automation should trigger in 1-2 minutes."

# Restore market prices to normal
increase-market:
	@echo "📈 RESTORING MARKET PRICES"
	@echo "========================="
	@. ./.env && forge script script/test/IncreaseMarket.s.sol:IncreaseMarket \
		--rpc-url $$RPC_URL --private-key $$PRIVATE_KEY --broadcast --gas-price 2000000000
	@echo "✅ Market prices restored!"

# Check your Chainlink upkeep status
check-upkeep:
	@echo "🔍 CHECKING YOUR CHAINLINK UPKEEP"
	@echo "================================="
	@if [ ! -f "deployed-addresses-mock.json" ]; then \
		echo "❌ System not deployed! Run: make deploy-full-stack"; \
		exit 1; \
	fi
	@forge script script/test/CheckYourUpkeep.s.sol:CheckYourUpkeep --rpc-url $(RPC_URL) -vvv

# ========================================
# 🔍 MONITORING COMMANDS
# ========================================

# Check deployment status
status:
	@echo "🔍 CHECKING DEPLOYMENT STATUS"
	@echo "============================="
	@if [ ! -f "deployed-addresses-mock.json" ]; then \
		echo "❌ deployed-addresses-mock.json not found"; \
		echo "   Run: make deploy-full-stack"; \
		exit 1; \
	fi
	@echo "✅ deployed-addresses-mock.json found"
	@echo "📋 Key contracts:"
	@echo "  FlexibleLoanManager: $$(jq -r '.coreLending.flexibleLoanManager' deployed-addresses-mock.json)"
	@echo "  AutomationKeeper: $$(jq -r '.automation.automationKeeper' deployed-addresses-mock.json)"
	@echo "  Mock Oracle: $$(jq -r '.vcopCollateral.mockVcopOracle' deployed-addresses-mock.json)"
	@echo "  VaultBasedHandler: $$(jq -r '.coreLending.vaultBasedHandler' deployed-addresses-mock.json)"

# Check Chainlink automation status
check-chainlink:
	@echo "🔗 CHAINLINK AUTOMATION STATUS"
	@echo "==============================="
	@echo "🌐 Official Chainlink Dashboard:"
	@echo "   https://automation.chain.link/"
	@echo "   (Select Base Sepolia network)"
	@echo ""
	@echo "💰 Get LINK tokens:"
	@echo "   https://faucets.chain.link/"

# Show all contract addresses
show-addresses:
	@echo "📋 CONTRACT ADDRESSES"
	@echo "===================="
	@if [ ! -f "deployed-addresses-mock.json" ]; then \
		echo "❌ No deployment found"; \
		exit 1; \
	fi
	@cat deployed-addresses-mock.json | jq .

# ========================================
# ✅ VERIFICATION COMMANDS
# ========================================

# Verify contracts on Base Sepolia
verify-contracts:
	@echo "🔍 VERIFYING CONTRACTS ON BASE SEPOLIA"
	@echo "======================================"
	@if [ ! -f "tools/verify-all-contracts-fixed.sh" ]; then \
		echo "❌ Verification script not found"; \
		exit 1; \
	fi
	@chmod +x tools/verify-all-contracts-fixed.sh
	@CHAIN_ID=84532 ./tools/verify-all-contracts-fixed.sh
	@echo "✅ Contract verification completed!"

# ========================================
# 🎯 SHORTCUTS FOR COMMON WORKFLOWS
# ========================================

# Quick deployment alias
deploy: deploy-full-stack

# Quick test flow
test: create-test-loan crash-market check-upkeep

# Quick status check
check: status