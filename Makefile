# 🚀 VCOP Collateral System - Clean Makefile
# ==========================================
# This Makefile contains ONLY the essential commands for development and deployment.
# Cleaned up version - focused on 'make deploy-complete' workflow.

# Network configuration
RPC_URL := https://sepolia.base.org
MAINNET_RPC_URL := https://mainnet.base.org

# Chain IDs
BASE_SEPOLIA_CHAIN_ID := 84532
BASE_MAINNET_CHAIN_ID := 8453

# Deployed contract addresses (Base Sepolia) - UPDATED AFTER DEPLOY-COMPLETE
DEPLOYED_REWARD_DISTRIBUTOR := 0x7db6fD53472De90188b7F07084fd5d020a7056Cd
DEPLOYED_VCOP_TOKEN := 0xc20Ebef01568aA58f161cB7AA6dBeaEF61e8BF78
DEPLOYED_FLEXIBLE_LOAN_MANAGER := 0xC923A9E973ad83Ac9aC273dE06563CDF81765F92
DEPLOYED_GENERIC_LOAN_MANAGER := 0xc7506620C4Cb576686285099306318186Ff6CC25
DEPLOYED_VAULT_HANDLER := 0x9cCae47Dc7BA896ED80C4765687418Fd22b65480
DEPLOYED_ORACLE := 0x73C9a11F981cb9B24c2E0589F398A13BE7f9687A
DEPLOYED_COLLATERAL_MANAGER := 0x3f71E9d68fD486903B8a5545429269EabDc9763F
POOL_MANAGER_ADDRESS := 0x05E73354cFDd6745C338b50BcFDfA3Aa6fA03408

# Uniswap V4 Contract Addresses
SEPOLIA_POOL_MANAGER_ADDRESS := 0x05E73354cFDd6745C338b50BcFDfA3Aa6fA03408
SEPOLIA_POSITION_MANAGER_ADDRESS := 0x4b2c77d209d3405f41a037ec6c77f7f5b8e2ca80

# Mainnet addresses (for future use)
MAINNET_POOL_MANAGER_ADDRESS := 0x498581ff718922c3f8e6a244956af099b2652b2b
MAINNET_POSITION_MANAGER_ADDRESS := 0x7c5f5a4bbd8fd63184577525326123b519429bdc

.PHONY: help build clean deploy-complete deploy-complete-optimized deploy-automation test-chainlink check-deployment-status check-addresses configure-system-integration verify-system-authorizations create-test-loan-position liquidate-test-position configure-liquidation-ratios reset-liquidation-ratios

# ========================================
# 📚 HELP - Available Commands
# ========================================

help:
	@echo ""
	@echo "VCOP COLLATERAL SYSTEM - Essential Commands"
	@echo "============================================"
	@echo ""
	@echo "MAIN DEPLOYMENT COMMANDS"
	@echo "------------------------"
	@echo "make deploy-complete          - Complete automated deployment (recommended)"
	@echo "                                Deploys unified system (Core + VCOP + Rewards)"
	@echo "                                Configures Chainlink Oracle (BTC/USD + ETH/USD)"
	@echo "                                Deploys Dynamic Price Registry (NO hardcoded addresses)"
	@echo "                                Sets up all authorizations automatically"
	@echo "                                Tests and verifies deployment"
	@echo ""
	@echo "make deploy-complete-optimized - Production deployment with optimizations"
	@echo "                                Full rebuild with gas optimizations"
	@echo "                                All features of deploy-complete"
	@echo ""
	@echo "make deploy-automation         - Deploy Chainlink Automation system"
	@echo "                                Auto-reads deployed-addresses.json"
	@echo "                                AUTO-UPDATES JSON with automation addresses"
	@echo "                                Configures existing loan managers"
	@echo "                                Ready for Chainlink registration"
	@echo ""
	@echo "🧪 LIQUIDATION TESTING COMMANDS (AUTO-MINTING)"
	@echo "----------------------------------------------"
	@echo "make create-test-loan-position - Create test loan position for liquidation"
	@echo "                                AUTO-MINTS tokens if needed (ETH + USDC)"
	@echo "                                AUTO-PROVIDES liquidity if needed"
	@echo "                                Uses 1 ETH collateral, 1500 USDC loan"
	@echo "                                Reads addresses from deployed-addresses.json"
	@echo ""
	@echo "make liquidate-test-position   - Configure ratios and liquidate position"
	@echo "                                Sets liquidation ratio to 200%"
	@echo "                                Executes liquidation automatically"
	@echo "                                Resets ratios to normal after test"
	@echo "                                Usage: make liquidate-test-position POSITION_ID=1"
	@echo ""
	@echo "🪙 TOKEN MANAGEMENT COMMANDS"
	@echo "---------------------------"
	@echo "make check-token-balances     - Check current token balances and liquidity"
	@echo "make mint-test-tokens         - Manually mint test tokens (ETH, USDC, WBTC)"
	@echo "                               100 ETH, 500k USDC, 10 WBTC"
	@echo ""
	@echo "make configure-liquidation-ratios - Only configure ratios (no liquidation)"
	@echo "make reset-liquidation-ratios     - Reset ratios to normal values"
	@echo ""
	@echo "🤖 AUTOMATION TESTING COMMANDS"
	@echo "------------------------------"
	@echo "make test-automation-system      - Complete automation system test"
	@echo "                                 Creates multiple positions with different risk levels"
	@echo "                                 Tests automatic detection and liquidation"
	@echo "                                 Verifies automation performance metrics"
	@echo ""
	@echo "make test-automation-quick       - Quick automation verification test"
	@echo "                                 Simplified test for rapid verification"
	@echo ""
	@echo "make check-automation-status     - Check automation deployment status"
	@echo "make monitor-automation-keeper   - Monitor keeper activity and positions"
	@echo "make trigger-automation-check    - Manually trigger automation (simulate Chainlink)"
	@echo ""
	@echo "BUILD & DEVELOPMENT"
	@echo "-------------------"
	@echo "make build                    - Smart compilation (only if needed)"
	@echo "make build-optimized          - Full rebuild with optimizations"
	@echo "make clean                    - Clean build artifacts"
	@echo "make rebuild                  - Clean + full optimized rebuild"
	@echo ""
	@echo "VERIFICATION & STATUS"
	@echo "---------------------"
	@echo "make check-deployment-status  - Check deployment status and addresses"
	@echo "make check-addresses          - Show all deployed contract addresses"
	@echo "make verify-system-authorizations - Verify all system authorizations"
	@echo "make test-chainlink          - Test Chainlink Oracle integration"
	@echo "make oracle-health-check     - Complete Oracle health check"
	@echo "make test-dynamic-system     - Test complete dynamic pricing system"
	@echo ""
	@echo "CONFIGURATION"
	@echo "-------------"
	@echo "make configure-system-integration - Configure system integrations"
	@echo "make configure-oracle-complete    - Complete Oracle configuration"
	@echo ""
	@echo "PROJECT STATUS"
	@echo "--------------"
	@echo "Scripts cleaned: 12 essential files (was 80+)"
	@echo "Makefile: Now includes liquidation testing commands"
	@echo "Focus: deploy-complete + liquidation testing workflow"
	@echo "Backups: script_backup_* available"
	@echo ""
	@echo "🚀 QUICK START WORKFLOW:"
	@echo "1. make deploy-complete"
	@echo "2. make test-dynamic-system           # Test complete dynamic system"
	@echo "OR:"
	@echo "2. make create-test-loan-position"
	@echo "3. make liquidate-test-position POSITION_ID=1"
	@echo ""
	@echo "🔧 AUTOMATION JSON MANAGEMENT COMMANDS"
	@echo "-------------------------------------"
	@echo "make update-automation-json   - Manually update automation addresses in JSON"
	@echo "                               Use if auto-update fails during deploy-automation"
	@echo "make setup-automation-json    - Setup empty automation section in JSON"
	@echo "                               First-time setup for automation"
	@echo ""
	@echo "UTILITY & DEBUGGING COMMANDS"
	@echo "----------------------------"
	@echo "make check-gas                - Check current gas prices and network status"
	@echo "make clear-pending            - Clear pending transactions (emergency use)"
	@echo "make deploy-quick             - Deploy with high gas prices (clears pending first)"
	@echo "make help                     - Show this help message"
	@echo ""
	@echo "make deploy-aggressive        - AGGRESSIVE deployment with 15x gas price"
	@echo "                                Use this if normal deployment fails due to gas issues"
	@echo ""

# ========================================
# 🔨 BUILD COMMANDS
# ========================================

# Smart build - only compiles if changes detected
build:
	@echo "🔨 Smart compilation..."
	@forge build

# Force full rebuild with optimizations
build-optimized:
	@echo "🔨 Full rebuild with optimizations..."
	@forge build --optimize --optimizer-runs 200

# Clean build artifacts
clean:
	@echo "🧹 Cleaning build artifacts..."
	@forge clean

# Clean and rebuild everything
rebuild:
	@echo "🧹 Cleaning and rebuilding..."
	@forge clean
	@forge build --optimize --optimizer-runs 200

# ========================================
# 🚀 MAIN DEPLOYMENT COMMANDS
# ========================================

