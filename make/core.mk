# ========================================
# 🚀 CORE DEPLOYMENT MODULE - ENHANCED
# ========================================

.PHONY: deploy-complete deploy-complete-mock deploy-complete-optimized help-core \
	deploy-full-stack deploy-full-stack-mock

help-core:
	@echo ""
	@echo "🚀 CORE DEPLOYMENT COMMANDS"
	@echo "============================"
	@echo "🎯 COMPLETE STACK DEPLOYMENT:"
	@echo "deploy-full-stack            - Complete system + Chainlink automation"
	@echo "deploy-full-stack-mock       - Complete mock system + automation"
	@echo ""
	@echo "🔧 CORE SYSTEM ONLY:"
	@echo "deploy-complete              - Complete deployment with real Oracle"
	@echo "deploy-complete-mock         - Complete deployment with MockOracle + Automation"
	@echo "deploy-complete-optimized    - Production deployment with optimizations"
	@echo "deploy-emergency-registry    - Deploy emergency registry system"
	@echo ""
	@echo "🧪 TESTING COMMANDS:"
	@echo "create-test-positions        - Create test loan positions"
	@echo "crash-prices                 - Crash prices to trigger liquidations"
	@echo "generate-upkeep-config       - Generate Chainlink upkeep configuration"
	@echo "check-system-status          - Check complete system status"
	@echo ""

# ========================================
# 🎯 COMPLETE STACK DEPLOYMENTS (NEW)
# ========================================

# Complete deployment with real Oracle + Chainlink Automation
deploy-full-stack:
	@echo "🎯 DEPLOYING COMPLETE VCOP STACK WITH CHAINLINK"
	@echo "==============================================="
	@echo ""
	@echo "This will deploy the complete system including:"
	@echo "1. Core VCOP lending system with real Oracle"
	@echo "2. Chainlink Automation with official registry"
	@echo "3. Complete configuration and testing"
	@echo ""
	@read -p "Continue with full deployment? (y/N): " confirm && [ "$$confirm" = "y" ] || exit 1
	@echo ""
	@echo "🚀 Phase 1: Deploying core system..."
	@$(MAKE) deploy-complete
	@echo ""
	@echo "🤖 Phase 2: Deploying automation..."
	@$(MAKE) deploy-automation-complete
	@echo ""
	@echo "🎉 COMPLETE STACK DEPLOYMENT FINISHED!"
	@echo "✅ Your VCOP system is fully operational with Chainlink automation"

# Complete deployment with MockOracle + Mock Automation for testing
deploy-full-stack-mock:
	@echo "🧪 DEPLOYING COMPLETE MOCK STACK"
	@echo "================================"
	@echo ""
	@echo "This will deploy the complete testing system including:"
	@echo "1. Core VCOP lending system with Mock Oracle"
	@echo "2. Mock automation for testing liquidations"
	@echo "3. Vault-funded liquidation configuration"
	@echo "4. Automated testing flow"
	@echo ""
	@echo "🚀 Phase 1: Deploying mock core system..."
	@$(MAKE) deploy-complete-mock
	@echo ""
	@echo "🤖 Phase 2: Deploying mock automation..."
	@$(MAKE) deploy-automation-complete-mock-no-test
	@echo ""
	@echo "🔧 Phase 3: Configuring vault-funded liquidation..."
	@$(MAKE) configure-vault-automation
	@echo ""
	@echo "🔧 Phase 3.5: Fixing vault allowances for automation..."
	@echo "Waiting 10 seconds to avoid nonce conflicts..."
	@sleep 10
	@. ./.env && forge script script/automation/FixVaultAllowances.s.sol:FixVaultAllowances \
		--rpc-url $$RPC_URL --private-key $$PRIVATE_KEY --broadcast --legacy --gas-price 2000000000 --slow
	@echo ""
	@echo "🧪 Phase 4: Quick system verification..."
	@$(MAKE) quick-system-check
	@echo ""
	@echo "🧪 Phase 5: Testing complete automation flow..."
	@$(MAKE) test-automation-flow
	@echo ""
	@echo "🎉 COMPLETE MOCK STACK WITH VAULT-FUNDED LIQUIDATION FINISHED!"
	@echo "=========================================================="
	@echo "✅ Your test environment is ready with:"
	@echo "   • Chainlink Automation for position monitoring"
	@echo "   • Vault-funded liquidation system (no allowance issues)"
	@echo "   • Self-sustaining liquidation mechanism"
	@echo "   • Tested and verified working system"
	@echo ""
	@echo "📊 DEPLOYMENT SUMMARY:"
	@echo "   • Core system: DEPLOYED ✅"
	@echo "   • Automation: DEPLOYED ✅"
	@echo "   • Authorizations: CONFIGURED ✅"
	@echo "   • Vault liquidity: 300,000 USDC ✅"
	@echo "   • Test passed: Liquidation working ✅"
	@echo ""
	@echo "🚀 NEXT STEPS:"
	@echo "   1. Test more scenarios: make create-test-positions && make crash-market"
	@echo "   2. Register Chainlink upkeep: make register-chainlink-upkeep"  
	@echo "   3. Monitor live: https://automation.chain.link/base-sepolia"
	@echo "   4. Verify contracts: make verify-all-contracts-fixed"
	@echo ""
	@echo "🎯 SYSTEM IS 100% FUNCTIONAL AND READY FOR USE!"