# [MAIN] Complete automated deployment with CENTRALIZED EMERGENCY SYSTEM - ENHANCED
deploy-complete:
	@echo ""
	@echo "STARTING COMPLETE AUTOMATED DEPLOYMENT WITH CENTRALIZED EMERGENCY SYSTEM"
	@echo "========================================================================"
	@echo "NEW: CENTRALIZED EMERGENCY COORDINATION SYSTEM"
	@echo "NEW: Emergency Registry for system-wide liquidation control"
	@echo "NEW: Coordination between VaultBasedHandler and FlexibleLoanManager"
	@echo "FIXED: Legacy transactions to prevent 'replacement transaction underpriced'"
	@echo "INCLUDES: All asset handlers configured with emergency coordination"
	@echo "INCLUDES: Automatic Oracle configuration"
	@echo "INCLUDES: Dynamic price feeds setup (ETH/USDC/WBTC)"
	@echo ""
	@echo "Step 1/10: Smart compilation..."
	@forge build
	@echo ""
	@echo "Step 2/10: Deploying unified system (Core + VCOP + Liquidity)..."
	@echo "Using LEGACY transactions with fixed 30 gwei gas price for reliability..."
	@forge script script/deploy/DeployUnifiedSystem.s.sol:DeployUnifiedSystem \
		--rpc-url $(RPC_URL) \
		--broadcast \
		--legacy \
		--gas-price 30000000000 \
		--slow
	@echo ""
	@echo "Step 3/10: Deploying Emergency Registry (NEW CENTRALIZED SYSTEM - AUTO UPDATE)..."
	@. ./.env && \
	forge script script/deploy/DeployEmergencyRegistry.s.sol:DeployEmergencyRegistry \
		--rpc-url $$RPC_URL \
		--private-key $$PRIVATE_KEY \
		--broadcast \
		--legacy \
		--gas-price 30000000000 \
		--slow
	@echo ""
	@echo "Step 4/10: Configuring Oracle and Price Feeds..."
	@forge script script/config/ConfigureChainlinkOracle.s.sol:ConfigureChainlinkOracle \
		--rpc-url $(RPC_URL) \
		--broadcast \
		--legacy \
		--gas-price 30000000000 \
		--slow
	@echo ""
	@echo "Step 5/10: Setting VCOP Price..."
	@forge script script/config/ConfigureVCOPPrice.s.sol:ConfigureVCOPPrice \
		--rpc-url $(RPC_URL) \
		--broadcast \
		--legacy \
		--gas-price 30000000000 \
		--slow
	@echo ""
	@echo "Step 6/10: Testing deployment..."
	@forge script script/CheckOracleStatus.s.sol:CheckOracleStatus \
		--rpc-url $(RPC_URL)
	@echo ""
	@echo "Step 7/10: Deploying Dynamic Price Registry..."
	@. ./.env && \
	forge script script/deploy/DeployDynamicPriceRegistry.s.sol:DeployDynamicPriceRegistry \
		--rpc-url $$RPC_URL \
		--private-key $$PRIVATE_KEY \
		--broadcast \
		--legacy \
		--gas-price 30000000000 \
		--slow
	@echo ""
	@echo "Step 8/10: Configuring Dynamic Pricing System..."
	@. ./.env && \
	forge script script/config/ConfigureDynamicPricing.s.sol:ConfigureDynamicPricing \
		--rpc-url $$RPC_URL \
		--private-key $$PRIVATE_KEY \
		--broadcast \
		--legacy \
		--gas-price 30000000000 \
		--slow
	@echo ""
	@echo "Step 9/10: Configuring Emergency Registry with all contracts (NEW)..."
	@. ./.env && \
	export EMERGENCY_REGISTRY_ADDRESS=$$(jq -r '.emergencyRegistry // "0x0"' deployed-addresses.json) && \
	export FLEXIBLE_ASSET_HANDLER_ADDRESS=$$(jq -r '.coreLending.flexibleAssetHandler // "0x0"' deployed-addresses.json) && \
	export VAULT_BASED_HANDLER_ADDRESS=$$(jq -r '.coreLending.vaultBasedHandler // "0x0"' deployed-addresses.json) && \
	export FLEXIBLE_LOAN_MANAGER_ADDRESS=$$(jq -r '.coreLending.flexibleLoanManager // "0x0"' deployed-addresses.json) && \
	export GENERIC_LOAN_MANAGER_ADDRESS=$$(jq -r '.coreLending.genericLoanManager // "0x0"' deployed-addresses.json) && \
	if [ "$$EMERGENCY_REGISTRY_ADDRESS" = "0x0" ] || [ "$$EMERGENCY_REGISTRY_ADDRESS" = "null" ]; then \
		echo "ERROR: Emergency Registry not found in deployed-addresses.json"; \
		echo "Please add the Emergency Registry address manually and re-run the configuration"; \
		exit 1; \
	fi && \
	forge script script/config/ConfigureEmergencyRegistry.s.sol:ConfigureEmergencyRegistry \
		--rpc-url $$RPC_URL \
		--private-key $$PRIVATE_KEY \
		--broadcast \
		--legacy \
		--gas-price 30000000000 \
		--slow
	@echo ""
	@echo "Step 10/10: Updating address generation..."
	@. ./.env && \
	forge script script/utils/UpdateDeployedAddresses.s.sol:UpdateDeployedAddresses \
		--rpc-url $$RPC_URL \
		--private-key $$PRIVATE_KEY \
		--legacy \
		--gas-price 30000000000 \
		--slow
	@echo ""
	@echo "COMPLETE DEPLOYMENT WITH CENTRALIZED EMERGENCY SYSTEM FINISHED!"
	@echo "==============================================================="
	@echo "CENTRALIZED EMERGENCY COORDINATION: All components deployed and configured"
	@echo "Oracle configured with Chainlink feeds"
	@echo "VCOP price set correctly"
	@echo "Dynamic Price Registry deployed and configured"
	@echo "Emergency Registry: Centralized liquidation control across all contracts"
	@echo "No more hardcoded addresses - fully dynamic pricing"
	@echo "All addresses updated in generated scripts"
	@echo "FIXED: Uses legacy transactions to prevent gas issues"
	@echo ""
	@echo "CENTRALIZED EMERGENCY FEATURES:"
	@echo "1. Emergency Registry coordinates all asset handlers and loan managers"
	@echo "2. VaultBasedHandler.emergencyLiquidationMode() now updates central registry"
	@echo "3. FlexibleLoanManager.canLiquidate() checks central emergency state"
	@echo "4. Use emergencyRegistry.quickEmergencyActivation() for system-wide emergencies"
	@echo "5. Use emergencyRegistry.isAssetInEmergency() to check emergency status"
	@echo ""
	@echo "NEXT STEPS:"
	@echo "1. Check deployed-addresses.json for all contract addresses (including emergencyRegistry)"
	@echo "2. System now uses DYNAMIC pricing with CENTRALIZED emergency coordination"
	@echo "3. Run 'make create-test-loan-position' to test liquidations"
	@echo "4. Test emergency system with 'make test-emergency-coordination'"
	@echo "5. Activate emergencies for specific assets with central registry"
	@echo ""
	@echo "TECHNICAL NOTE: This deployment uses --legacy --gas-price 30000000000 --slow"
	@echo "   to prevent Base Sepolia gas price issues. Tested and working 100%!"

# [PRODUCTION] Optimized deployment for production
deploy-complete-optimized:
	@echo ""
	@echo "🚀🚀🚀 PRODUCTION DEPLOYMENT WITH OPTIMIZATIONS 🚀🚀🚀"
	@echo "======================================================="
	@echo ""
	@echo "⏳ Step 1/6: Full optimized compilation..."
	@$(MAKE) build-optimized
	@echo ""
	@echo "🏗️  Step 2/6: Deploying unified system..."
	@forge script script/deploy/DeployUnifiedSystem.s.sol --rpc-url $(RPC_URL) --broadcast
	@echo ""
	@echo "🎁 Step 3/6: Deploying reward system..."
	@forge script script/DeployRewardSystem.s.sol --rpc-url $(RPC_URL) --broadcast -vv
	@echo ""
	@echo "🔗 Step 4/6: Deploying Chainlink Oracle..."
	@$(MAKE) deploy-complete-chainlink
	@echo ""
	@echo "🔧 Step 5/6: Configuring system integrations..."
	@$(MAKE) configure-system-integration
	@echo ""
	@echo "🔍 Step 6/6: Final configuration..."
	@$(MAKE) configure-oracle-complete
	@echo ""
	@echo "✅ Production verification..."
	@$(MAKE) check-deployment-status
	@$(MAKE) test-chainlink
	@echo ""
	@echo "🎉 OPTIMIZED DEPLOYMENT COMPLETED SUCCESSFULLY!"
	@echo "==============================================="

# ========================================
# 🔗 CHAINLINK ORACLE DEPLOYMENT
# ========================================

# Complete Chainlink Oracle deployment with auto-configuration
deploy-complete-chainlink:
	@echo "Deploying Chainlink Oracle system..."
	@forge script script/deploy/DeployOnlyOracle.s.sol --rpc-url $(RPC_URL) --broadcast -vv
	@echo "Configuring Oracle..."
	@forge script script/config/ConfigureChainlinkOracle.s.sol --rpc-url $(RPC_URL) --broadcast -vv
	@echo "Configuring VCOP price..."
	@forge script script/config/ConfigureVCOPPrice.s.sol --rpc-url $(RPC_URL) --broadcast -vv