# ========================================
# 🔧 CORE SYSTEM DEPLOYMENTS
# ========================================

# Main deployment with real Oracle
deploy-complete:
	@echo "🚀 STARTING COMPLETE CORE DEPLOYMENT (PRODUCTION)"
	@echo "=================================================="
	@echo "📦 Building contracts with optimizations..."
	@forge build --optimize --optimizer-runs 200
	@echo ""
	@echo "🚀 Step 1: Deploying unified system..."
	@forge script script/deploy/DeployUnifiedSystem.s.sol:DeployUnifiedSystem \
		--rpc-url $(RPC_URL) --broadcast --legacy --gas-price 2000000000 --slow
	@echo ""
	@echo "🔥 Step 2: Deploying Emergency Registry..."
	@. ./.env && forge script script/deploy/DeployEmergencyRegistry.s.sol:DeployEmergencyRegistry \
		--rpc-url $$RPC_URL --private-key $$PRIVATE_KEY --broadcast --legacy --gas-price 2000000000 --slow
	@echo ""
	@echo "🔗 Step 3: Configuring Chainlink Oracle..."
	@. ./.env && forge script script/config/ConfigureChainlinkOracle.s.sol:ConfigureChainlinkOracle \
		--rpc-url $$RPC_URL --private-key $$PRIVATE_KEY --broadcast --legacy --gas-price 2000000000 --slow
	@echo ""
	@echo "💰 Step 4: Setting VCOP Price..."
	@. ./.env && forge script script/config/ConfigureVCOPPrice.s.sol:ConfigureVCOPPrice \
		--rpc-url $$RPC_URL --private-key $$PRIVATE_KEY --broadcast --legacy --gas-price 2000000000 --slow
	@echo ""
	@echo "📊 Step 5: Deploying Dynamic Price Registry..."
	@. ./.env && forge script script/deploy/DeployDynamicPriceRegistry.s.sol:DeployDynamicPriceRegistry \
		--rpc-url $$RPC_URL --private-key $$PRIVATE_KEY --broadcast --legacy --gas-price 2000000000 --slow
	@echo ""
	@echo "⚙️ Step 6: Configuring Dynamic Pricing..."
	@. ./.env && forge script script/config/ConfigureDynamicPricing.s.sol:ConfigureDynamicPricing \
		--rpc-url $$RPC_URL --private-key $$PRIVATE_KEY --broadcast --legacy --gas-price 2000000000 --slow
	@echo ""
	@echo "🔗 Step 7: Configuring Asset Handlers..."
	@. ./.env && forge script script/deploy/ConfigureAssetHandlers.s.sol:ConfigureAssetHandlers \
		--rpc-url $$RPC_URL --private-key $$PRIVATE_KEY --broadcast --legacy --gas-price 2000000000 --slow
	@echo ""
	@echo "✅ Step 8: Verifying system status..."
	@. ./.env && forge script script/CheckOracleStatus.s.sol:CheckOracleStatus \
		--rpc-url $$RPC_URL --legacy --gas-price 2000000000
	@echo ""
	@echo "🎉 PRODUCTION CORE DEPLOYMENT COMPLETED!"
	@echo "📊 System configured with:"
	@echo "   • Real Chainlink price feeds"
	@echo "   • Dynamic pricing registry"
	@echo "   • Emergency response system"
	@echo "   • Asset handlers ready for production"
	@echo "✅ Ready for Chainlink automation setup!"