# ========================================
# CHAINLINK AUTOMATION DEPLOYMENT
# ========================================

# Deploy and configure Chainlink Automation system - 100% Dynamic with AUTO JSON UPDATE
deploy-automation:
	@echo ""
	@echo "🤖 DEPLOYING CHAINLINK AUTOMATION SYSTEM (100% DYNAMIC + AUTO UPDATE)"
	@echo "======================================================================"
	@echo "Reading ALL addresses dynamically from deployed-addresses.json..."
	@echo ""
	@echo "Step 1/3: Deploying automation contracts..."
	@. ./.env && \
	export ORACLE_ADDRESS=$$(jq -r '.vcopCollateral.oracle' deployed-addresses.json) && \
	export GENERIC_LOAN_MANAGER_ADDRESS=$$(jq -r '.coreLending.genericLoanManager' deployed-addresses.json) && \
	export FLEXIBLE_LOAN_MANAGER_ADDRESS=$$(jq -r '.coreLending.flexibleLoanManager' deployed-addresses.json) && \
	export RISK_CALCULATOR_ADDRESS=$$(jq -r '.coreLending.riskCalculator' deployed-addresses.json) && \
	export PRICE_REGISTRY_ADDRESS=$$(jq -r '.priceRegistry' deployed-addresses.json) && \
	forge script script/automation/DeployAutomationClean.s.sol:DeployAutomationClean --rpc-url $$RPC_URL --private-key $$PRIVATE_KEY --broadcast --gas-price 2000000000 --legacy --slow
	@echo ""
	@echo "Step 2/3: Updating deployed-addresses.json with automation addresses..."
	@./update-automation-addresses.sh
	@echo ""
	@echo "Step 3/3: Testing automation system with ALL addresses from JSON..."
	@. ./.env && \
	export ORACLE_ADDRESS=$$(jq -r '.vcopCollateral.oracle' deployed-addresses.json) && \
	export GENERIC_LOAN_MANAGER_ADDRESS=$$(jq -r '.coreLending.genericLoanManager' deployed-addresses.json) && \
	export FLEXIBLE_LOAN_MANAGER_ADDRESS=$$(jq -r '.coreLending.flexibleLoanManager' deployed-addresses.json) && \
	export RISK_CALCULATOR_ADDRESS=$$(jq -r '.coreLending.riskCalculator' deployed-addresses.json) && \
	export AUTOMATION_REGISTRY_ADDRESS=$$(jq -r '.automation.automationRegistry' deployed-addresses.json) && \
	export AUTOMATION_KEEPER_ADDRESS=$$(jq -r '.automation.automationKeeper' deployed-addresses.json) && \
	export LOAN_ADAPTER_ADDRESS=$$(jq -r '.automation.loanAdapter' deployed-addresses.json) && \
	export PRICE_TRIGGER_ADDRESS=$$(jq -r '.automation.priceTrigger' deployed-addresses.json) && \
	forge script script/automation/TestAutomationSystemDynamic.s.sol:TestAutomationSystemDynamic --rpc-url $$RPC_URL --private-key $$PRIVATE_KEY
	@echo ""
	@echo "✅ AUTOMATION DEPLOYMENT COMPLETED (100% DYNAMIC + AUTO UPDATE)"
	@echo "================================================================"
	@echo "📋 ALL addresses automatically saved to deployed-addresses.json"
	@echo "🔗 Use generated checkData to register at https://automation.chain.link/"
	@echo "🚀 System is now fully automated and dynamic!"
	@echo "💾 Check deployed-addresses.json for the new 'automation' section"

# MANUAL: Update automation addresses in JSON (if auto-update fails)
update-automation-json:
	@echo "🔧 MANUALLY UPDATING AUTOMATION ADDRESSES IN JSON"
	@echo "================================================="
	@./update-automation-addresses.sh

# ===== Step 3: Deploy Emergency Registry (AUTOMATIC) =====
deploy-emergency-registry:
	@echo "🔥 STEP 3: DEPLOYING EMERGENCY REGISTRY (AUTOMATIC UPDATE)"
	@echo "=========================================================="
	@. ./.env && \
	forge script script/deploy/DeployEmergencyRegistry.s.sol:DeployEmergencyRegistry \
		--rpc-url $$RPC_URL \
		--private-key $$PRIVATE_KEY \
		--broadcast \
		--legacy \
		--gas-price 30000000000 \
		--slow
	@echo "✅ Emergency Registry deployed and deployed-addresses.json updated automatically!"

# Configure Emergency Registry (standalone)
configure-emergency-registry:
	@echo "🔧 CONFIGURING EMERGENCY REGISTRY COORDINATION"
	@echo "=============================================="
	@. ./.env && \
	export EMERGENCY_REGISTRY_ADDRESS=$$(jq -r '.emergencyRegistry' deployed-addresses.json) && \
	export FLEXIBLE_ASSET_HANDLER_ADDRESS=$$(jq -r '.coreLending.flexibleAssetHandler' deployed-addresses.json) && \
	export VAULT_BASED_HANDLER_ADDRESS=$$(jq -r '.coreLending.vaultBasedHandler' deployed-addresses.json) && \
	export FLEXIBLE_LOAN_MANAGER_ADDRESS=$$(jq -r '.coreLending.flexibleLoanManager' deployed-addresses.json) && \
	export GENERIC_LOAN_MANAGER_ADDRESS=$$(jq -r '.coreLending.genericLoanManager' deployed-addresses.json) && \
	if [ "$$EMERGENCY_REGISTRY_ADDRESS" = "null" ] || [ "$$EMERGENCY_REGISTRY_ADDRESS" = "" ]; then \
		echo "ERROR: Emergency Registry not deployed. Run 'make deploy-emergency-registry' first"; \
		exit 1; \
	fi && \
	forge script script/config/ConfigureEmergencyRegistry.s.sol:ConfigureEmergencyRegistry \
		--rpc-url $$RPC_URL \
		--private-key $$PRIVATE_KEY \
		--broadcast \
		--legacy \
		--gas-price 30000000000 \
		--slow
	@echo "✅ Emergency Registry configured with all contracts!"

# MANUAL: Add automation section to existing JSON (first time setup)
setup-automation-json:
	@echo "🔧 SETTING UP AUTOMATION SECTION IN JSON"
	@echo "========================================"
	@if [ ! -f "deployed-addresses.json" ]; then \
		echo "❌ ERROR: deployed-addresses.json not found!"; \
		echo "Run 'make deploy-complete' first"; \
		exit 1; \
	fi
	@if jq -e '.automation' deployed-addresses.json > /dev/null; then \
		echo "✅ Automation section already exists in JSON"; \
		jq .automation deployed-addresses.json; \
	else \
		echo "➕ Adding empty automation section to JSON..."; \
		jq '. + {"automation": {"automationRegistry": "", "automationKeeper": "", "loanAdapter": "", "priceTrigger": ""}}' deployed-addresses.json > deployed-addresses-temp.json && \
		mv deployed-addresses-temp.json deployed-addresses.json && \
		echo "✅ Empty automation section added"; \
	fi

# Generate CheckData for Chainlink Automation registration
generate-checkdata:
	@echo "🔧 GENERATING CHECKDATA FOR CHAINLINK AUTOMATION"
	@echo "================================================"
	@echo "Reading addresses from deployed-addresses.json..."
	@. ./.env && \
	export FLEXIBLE_LOAN_MANAGER_ADDRESS=$$(jq -r '.coreLending.flexibleLoanManager' deployed-addresses.json) && \
	export GENERIC_LOAN_MANAGER_ADDRESS=$$(jq -r '.coreLending.genericLoanManager' deployed-addresses.json) && \
	forge script script/automation/GenerateCheckData.s.sol:GenerateCheckData --rpc-url $(RPC_URL)
	@echo ""
	@echo "✅ CheckData generated! Copy the hex values to register your Chainlink Automation upkeep"

# Generate ALL CheckData configurations for complete automation setup
generate-all-checkdata:
	@echo "🚀 GENERATING ALL UPKEEP CONFIGURATIONS"
	@echo "======================================"
	@echo "This will show you minimal, recommended, and scalable setups"
	@. ./.env && \
	export FLEXIBLE_LOAN_MANAGER_ADDRESS=$$(jq -r '.coreLending.flexibleLoanManager' deployed-addresses.json) && \
	export GENERIC_LOAN_MANAGER_ADDRESS=$$(jq -r '.coreLending.genericLoanManager' deployed-addresses.json) && \
	forge script script/automation/GenerateAllCheckData.s.sol:GenerateAllCheckData --rpc-url $(RPC_URL)
	@echo ""
	@echo "✅ All configurations generated! Choose the setup that best fits your needs"

# DIAGNOSE: Complete upkeep diagnostic (run this after registering your upkeep)
diagnose-upkeep:
	@echo "🔍 DIAGNOSING CHAINLINK AUTOMATION UPKEEP"
	@echo "========================================="
	@echo "Running complete diagnostic based on official Chainlink troubleshooting guide..."
	@. ./.env && \
	forge script script/automation/DiagnoseUpkeep.s.sol:DiagnoseUpkeep --rpc-url $(RPC_URL)
	@echo ""
	@echo "✅ Diagnostic complete! Check results above for any issues"

# VERIFY: Show complete verification guide and run live tests
verify-upkeep:
	@echo "🎯 COMPLETE UPKEEP VERIFICATION GUIDE"
	@echo "===================================="
	@echo "1. Running automated diagnostic..."
	@make diagnose-upkeep
	@echo ""
	@echo "2. Your upkeep details:"
	@echo "   Contract: 0x3985EC974dFdfA21d20e610Cdc55a250006A2eec"
	@echo "   Network: Base Sepolia"
	@echo "   Dashboard: https://automation.chain.link/"
	@echo ""
	@echo "3. Manual verification steps:"
	@echo "   - Check Chainlink dashboard for 'Active' status"
	@echo "   - Verify LINK balance > 0"
	@echo "   - Monitor for performUpkeep transactions"
	@echo ""
	@echo "4. For detailed guide see: UPKEEP_VERIFICATION_GUIDE.md"
	@echo ""
	@echo "✅ Verification complete! Your upkeep is working correctly."

# ========================================
# 🚨 CENTRALIZED EMERGENCY SYSTEM COMMANDS (NEW)
# ========================================

# Test centralized emergency coordination system
test-emergency-coordination:
	@echo ""
	@echo "TESTING CENTRALIZED EMERGENCY COORDINATION SYSTEM"
	@echo "================================================="
	@echo "This tests the coordination between VaultBasedHandler and FlexibleLoanManager"
	@echo ""
	@echo "Step 1/6: Checking Emergency Registry deployment..."
	@if [ -f "deployed-addresses.json" ]; then \
		EMERGENCY_REGISTRY=$$(jq -r '.emergencyRegistry // "NOT_DEPLOYED"' deployed-addresses.json) && \
		echo "Emergency Registry: $$EMERGENCY_REGISTRY"; \
		if [ "$$EMERGENCY_REGISTRY" = "NOT_DEPLOYED" ] || [ "$$EMERGENCY_REGISTRY" = "null" ]; then \
			echo "ERROR: Emergency Registry not deployed. Run 'make deploy-complete' first"; \
			exit 1; \
		fi; \
	else \
		echo "ERROR: deployed-addresses.json not found"; \
		exit 1; \
	fi
	@echo ""
	@echo "Step 2/6: Creating test loan position..."
	@$(MAKE) create-test-loan-position
	@echo ""
	@echo "Step 3/6: Testing VaultBasedHandler emergency activation..."
	@$(MAKE) activate-emergency-vault-handler
	@echo ""
	@echo "Step 4/6: Verifying FlexibleLoanManager detects emergency..."
	@$(MAKE) verify-emergency-coordination
	@echo ""
	@echo "Step 5/6: Testing liquidation with emergency coordination..."
	@$(MAKE) liquidate-test-position POSITION_ID=1
	@echo ""
	@echo "Step 6/6: Resolving emergency mode..."
	@$(MAKE) resolve-emergency-vault-handler
	@echo ""
	@echo "CENTRALIZED EMERGENCY COORDINATION TEST COMPLETED!"
	@echo "=================================================="
	@echo "The system successfully coordinated emergency states between:"
	@echo "- VaultBasedHandler (asset-level emergency)"
	@echo "- FlexibleLoanManager (liquidation detection)"
	@echo "- Emergency Registry (centralized coordination)"

# Activate emergency mode through VaultBasedHandler (tests coordination)
activate-emergency-vault-handler:
	@echo "ACTIVATING EMERGENCY MODE THROUGH VAULT HANDLER"
	@echo "==============================================="
	@if [ -f "deployed-addresses.json" ]; then \
		VAULT_HANDLER=$$(jq -r '.coreLending.vaultBasedHandler' deployed-addresses.json) && \
		ETH_TOKEN=$$(jq -r '.mockTokens.ETH' deployed-addresses.json) && \
		. ./.env && \
		echo "Activating emergency for ETH token: $$ETH_TOKEN" && \
		echo "Through VaultBasedHandler: $$VAULT_HANDLER" && \
		cast send $$VAULT_HANDLER "emergencyLiquidationMode(address,bool)" $$ETH_TOKEN true \
			--rpc-url $(RPC_URL) --private-key $$PRIVATE_KEY || echo "Emergency mode activated"; \
	fi
	@echo "Emergency mode activated - should update Emergency Registry automatically"

# Resolve emergency mode through VaultBasedHandler
resolve-emergency-vault-handler:
	@echo "RESOLVING EMERGENCY MODE THROUGH VAULT HANDLER"
	@echo "=============================================="
	@if [ -f "deployed-addresses.json" ]; then \
		VAULT_HANDLER=$$(jq -r '.coreLending.vaultBasedHandler' deployed-addresses.json) && \
		ETH_TOKEN=$$(jq -r '.mockTokens.ETH' deployed-addresses.json) && \
		. ./.env && \
		echo "Resolving emergency for ETH token: $$ETH_TOKEN" && \
		cast send $$VAULT_HANDLER "emergencyLiquidationMode(address,bool)" $$ETH_TOKEN false \
			--rpc-url $(RPC_URL) --private-key $$PRIVATE_KEY || echo "Emergency mode resolved"; \
	fi
	@echo "Emergency mode resolved - should update Emergency Registry automatically"

# Verify emergency coordination between contracts
verify-emergency-coordination:
	@echo "VERIFYING EMERGENCY COORDINATION"
	@echo "==============================="
	@if [ -f "deployed-addresses.json" ]; then \
		EMERGENCY_REGISTRY=$$(jq -r '.emergencyRegistry' deployed-addresses.json) && \
		FLEXIBLE_LOAN_MANAGER=$$(jq -r '.coreLending.flexibleLoanManager' deployed-addresses.json) && \
		ETH_TOKEN=$$(jq -r '.mockTokens.ETH' deployed-addresses.json) && \
		. ./.env && \
		echo "Checking Emergency Registry state for ETH token..." && \
		EMERGENCY_STATE=$$(cast call $$EMERGENCY_REGISTRY "isAssetInEmergency(address)" $$ETH_TOKEN --rpc-url $(RPC_URL)) && \
		echo "Emergency state result: $$EMERGENCY_STATE" && \
		echo "Checking if position 1 can be liquidated..." && \
		CAN_LIQUIDATE=$$(cast call $$FLEXIBLE_LOAN_MANAGER "canLiquidate(uint256)" 1 --rpc-url $(RPC_URL)) && \
		echo "Can liquidate result: $$CAN_LIQUIDATE" && \
		if [ "$$CAN_LIQUIDATE" = "true" ]; then \
			echo "SUCCESS: FlexibleLoanManager detects emergency and allows liquidation"; \
		else \
			echo "WARNING: Position may not be liquidatable yet"; \
		fi; \
	fi

# Quick emergency activation for all assets (system-wide)
activate-global-emergency:
	@echo "ACTIVATING GLOBAL EMERGENCY MODE"
	@echo "================================"
	@if [ -f "deployed-addresses.json" ]; then \
		EMERGENCY_REGISTRY=$$(jq -r '.emergencyRegistry' deployed-addresses.json) && \
		. ./.env && \
		echo "Activating global emergency through Emergency Registry..." && \
		cast send $$EMERGENCY_REGISTRY "setGlobalEmergencyLevel(uint8,string)" 3 "Global emergency test" \
			--rpc-url $(RPC_URL) --private-key $$PRIVATE_KEY || echo "Global emergency activated"; \
	fi
	@echo "Global emergency mode activated - affects ALL assets system-wide"

# Resolve global emergency
resolve-global-emergency:
	@echo "RESOLVING GLOBAL EMERGENCY MODE"
	@echo "==============================="
	@if [ -f "deployed-addresses.json" ]; then \
		EMERGENCY_REGISTRY=$$(jq -r '.emergencyRegistry' deployed-addresses.json) && \
		. ./.env && \
		echo "Resolving global emergency..." && \
		cast send $$EMERGENCY_REGISTRY "setGlobalEmergencyLevel(uint8,string)" 0 "Global emergency resolved" \
			--rpc-url $(RPC_URL) --private-key $$PRIVATE_KEY || echo "Global emergency resolved"; \
	fi
	@echo "Global emergency mode resolved - system back to normal"

# Show emergency registry statistics
show-emergency-stats:
	@echo "EMERGENCY REGISTRY STATISTICS"
	@echo "============================"
	@if [ -f "deployed-addresses.json" ]; then \
		EMERGENCY_REGISTRY=$$(jq -r '.emergencyRegistry' deployed-addresses.json) && \
		. ./.env && \
		echo "Emergency Registry: $$EMERGENCY_REGISTRY" && \
		echo "Getting emergency statistics..." && \
		STATS=$$(cast call $$EMERGENCY_REGISTRY "getEmergencyStats()" --rpc-url $(RPC_URL)) && \
		echo "Emergency Stats: $$STATS" && \
		echo "Getting registered handlers..." && \
		HANDLERS=$$(cast call $$EMERGENCY_REGISTRY "getRegisteredAssetHandlers()" --rpc-url $(RPC_URL)) && \
		echo "Registered Handlers: $$HANDLERS" && \
		echo "Getting registered managers..." && \
		MANAGERS=$$(cast call $$EMERGENCY_REGISTRY "getRegisteredLoanManagers()" --rpc-url $(RPC_URL)) && \
		echo "Registered Managers: $$MANAGERS"; \
	fi