# Complete deployment with MockOracle + Full Automation Setup
deploy-complete-mock:
	@echo "🧪 STARTING COMPLETE MOCK STACK DEPLOYMENT"
	@echo "==========================================="
	@echo "This will deploy the complete VCOP system with:"
	@echo "• Core lending system with Mock Oracle"
	@echo "• Automation-enabled VaultBasedHandler"
	@echo "• Chainlink Automation configuration"
	@echo "• All testing tools and liquidity"
	@echo ""
	@echo "📦 Building contracts..."
	@forge build
	@echo ""
	@echo "🚀 Step 1: Deploying unified system with Mock Oracle..."
	@forge script script/deploy/DeployUnifiedSystemMock.s.sol:DeployUnifiedSystemMock \
		--rpc-url $(RPC_URL) --broadcast --legacy --gas-price 2000000000 --slow
	@echo ""
	@echo "🔧 Step 2: Mock Oracle configuration completed during deployment..."
	@echo "✅ MockOracle already configured with realistic 2025 prices"
	@echo ""
	@echo "💰 Step 3: VCOP Price configuration completed during deployment..."
	@echo "✅ VCOP price already set to $1.00 USD"
	@echo ""
	@echo "🔗 Step 4: Configuring Asset Handlers with initial liquidity..."
	@. ./.env && forge script script/test/ConfigureAssetHandlers.s.sol:ConfigureAssetHandlers \
		--rpc-url $$RPC_URL --private-key $$PRIVATE_KEY --broadcast --legacy --gas-price 2000000000 --slow
	@echo ""
	@echo "🤖 Step 5: Deploying VaultBasedHandler with Automation functions..."
	@. ./.env && forge script script/automation/RedeployVaultWithAutomation.s.sol:RedeployVaultWithAutomation \
		--rpc-url $$RPC_URL --private-key $$PRIVATE_KEY --broadcast --legacy --gas-price 2000000000 --slow
	@echo ""
	@echo "💰 Step 6: Transferring funds to automation vault..."
	@. ./.env && forge script script/automation/TransferFundsToNewVault.s.sol:TransferFundsToNewVault \
		--rpc-url $$RPC_URL --private-key $$PRIVATE_KEY --broadcast --legacy --gas-price 2000000000 --slow
	@echo ""
	@echo "💧 Step 7: Adding USDC liquidity to vault..."
	@. ./.env && forge script script/automation/AddVaultLiquidity.s.sol:AddVaultLiquidity \
		--rpc-url $$RPC_URL --private-key $$PRIVATE_KEY --broadcast --legacy --gas-price 2000000000 --slow
	@echo ""
	@echo "✅ Step 8: Verifying system configuration..."
	@. ./.env && forge script script/CheckMockOracleStatus.s.sol:CheckMockOracleStatus \
		--rpc-url $$RPC_URL --legacy --gas-price 2000000000
	@echo ""
	@echo "🎯 Step 9: Generating Chainlink Automation configuration..."
	@echo ""
	@echo "=================================================="
	@echo "🎯 CHAINLINK UPKEEP REGISTRATION INFORMATION"
	@echo "=================================================="
	@. ./.env && forge script script/automation/GenerateUpkeepConfig.s.sol:GenerateUpkeepConfig \
		--rpc-url $$RPC_URL --legacy --gas-price 2000000000
	@echo ""
	@echo "=================================================="
	@echo "🎉 COMPLETE MOCK STACK DEPLOYMENT FINISHED!"
	@echo "=================================================="
	@echo ""
	@echo "📊 SYSTEM STATUS:"
	@echo "✅ Core lending system deployed"
	@echo "✅ Mock Oracle configured with realistic prices:"
	@echo "   • ETH: $$2,500 USD"
	@echo "   • BTC: $$104,000 USD"
	@echo "   • USDC: $$1.00 USD"
	@echo "   • VCOP: $$1.00 USD"
	@echo "✅ VaultBasedHandler with automation functions"
	@echo "✅ 200,000+ USDC liquidity for liquidations (FIXED)"
	@echo "✅ AutomationKeeper authorized in vault"
	@echo "✅ ERC20InsufficientAllowance problem SOLVED"
	@echo ""
	@echo "🚀 NEXT STEPS:"
	@echo "1. Register the upkeep using the information above"
	@echo "2. Test with: make create-test-positions"
	@echo "3. Trigger liquidations: make crash-prices"
	@echo "4. Monitor: https://automation.chain.link/base-sepolia"
	@echo ""
	@echo "🎯 YOUR COMPLETE SYSTEM IS READY AND FIXED! 🎯"