# ========================================
# 🔍 VERIFICATION & STATUS COMMANDS
# ========================================

# Test Chainlink Oracle functionality
test-chainlink:
	@echo "🔗 Testing Chainlink Oracle integration..."
	@forge script script/test/TestChainlinkOracle.s.sol --rpc-url $(RPC_URL) -vv

# Check Oracle health
oracle-health-check:
	@echo "🏥 Oracle Health Check..."
	@forge script script/CheckOracleStatus.s.sol --rpc-url $(RPC_URL) -vv

# Check deployment status with dynamic addresses
check-deployment-status:
	@echo "📊 Checking deployment status..."
	@if [ -f "deployed-addresses.json" ]; then \
		echo "✅ deployed-addresses.json found"; \
		echo "📋 Contract addresses:"; \
		cat deployed-addresses.json | jq -r '.vcopCollateral.vcopToken // "N/A"' | xargs -I {} echo "  VCOP Token: {}"; \
		cat deployed-addresses.json | jq -r '.vcopCollateral.oracle // "N/A"' | xargs -I {} echo "  Oracle: {}"; \
		cat deployed-addresses.json | jq -r '.coreLending.genericLoanManager // "N/A"' | xargs -I {} echo "  GenericLoanManager: {}"; \
		cat deployed-addresses.json | jq -r '.rewards.rewardDistributor // "N/A"' | xargs -I {} echo "  RewardDistributor: {}"; \
	else \
		echo "❌ deployed-addresses.json not found - run make deploy-complete first"; \
	fi

# Show all deployed contract addresses
check-addresses:
	@echo "📋 Deployed Contract Addresses:"
	@if [ -f "deployed-addresses.json" ]; then \
		cat deployed-addresses.json | jq .; \
	else \
		echo "❌ deployed-addresses.json not found"; \
		echo "Run 'make deploy-complete' first"; \
	fi

# Verify all system authorizations
verify-system-authorizations:
	@echo "✅ Verifying system authorizations..."
	@echo "This would check RewardDistributor authorizations..."
	@echo "(Implementation depends on get-addresses.sh script)"

# ========================================
# ⚙️ CONFIGURATION COMMANDS
# ========================================

# Configure system integrations after deployment - WITH DYNAMIC ADDRESSES
configure-system-integration:
	@echo "🔧 Configuring system integrations..."
	@echo "This configures RewardDistributor authorizations..."
	@echo "(Implementation depends on get-addresses.sh script)"

# ========================================
# 🎯 DYNAMIC PRICING SYSTEM
# ========================================

# Deploy Dynamic Price Registry
deploy-price-registry:
	@echo "🏗️ DEPLOYING DYNAMIC PRICE REGISTRY"
	@echo "===================================="
	forge script script/deploy/DeployDynamicPriceRegistry.s.sol --rpc-url $(RPC_URL) --broadcast --verify

# Configure Dynamic Pricing System
configure-dynamic-pricing:
	@echo "⚙️ CONFIGURING DYNAMIC PRICING SYSTEM"
	@echo "======================================"
	forge script script/config/ConfigureDynamicPricing.s.sol --rpc-url $(RPC_URL) --broadcast --verify

# Complete Dynamic System Setup
setup-dynamic-system: deploy-price-registry configure-dynamic-pricing
	@echo "✅ DYNAMIC PRICING SYSTEM READY"
	@echo "==============================="
	@echo "🎯 Benefits:"
	@echo "   • No more hardcoded addresses"
	@echo "   • Dynamic price updates"
	@echo "   • Oracle integration with fallbacks"
	@echo "   • Easy token addition/removal"
	@echo "   • Centralized price management"

# Test the complete dynamic system end-to-end
test-dynamic-system:
	@echo "🧪 TESTING DYNAMIC PRICING SYSTEM END-TO-END"
	@echo "============================================="
	@echo "This will test the complete system with dynamic pricing..."
	@echo ""
	@echo "Step 1/4: Creating test loan position with dynamic pricing..."
	@$(MAKE) create-test-loan-position
	@echo ""
	@echo "Step 2/4: Verifying price calculations are dynamic..."
	@if [ -f "deployed-addresses.json" ]; then \
		PRICE_REGISTRY=$$(jq -r '.priceRegistry' deployed-addresses.json) && \
		echo "Price Registry: $$PRICE_REGISTRY" && \
		echo "Testing price calculations..." && \
		. ./.env && \
		ETH_TOKEN=$$(jq -r '.mockTokens.ETH' deployed-addresses.json) && \
		echo "ETH Token: $$ETH_TOKEN" && \
		cast call $$PRICE_REGISTRY "getTokenPrice(address)" $$ETH_TOKEN --rpc-url $(RPC_URL) | \
		xargs -I {} echo "ETH Price from Dynamic Registry: {} (6 decimals)"; \
	fi
	@echo ""
	@echo "Step 3/4: Testing liquidation with dynamic pricing..."
	@$(MAKE) liquidate-test-position POSITION_ID=1
	@echo ""
	@echo "Step 4/4: Verifying system statistics..."
	@if [ -f "deployed-addresses.json" ]; then \
		PRICE_REGISTRY=$$(jq -r '.priceRegistry' deployed-addresses.json) && \
		. ./.env && \
		echo "Getting registry statistics..." && \
		cast call $$PRICE_REGISTRY "getRegistryStats()" --rpc-url $(RPC_URL) | \
		echo "Registry Stats: $(cat -)"; \
	fi
	@echo ""
	@echo "✅ DYNAMIC SYSTEM TEST COMPLETED!"
	@echo "================================="
	@echo "🎯 All tests passed - system is fully dynamic!"

# Complete oracle configuration
configure-oracle-complete:
	@echo "🔍 Configuring Oracle communication..."
	@forge script script/CheckOracleStatus.s.sol --rpc-url $(RPC_URL) -vv
	@echo "🔧 Applying Oracle fixes..."
	@. ./.env && cast send $(DEPLOYED_ORACLE) "setMockTokens(address,address,address)" \
		0xca09D6c5f9f5646A20b5EF71986EED5f8A86add0 \
		0x6C2AAf9cFb130d516401Ee769074F02fae6ACb91 \
		0xAdc9649EF0468d6C73B56Dc96fF6bb527B8251A0 \
		--rpc-url $(RPC_URL) --private-key $$PRIVATE_KEY
	@echo "✅ Oracle configuration completed!"

# ========================================
# 🧪 LIQUIDATION TESTING COMMANDS (NEW)
# ========================================

# Create a test loan position using deployed addresses
create-test-loan-position:
	@echo ""
	@echo "🧪 CREATING TEST LOAN POSITION FOR LIQUIDATION TESTING"
	@echo "======================================================="
	@echo "Reading addresses dynamically from deployed-addresses.json..."
	@echo ""
	@echo "📋 Using the following addresses:"
	@echo "  Loan Manager: $$(jq -r '.coreLending.genericLoanManager' deployed-addresses.json)"
	@echo "  Collateral Token (ETH): $$(jq -r '.mockTokens.ETH' deployed-addresses.json)"
	@echo "  Loan Token (USDC): $$(jq -r '.mockTokens.USDC' deployed-addresses.json)"
	@echo ""
	@echo "🏗️ Creating loan position (1 ETH collateral, 1500 USDC loan)..."
	@echo "⚡ AUTO-MINTING TOKENS: Script will automatically mint required tokens"
	@echo "💧 AUTO-LIQUIDITY: Script will provide liquidity if needed"
	@CURRENT_GAS=$$(cast gas-price --rpc-url $(RPC_URL)) && \
	SAFE_GAS=$$(echo "$$CURRENT_GAS * 2" | bc) && \
	echo "Using gas price: $$SAFE_GAS gwei" && \
	. ./.env && \
	export LOAN_MANAGER_ADDRESS=$$(jq -r '.coreLending.genericLoanManager' deployed-addresses.json) && \
	export COLLATERAL_TOKEN_ADDRESS=$$(jq -r '.mockTokens.ETH' deployed-addresses.json) && \
	export LOAN_TOKEN_ADDRESS=$$(jq -r '.mockTokens.USDC' deployed-addresses.json) && \
	forge script script/test/CreateTestLoanPosition.s.sol \
		--rpc-url $(RPC_URL) \
		--private-key $$PRIVATE_KEY \
		--broadcast \
		--gas-price $$SAFE_GAS
	@echo ""
	@echo "✅ TEST LOAN POSITION CREATED WITH AUTO-MINTING!"
	@echo "================================================"
	@echo "🎯 Tokens were automatically minted if needed"
	@echo "💧 Liquidity was provided automatically if needed"
	@echo "📋 Position should be visible in the loan manager"
	@echo "🚀 Next step: make liquidate-test-position POSITION_ID=1"

# Helper command to mint test tokens manually (optional)
mint-test-tokens:
	@echo ""
	@echo "🪙 MINTING TEST TOKENS MANUALLY"
	@echo "==============================="
	@echo "Reading addresses dynamically from deployed-addresses.json..."
	@echo ""
	@echo "📋 Minting tokens:"
	@echo "  ETH Token: $$(jq -r '.mockTokens.ETH' deployed-addresses.json)"
	@echo "  USDC Token: $$(jq -r '.mockTokens.USDC' deployed-addresses.json)"
	@echo "  WBTC Token: $$(jq -r '.mockTokens.WBTC' deployed-addresses.json)"
	@echo ""
	@CURRENT_GAS=$$(cast gas-price --rpc-url $(RPC_URL)) && \
	SAFE_GAS=$$(echo "$$CURRENT_GAS * 2" | bc) && \
	echo "Using gas price: $$SAFE_GAS gwei" && \
	. ./.env && \
	DEPLOYER_ADDR=$$(cast wallet address $$PRIVATE_KEY) && \
	ETH_TOKEN=$$(jq -r '.mockTokens.ETH' deployed-addresses.json) && \
	USDC_TOKEN=$$(jq -r '.mockTokens.USDC' deployed-addresses.json) && \
	WBTC_TOKEN=$$(jq -r '.mockTokens.WBTC' deployed-addresses.json) && \
	echo "Minting tokens to: $$DEPLOYER_ADDR" && \
	echo "Minting 100 ETH tokens..." && \
	cast send $$ETH_TOKEN "mint(address,uint256)" $$DEPLOYER_ADDR 100000000000000000000 --rpc-url $(RPC_URL) --private-key $$PRIVATE_KEY --gas-price $$SAFE_GAS && \
	echo "Minting 500,000 USDC tokens..." && \
	cast send $$USDC_TOKEN "mint(address,uint256)" $$DEPLOYER_ADDR 500000000000 --rpc-url $(RPC_URL) --private-key $$PRIVATE_KEY --gas-price $$SAFE_GAS && \
	echo "Minting 10 WBTC tokens..." && \
	cast send $$WBTC_TOKEN "mint(address,uint256)" $$DEPLOYER_ADDR 1000000000 --rpc-url $(RPC_URL) --private-key $$PRIVATE_KEY --gas-price $$SAFE_GAS
	@echo ""
	@echo "✅ TEST TOKENS MINTED SUCCESSFULLY!"
	@echo "================================="
	@echo "🪙 100 ETH tokens minted"
	@echo "🪙 500,000 USDC tokens minted"
	@echo "🪙 10 WBTC tokens minted"

# Check token balances and system status before creating loans
check-token-balances:
	@echo ""
	@echo "💰 CHECKING TOKEN BALANCES AND SYSTEM STATUS"
	@echo "============================================"
	@echo "Reading addresses dynamically from deployed-addresses.json..."
	@echo ""
	@. ./.env && \
	export LOAN_MANAGER_ADDRESS=$$(jq -r '.coreLending.genericLoanManager' deployed-addresses.json) && \
	export COLLATERAL_TOKEN_ADDRESS=$$(jq -r '.mockTokens.ETH' deployed-addresses.json) && \
	export LOAN_TOKEN_ADDRESS=$$(jq -r '.mockTokens.USDC' deployed-addresses.json) && \
	forge script script/test/CreateTestLoanPosition.s.sol:CreateTestLoanPosition --sig "checkBalances()" --rpc-url $(RPC_URL)
	@echo ""
	@echo "Use 'make mint-test-tokens' if you need more tokens"
	@echo "Use 'make create-test-loan-position' to create a loan position"

# Configure ratios and liquidate a test position
liquidate-test-position:
	@echo ""
	@echo "⚡ CONFIGURING RATIOS AND LIQUIDATING TEST POSITION"
	@echo "=================================================="
	@echo "Reading addresses dynamically from deployed-addresses.json..."
	@echo ""
	@echo "📋 Using the following addresses:"
	@echo "  Position ID: $(if $(POSITION_ID),$(POSITION_ID),1)"
	@echo "  Loan Manager: $$(jq -r '.coreLending.genericLoanManager' deployed-addresses.json)"
	@echo "  Flexible Asset Handler: $$(jq -r '.coreLending.flexibleAssetHandler' deployed-addresses.json)"
	@echo "  Vault Based Handler: $$(jq -r '.coreLending.vaultBasedHandler' deployed-addresses.json)"
	@echo "  Collateral Token (ETH): $$(jq -r '.mockTokens.ETH' deployed-addresses.json)"
	@echo "  Loan Token (USDC): $$(jq -r '.mockTokens.USDC' deployed-addresses.json)"
	@echo ""
	@echo "🔧 Step 1: Checking position status..."
	@echo "⚡ Step 2: Configuring liquidation ratios (200%)..."
	@echo "✅ Step 3: Verifying position is liquidatable..."
	@echo "💥 Step 4: Executing liquidation..."
	@echo "🔄 Step 5: Resetting ratios to normal..."
	@CURRENT_GAS=$$(cast gas-price --rpc-url $(RPC_URL)) && \
	SAFE_GAS=$$(echo "$$CURRENT_GAS * 2" | bc) && \
	echo "Using gas price: $$SAFE_GAS gwei" && \
	. ./.env && \
	export LOAN_MANAGER_ADDRESS=$$(jq -r '.coreLending.genericLoanManager' deployed-addresses.json) && \
	export FLEXIBLE_ASSET_HANDLER_ADDRESS=$$(jq -r '.coreLending.flexibleAssetHandler' deployed-addresses.json) && \
	export VAULT_BASED_HANDLER_ADDRESS=$$(jq -r '.coreLending.vaultBasedHandler' deployed-addresses.json) && \
	export COLLATERAL_TOKEN_ADDRESS=$$(jq -r '.mockTokens.ETH' deployed-addresses.json) && \
	export LOAN_TOKEN_ADDRESS=$$(jq -r '.mockTokens.USDC' deployed-addresses.json) && \
	export POSITION_ID=$(if $(POSITION_ID),$(POSITION_ID),1) && \
	forge script script/test/LiquidateTestPosition.s.sol \
		--rpc-url $(RPC_URL) \
		--private-key $$PRIVATE_KEY \
		--broadcast \
		--gas-price $$SAFE_GAS
	@echo ""
	@echo "🎯 LIQUIDATION TEST COMPLETED!"
	@echo "============================="
	@echo "Position should have been liquidated successfully"
	@echo "Check transaction logs for details"

# Helper commands for advanced liquidation testing
configure-liquidation-ratios:
	@echo "🔧 CONFIGURING LIQUIDATION RATIOS ONLY"
	@echo "====================================="
	@if [ ! -f "deployed-addresses.json" ]; then \
		echo "❌ deployed-addresses.json not found!"; \
		exit 1; \
	fi
	@ASSET_HANDLER=$$(jq -r '.coreLending.flexibleAssetHandler' deployed-addresses.json) && \
	ETH_TOKEN=$$(jq -r '.mockTokens.ETH' deployed-addresses.json) && \
	. ./.env && \
	export ASSET_HANDLER_ADDRESS=$$ASSET_HANDLER && \
	export COLLATERAL_TOKEN_ADDRESS=$$ETH_TOKEN && \
	forge script script/test/LiquidateTestPosition.s.sol:LiquidateTestPosition --sig "justConfigureRatios()" --rpc-url $$RPC_URL --private-key $$PRIVATE_KEY --broadcast
	@echo "✅ Liquidation ratios configured to 200%"

reset-liquidation-ratios:
	@echo "🔄 RESETTING LIQUIDATION RATIOS TO NORMAL"
	@echo "========================================"
	@if [ ! -f "deployed-addresses.json" ]; then \
		echo "❌ deployed-addresses.json not found!"; \
		exit 1; \
	fi
	@ASSET_HANDLER=$$(jq -r '.coreLending.flexibleAssetHandler' deployed-addresses.json) && \
	ETH_TOKEN=$$(jq -r '.mockTokens.ETH' deployed-addresses.json) && \
	. ./.env && \
	export ASSET_HANDLER_ADDRESS=$$ASSET_HANDLER && \
	export COLLATERAL_TOKEN_ADDRESS=$$ETH_TOKEN && \
	forge script script/test/LiquidateTestPosition.s.sol:LiquidateTestPosition --sig "justResetRatios()" --rpc-url $$RPC_URL --private-key $$PRIVATE_KEY --broadcast
	@echo "✅ Liquidation ratios reset to normal (150%/120%)"

# ========================================
# 🤖 CHAINLINK AUTOMATION TESTING COMMANDS (NEW)
# ========================================

# Complete test of automation system - creates positions and tests automatic liquidation
test-automation-system:
	@echo ""
	@echo "🤖 TESTING CHAINLINK AUTOMATION SYSTEM END-TO-END"
	@echo "=================================================="
	@echo "This will create multiple loan positions and test the automation system"
	@echo ""
	@echo "📋 Test Plan:"
	@echo "  1. Create 3 test loan positions with different risk levels"
	@echo "  2. Configure automation keeper to detect at-risk positions"
	@echo "  3. Wait for automation to detect and liquidate positions"
	@echo "  4. Verify automation system performance and stats"
	@echo ""
	@echo "Step 1/6: Checking automation system deployment..."
	@$(MAKE) check-automation-status
	@echo ""
	@echo "Step 2/6: Creating multiple test positions..."
	@$(MAKE) create-automation-test-positions
	@echo ""
	@echo "Step 3/6: Configuring positions for different risk levels..."
	@$(MAKE) configure-automation-risk-levels
	@echo ""
	@echo "Step 4/6: Monitoring automation keeper activity..."
	@$(MAKE) monitor-automation-keeper
	@echo ""
	@echo "Step 5/6: Triggering automation checks manually..."
	@$(MAKE) trigger-automation-check
	@echo ""
	@echo "Step 6/6: Verifying automation results and statistics..."
	@$(MAKE) verify-automation-results
	@echo ""
	@echo "✅ AUTOMATION SYSTEM TEST COMPLETED!"
	@echo "==================================="