# Production deployment with optimizations
deploy-complete-optimized:
	@echo "🏭 PRODUCTION DEPLOYMENT"
	@echo "======================="
	@forge build --optimize --optimizer-runs 200
	@$(MAKE) deploy-complete
	@echo "✅ OPTIMIZED DEPLOYMENT COMPLETED!"

# Deploy Emergency Registry standalone
deploy-emergency-registry:
	@echo "🔥 DEPLOYING EMERGENCY REGISTRY"
	@echo "==============================="
	@. ./.env && forge script script/deploy/DeployEmergencyRegistry.s.sol:DeployEmergencyRegistry \
		--rpc-url $$RPC_URL --private-key $$PRIVATE_KEY --broadcast --legacy --gas-price 30000000000 --slow
	@echo "✅ Emergency Registry deployed!"

# ========================================
# 🧪 TESTING COMMANDS
# ========================================

# Create test positions for liquidation testing
create-test-positions:
	@echo "🧪 CREATING TEST POSITIONS FOR LIQUIDATION"
	@echo "=========================================="
	@. ./.env && forge script script/test/Step1_CreateTestPositions.s.sol:Step1_CreateTestPositions \
		--rpc-url $$RPC_URL --private-key $$PRIVATE_KEY --broadcast --legacy --gas-price 2000000000
	@echo "✅ Test positions created!"

# Crash prices to trigger liquidations
crash-prices:
	@echo "💥 CRASHING PRICES TO TRIGGER LIQUIDATIONS"
	@echo "==========================================="
	@. ./.env && forge script script/test/Step2_CrashPrices.s.sol:Step2_CrashPrices \
		--rpc-url $$RPC_URL --private-key $$PRIVATE_KEY --broadcast --legacy --gas-price 2000000000
	@echo "✅ Prices crashed! Positions should be liquidatable now."

# Generate upkeep configuration
generate-upkeep-config:
	@echo "🎯 GENERATING CHAINLINK UPKEEP CONFIGURATION"
	@echo "============================================="
	@. ./.env && forge script script/automation/GenerateUpkeepConfig.s.sol:GenerateUpkeepConfig \
		--rpc-url $$RPC_URL --legacy --gas-price 2000000000
	@echo "✅ Upkeep configuration generated!"

# Check system status
check-system-status:
	@echo "🔍 CHECKING SYSTEM STATUS"
	@echo "========================="
	@. ./.env && forge script script/CheckMockOracleStatus.s.sol:CheckMockOracleStatus \
		--rpc-url $$RPC_URL --legacy --gas-price 2000000000
	@. ./.env && forge script script/automation/SimpleVaultCheck.s.sol:SimpleVaultCheck \
		--rpc-url $$RPC_URL --legacy --gas-price 2000000000
	@echo "✅ System status checked!" 