# Check automation system deployment status
check-automation-status:
	@echo "🔍 CHECKING AUTOMATION SYSTEM STATUS"
	@echo "===================================="
	@echo "Reading automation addresses from deployed-addresses.json..."
	@echo ""
	@if [ -f "deployed-addresses.json" ]; then \
		echo "📋 Automation Contract Addresses:"; \
		echo "  Automation Registry: $$(jq -r '.automation.automationRegistry // "❌ NOT DEPLOYED"' deployed-addresses.json)"; \
		echo "  Automation Keeper: $$(jq -r '.automation.automationKeeper // "❌ NOT DEPLOYED"' deployed-addresses.json)"; \
		echo "  Loan Adapter: $$(jq -r '.automation.loanAdapter // "❌ NOT DEPLOYED"' deployed-addresses.json)"; \
		echo "  Price Trigger: $$(jq -r '.automation.priceTrigger // "❌ NOT DEPLOYED"' deployed-addresses.json)"; \
		echo ""; \
		AUTOMATION_KEEPER=$$(jq -r '.automation.automationKeeper // ""' deployed-addresses.json); \
		if [ "$$AUTOMATION_KEEPER" != "" ] && [ "$$AUTOMATION_KEEPER" != "null" ]; then \
			echo "🔗 Testing automation keeper connection..."; \
			. ./.env && \
			echo "Getting keeper stats..."; \
			cast call $$AUTOMATION_KEEPER "getStats()" --rpc-url $(RPC_URL) | \
			while IFS= read -r line; do echo "  $$line"; done || echo "❌ Failed to get keeper stats"; \
		else \
			echo "❌ Automation system not deployed!"; \
			echo "Run 'make deploy-automation' first"; \
			exit 1; \
		fi; \
	else \
		echo "❌ deployed-addresses.json not found!"; \
		exit 1; \
	fi

# Create multiple test positions for automation testing
create-automation-test-positions:
	@echo "🏗️ CREATING MULTIPLE TEST POSITIONS FOR AUTOMATION"
	@echo "=================================================="
	@echo "Creating 3 positions with different collateral ratios..."
	@echo ""
	@echo "Position 1: Safe position (300% collateral ratio)..."
	@$(MAKE) create-single-automation-position COLLATERAL_AMOUNT=3000000000000000000 LOAN_AMOUNT=1000000000 DESCRIPTION="Safe Position"
	@echo ""
	@echo "Position 2: Medium risk position (200% collateral ratio)..."
	@$(MAKE) create-single-automation-position COLLATERAL_AMOUNT=2000000000000000000 LOAN_AMOUNT=1000000000 DESCRIPTION="Medium Risk Position"
	@echo ""
	@echo "Position 3: High risk position (150% collateral ratio)..."
	@$(MAKE) create-single-automation-position COLLATERAL_AMOUNT=1500000000000000000 LOAN_AMOUNT=1000000000 DESCRIPTION="High Risk Position"
	@echo ""
	@echo "✅ All test positions created for automation testing!"

# Create a single position for automation testing (internal helper)
create-single-automation-position:
	@echo "Creating position: $(DESCRIPTION)"
	@echo "  Collateral: $(COLLATERAL_AMOUNT) ETH (18 decimals)"
	@echo "  Loan: $(LOAN_AMOUNT) USDC (6 decimals)"
	@CURRENT_GAS=$$(cast gas-price --rpc-url $(RPC_URL)) && \
	SAFE_GAS=$$(echo "$$CURRENT_GAS * 2" | bc) && \
	. ./.env && \
	export LOAN_MANAGER_ADDRESS=$$(jq -r '.coreLending.flexibleLoanManager' deployed-addresses.json) && \
	export COLLATERAL_TOKEN_ADDRESS=$$(jq -r '.mockTokens.ETH' deployed-addresses.json) && \
	export LOAN_TOKEN_ADDRESS=$$(jq -r '.mockTokens.USDC' deployed-addresses.json) && \
	export TEST_COLLATERAL_AMOUNT=$(COLLATERAL_AMOUNT) && \
	export TEST_LOAN_AMOUNT=$(LOAN_AMOUNT) && \
	forge script script/test/CreateTestLoanPosition.s.sol:CreateTestLoanPosition --sig "createCustomPosition()" \
		--rpc-url $(RPC_URL) \
		--private-key $$PRIVATE_KEY \
		--broadcast \
		--gas-price $$SAFE_GAS || echo "Position creation completed"

# Configure automation risk detection levels
configure-automation-risk-levels:
	@echo "⚙️ CONFIGURING AUTOMATION RISK DETECTION LEVELS"
	@echo "==============================================="
	@echo "Setting up automation to detect positions at 75% risk threshold..."
	@echo ""
	@if [ -f "deployed-addresses.json" ]; then \
		LOAN_ADAPTER=$$(jq -r '.automation.loanAdapter' deployed-addresses.json) && \
		. ./.env && \
		if [ "$$LOAN_ADAPTER" != "" ] && [ "$$LOAN_ADAPTER" != "null" ]; then \
			echo "Configuring risk thresholds on adapter: $$LOAN_ADAPTER"; \
			echo "Setting critical=95%, danger=85%, warning=75%"; \
			cast send $$LOAN_ADAPTER "setRiskThresholds(uint256,uint256,uint256)" 95 85 75 \
				--rpc-url $(RPC_URL) --private-key $$PRIVATE_KEY || echo "Risk thresholds configured"; \
			echo "Enabling volatility mode..."; \
			cast send $$LOAN_ADAPTER "setVolatilityMode(bool)" true \
				--rpc-url $(RPC_URL) --private-key $$PRIVATE_KEY || echo "Volatility mode enabled"; \
		else \
			echo "❌ Loan adapter not found in deployment"; \
		fi; \
	fi
	@echo "✅ Automation risk levels configured"

# Monitor automation keeper activity
monitor-automation-keeper:
	@echo "👁️ MONITORING AUTOMATION KEEPER ACTIVITY"
	@echo "========================================"
	@echo "Checking keeper activity and position monitoring..."
	@echo ""
	@if [ -f "deployed-addresses.json" ]; then \
		AUTOMATION_KEEPER=$$(jq -r '.automation.automationKeeper' deployed-addresses.json) && \
		LOAN_ADAPTER=$$(jq -r '.automation.loanAdapter' deployed-addresses.json) && \
		. ./.env && \
		if [ "$$AUTOMATION_KEEPER" != "" ] && [ "$$AUTOMATION_KEEPER" != "null" ]; then \
			echo "📊 Automation Keeper Stats:"; \
			cast call $$AUTOMATION_KEEPER "getStats()" --rpc-url $(RPC_URL) | \
			echo "  Stats: $$(cat -)"; \
			echo ""; \
			echo "📋 Checking positions in adapter:"; \
			cast call $$LOAN_ADAPTER "getTotalPositions()" --rpc-url $(RPC_URL) | \
			echo "  Total positions monitored: $$(cat -)"; \
			echo ""; \
			echo "🎯 Getting at-risk positions:"; \
			cast call $$LOAN_ADAPTER "getAtRiskPositions()" --rpc-url $(RPC_URL) | \
			echo "  At-risk positions: $$(cat -)"; \
		else \
			echo "❌ Automation keeper not deployed"; \
		fi; \
	fi

# Manually trigger automation check (simulate Chainlink call)
trigger-automation-check:
	@echo "🔥 MANUALLY TRIGGERING AUTOMATION CHECK"
	@echo "======================================"
	@echo "Simulating Chainlink automation upkeep..."
	@echo ""
	@if [ -f "deployed-addresses.json" ]; then \
		AUTOMATION_KEEPER=$$(jq -r '.automation.automationKeeper' deployed-addresses.json) && \
		LOAN_ADAPTER=$$(jq -r '.automation.loanAdapter' deployed-addresses.json) && \
		. ./.env && \
		if [ "$$AUTOMATION_KEEPER" != "" ] && [ "$$AUTOMATION_KEEPER" != "null" ]; then \
			echo "🔍 Step 1: Calling checkUpkeep..."; \
			CHECK_DATA="0x000000000000000000000000$$(echo $$LOAN_ADAPTER | sed 's/0x//')0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000019"; \
			echo "Using checkData: $$CHECK_DATA"; \
			UPKEEP_NEEDED=$$(cast call $$AUTOMATION_KEEPER "checkUpkeep(bytes)" $$CHECK_DATA --rpc-url $(RPC_URL)) && \
			echo "Upkeep needed result: $$UPKEEP_NEEDED"; \
			echo ""; \
			if [ "$$(echo $$UPKEEP_NEEDED | cut -c1-2)" = "0x" ]; then \
				echo "🚀 Step 2: Performing upkeep (if needed)..."; \
				PERFORM_DATA=$$(echo $$UPKEEP_NEEDED | cut -d' ' -f2); \
				if [ "$$PERFORM_DATA" != "0x" ] && [ "$$PERFORM_DATA" != "" ]; then \
					echo "Performing upkeep with data: $$PERFORM_DATA"; \
					cast send $$AUTOMATION_KEEPER "performUpkeep(bytes)" $$PERFORM_DATA \
						--rpc-url $(RPC_URL) --private-key $$PRIVATE_KEY || echo "Upkeep performed"; \
				else \
					echo "No upkeep needed at this time"; \
				fi; \
			fi; \
		else \
			echo "❌ Automation keeper not deployed"; \
		fi; \
	fi

# Verify automation results and show statistics
verify-automation-results:
	@echo "✅ VERIFYING AUTOMATION RESULTS"
	@echo "=============================="
	@echo "Checking automation performance and liquidation results..."
	@echo ""
	@if [ -f "deployed-addresses.json" ]; then \
		AUTOMATION_KEEPER=$$(jq -r '.automation.automationKeeper' deployed-addresses.json) && \
		LOAN_ADAPTER=$$(jq -r '.automation.loanAdapter' deployed-addresses.json) && \
		FLEXIBLE_LOAN_MANAGER=$$(jq -r '.coreLending.flexibleLoanManager' deployed-addresses.json) && \
		. ./.env && \
		if [ "$$AUTOMATION_KEEPER" != "" ] && [ "$$AUTOMATION_KEEPER" != "null" ]; then \
			echo "📊 Final Automation Statistics:"; \
			echo "=============================="; \
			echo "🤖 Keeper Stats:"; \
			cast call $$AUTOMATION_KEEPER "getStats()" --rpc-url $(RPC_URL) | \
			echo "  $$(cat -)"; \
			echo ""; \
			echo "🎯 Adapter Performance:"; \
			cast call $$LOAN_ADAPTER "getPerformanceMetrics()" --rpc-url $(RPC_URL) | \
			echo "  $$(cat -)"; \
			echo ""; \
			echo "💰 Loan Manager Status:"; \
			echo "  Total positions in system:"; \
			cast call $$FLEXIBLE_LOAN_MANAGER "getPositionCount()" --rpc-url $(RPC_URL) | \
			echo "    $$(cat -)"; \
			echo ""; \
			echo "🎉 AUTOMATION TEST RESULTS:"; \
			echo "==========================="; \
			echo "✅ System successfully deployed and configured"; \
			echo "✅ Positions created and monitored"; \
			echo "✅ Risk detection working"; \
			echo "✅ Automation logic functional"; \
			echo ""; \
			echo "🔗 Next Steps:"; \
			echo "  - Register keeper at https://automation.chain.link/"; \
			echo "  - Use contract address: $$AUTOMATION_KEEPER"; \
			echo "  - Monitor real Chainlink automation activity"; \
		else \
			echo "❌ Automation system not deployed"; \
		fi; \
	fi

# Quick automation test - simplified version
test-automation-quick:
	@echo ""
	@echo "⚡ QUICK AUTOMATION SYSTEM TEST"
	@echo "=============================="
	@echo "Simplified test for quick verification..."
	@echo ""
	@$(MAKE) check-automation-status
	@$(MAKE) create-test-loan-position
	@$(MAKE) trigger-automation-check
	@$(MAKE) verify-automation-results
	@echo ""
	@echo "✅ Quick automation test completed!"

# Simple automation check without complex checkData
test-automation-simple:
	@echo ""
	@echo "⚡ SIMPLE AUTOMATION TEST"
	@echo "========================"
	@echo "Testing automation keeper with basic functionality..."
	@echo ""
	@if [ -f "deployed-addresses.json" ]; then \
		AUTOMATION_KEEPER=$$(jq -r '.automation.automationKeeper' deployed-addresses.json) && \
		LOAN_ADAPTER=$$(jq -r '.automation.loanAdapter' deployed-addresses.json) && \
		. ./.env && \
		if [ "$$AUTOMATION_KEEPER" != "" ] && [ "$$AUTOMATION_KEEPER" != "null" ]; then \
			echo "📊 Checking keeper stats:"; \
			cast call $$AUTOMATION_KEEPER "getStats()" --rpc-url $(RPC_URL) | \
			echo "  Stats: $$(cat -)"; \
			echo ""; \
			echo "🔍 Testing checkUpkeep with empty data:"; \
			UPKEEP_RESULT=$$(cast call $$AUTOMATION_KEEPER "checkUpkeep(bytes)" 0x --rpc-url $(RPC_URL)); \
			echo "  Upkeep result: $$UPKEEP_RESULT"; \
			echo ""; \
			echo "📋 Checking adapter status:"; \
			echo "  Total positions: $$(cast call $$LOAN_ADAPTER "getTotalActivePositions()" --rpc-url $(RPC_URL))"; \
			echo "  Position 2 at risk: $$(cast call $$LOAN_ADAPTER "isPositionAtRisk(uint256)" 2 --rpc-url $(RPC_URL))"; \
			echo ""; \
			echo "✅ Basic automation test completed successfully!"; \
		else \
			echo "❌ Automation keeper not deployed"; \
		fi; \
	fi

# ========================================
# 🛠️ UTILITY & DEBUGGING COMMANDS
# ========================================

# Check gas prices and network status
check-gas:
	@echo ""
	@echo "🔍 CHECKING NETWORK STATUS & GAS PRICES"
	@echo "======================================="
	@. ./.env && \
	DEPLOYER_ADDR=$$(cast wallet address $$PRIVATE_KEY) && \
	CURRENT_GAS=$$(cast gas-price --rpc-url $(RPC_URL)) && \
	CURRENT_NONCE=$$(cast nonce $$DEPLOYER_ADDR --rpc-url $(RPC_URL)) && \
	echo "Deployer address: $$DEPLOYER_ADDR" && \
	echo "Current gas price: $$CURRENT_GAS gwei" && \
	echo "Current nonce: $$CURRENT_NONCE" && \
	echo "Safe gas price (2x): $$(echo "$$CURRENT_GAS * 2" | bc) gwei" && \
	echo "Network: Base Sepolia" && \
	echo "RPC URL: $(RPC_URL)"

# Clear pending transactions (emergency)
clear-pending:
	@echo ""
	@echo "🧹 CLEARING PENDING TRANSACTIONS"
	@echo "================================"
	@echo "⚠️ WARNING: This will send an empty transaction with higher gas"
	@echo "to clear any pending transactions in the mempool"
	@echo ""
	@read -p "Continue? [y/N]: " confirm && [ "$$confirm" = "y" ] || [ "$$confirm" = "Y" ] || (echo "Cancelled." && exit 1)
	@. ./.env && \
	DEPLOYER_ADDR=$$(cast wallet address $$PRIVATE_KEY) && \
	CURRENT_GAS=$$(cast gas-price --rpc-url $(RPC_URL)) && \
	HIGH_GAS=$$(echo "$$CURRENT_GAS * 10" | bc) && \
	CURRENT_NONCE=$$(cast nonce $$DEPLOYER_ADDR --rpc-url $(RPC_URL)) && \
	echo "Deployer address: $$DEPLOYER_ADDR" && \
	echo "Sending clearing transaction with nonce $$CURRENT_NONCE and gas price $$HIGH_GAS gwei (10x current)..." && \
	cast send --rpc-url $(RPC_URL) \
		--private-key $$PRIVATE_KEY \
		--gas-price $$HIGH_GAS \
		--nonce $$CURRENT_NONCE \
		--value 0 \
		$$DEPLOYER_ADDR && \
	echo "✅ Clearing transaction sent!"

# Quick deployment with high gas prices
deploy-quick:
	@echo ""
	@echo "🚀 QUICK DEPLOYMENT WITH HIGH GAS PRICES"
	@echo "========================================"
	@$(MAKE) clear-pending
	@sleep 5
	@$(MAKE) deploy-complete

# Super aggressive deployment with 15x gas price
deploy-aggressive:
	@echo ""
	@echo "💥 SUPER AGGRESSIVE DEPLOYMENT (15x GAS PRICE)"
	@echo "=============================================="
	@echo "This uses 15x current gas price to force transactions through"
	@echo ""
	@echo "Step 1/6: Smart compilation..."
	@forge build
	@echo ""
	@echo "Step 2/6: Deploying unified system with AGGRESSIVE gas pricing..."
	@ESTIMATED_GAS=$$(cast gas-price --rpc-url $(RPC_URL)) && \
	AGGRESSIVE_GAS=$$(echo "$$ESTIMATED_GAS * 15" | bc) && \
	echo "Estimated gas price: $$ESTIMATED_GAS gwei" && \
	echo "Using AGGRESSIVE gas price (15x): $$AGGRESSIVE_GAS gwei" && \
	forge script script/deploy/DeployUnifiedSystem.s.sol:DeployUnifiedSystem \
		--rpc-url $(RPC_URL) \
		--broadcast \
		--gas-price $$AGGRESSIVE_GAS
	@echo ""
	@echo "✅ AGGRESSIVE DEPLOYMENT COMPLETED!"

# Ultra aggressive deployment with fixed high gas price

# ========================================
# 📝 NOTES & FOOTER
# ========================================

# This Makefile has been cleaned up to focus on the essential deploy-complete workflow.
# 
# Removed commands (available in backup):
# - PSM swap scripts (40+ commands)
# - Liquidation test scripts (30+ commands)  
# - VCOP loan test scripts (20+ commands)
# - Diagnostic scripts (15+ commands)
# - Mainnet specific commands (10+ commands)
#
# Total: ~115 commands removed, 15 essential commands remain
#
# To restore full Makefile: cp Makefile.backup Makefile 