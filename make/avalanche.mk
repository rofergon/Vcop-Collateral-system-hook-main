# ========================================
# 🏔️ AVALANCHE FUJI MODULE - ENHANCED FOR VCOP DEPLOYMENT
# ========================================

.PHONY: deploy-avalanche-full-stack-mock deploy-avalanche-complete-mock deploy-avalanche-automation \
	deploy-avalanche-complete-mock-high-gas deploy-avalanche-emergency-high-gas \
	check-avalanche-gas check-avalanche-status show-avalanche-info \
	configure-avalanche-vault-automation fix-avalanche-vault-allowances \
	quick-avalanche-system-check test-avalanche-automation test-avalanche-high-gas \
	ensure-avalanche-config switch-to-avalanche switch-to-base verify-avalanche-contracts \
	mint-avalanche-test-tokens create-avalanche-test-loan crash-avalanche-market \
	increase-avalanche-market liquidate-avalanche-position check-avalanche-balances \
	test-avalanche-automation-complete create-avalanche-risky-positions test-avalanche-oracle \
	avalanche-quick-test avalanche-reset-and-test monitor-avalanche-automation help-avalanche-testing \
	deploy-avalanche-automation-complete-mock-no-test

help-avalanche:
	@echo ""
	@echo "🏔️ AVALANCHE FUJI COMMANDS"
	@echo "=========================="
	@echo ""
	@echo "🚀 DEPLOYMENT:"
	@echo "deploy-avalanche-full-stack-mock       - Complete system + automation (2 Gwei)"
	@echo "deploy-avalanche-complete-mock         - Core system only (2 Gwei)"
	@echo "deploy-avalanche-automation            - Automation contracts only (2 Gwei)"
	@echo "deploy-avalanche-complete-mock-high-gas - High gas version (25 Gwei)"
	@echo "deploy-avalanche-emergency-high-gas    - Emergency max gas (300 Gwei)"
	@echo ""
	@echo "🧪 TESTING:"
	@echo "avalanche-quick-test                   - ⭐ Complete test in 3 steps"
	@echo "mint-avalanche-test-tokens             - Mint 100 ETH, 500k USDC, 10 WBTC"
	@echo "create-avalanche-test-loan             - Create test loan position"
	@echo "crash-avalanche-market                 - Crash prices to trigger liquidation"
	@echo "increase-avalanche-market              - Reset market prices upward"
	@echo "liquidate-avalanche-position           - Manually liquidate position"
	@echo "test-avalanche-automation              - Test automation with MockOracle"
	@echo "test-avalanche-automation-complete     - Full automation test sequence"
	@echo "avalanche-reset-and-test               - Reset market and create new position"
	@echo ""
	@echo "🔍 MONITORING:"
	@echo "check-avalanche-balances               - Check your token balances"
	@echo "test-avalanche-oracle                  - Test Oracle functionality"
	@echo "monitor-avalanche-automation           - Show automation dashboard links"
	@echo "check-avalanche-status                 - Check network status"
	@echo "check-avalanche-gas                    - Check current gas prices"
	@echo ""
	@echo "🔧 CONFIGURATION:"
	@echo "configure-avalanche-vault-automation   - Configure vault automation"
	@echo "configure-avalanche-default-risk-thresholds - Configure default risk thresholds"
	@echo "fix-avalanche-vault-allowances         - Fix vault allowances (2 Gwei)"
	@echo "verify-avalanche-contracts             - Verify contracts on Snowtrace"
	@echo "show-avalanche-info                    - Show network information"
	@echo ""
	@echo "🧪 TESTING:"
	@echo "test-avalanche-liquidation-flow        - Test complete liquidation flow with diagnosis"
	@echo ""
	@echo "🔧 CHAINLINK AUTOMATION DIAGNOSIS:"
	@echo "fix-avalanche-automation-complete      - ⭐ COMPLETE automation diagnosis & fix guide"
	@echo "configure-avalanche-automation-complete - Configure LoanManager <-> Adapter integration"
	@echo "sync-avalanche-positions               - Sync new positions to tracking"
	@echo "diagnose-avalanche-chainlink           - Diagnose why automation doesn't execute"
	@echo "test-avalanche-checkupkeep             - Test checkUpkeep manually"
	@echo "generate-avalanche-checkdata           - Generate checkData for Chainlink registration"
	@echo ""
	@echo "💡 WORKFLOWS:"
	@echo "   Complete test: make avalanche-quick-test"
	@echo "   Fix automation: make fix-avalanche-automation-complete"
	@echo "   Debug flow:    make help-avalanche-testing"

# ========================================
# 🚀 COMPLETE AVALANCHE DEPLOYMENT
# ========================================

# Deploy complete Avalanche stack with automation (FULL EQUIVALENT TO BASE SEPOLIA)
deploy-avalanche-full-stack-mock:
	@echo "🏔️ DEPLOYING COMPLETE AVALANCHE STACK WITH AUTOMATION"
	@echo "======================================================"
	@echo "⚠️  Using 25 Gwei gas price (reliable for Avalanche Fuji)"
	@echo ""
	@echo "This will execute the complete 10-phase deployment:"
	@echo "1. Deploy core system (deploy-avalanche-complete-mock)"
	@echo "2. Deploy automation contracts (deploy-avalanche-automation-complete-mock-no-test)"
	@echo "3. Configure vault automation (configure-avalanche-vault-automation)"
	@echo "4. Configure default risk thresholds (configure-avalanche-default-risk-thresholds)"
	@echo "5. Fix vault allowances (fix-avalanche-vault-allowances)"
	@echo "6. Configure automation integration (configure-avalanche-automation-complete)"
	@echo "7. Set automation adapter reference in FlexibleLoanManager"
	@echo "8. Quick system check (quick-avalanche-system-check)"
	@echo "9. Test automation flow (test-avalanche-automation-flow)"
	@echo "10. Test complete liquidation flow (test-avalanche-liquidation-flow)"
	@echo ""
	@echo "📋 Phase 1/10: Deploying core system..."
	@$(MAKE) deploy-avalanche-complete-mock
	@echo ""
	@echo "🤖 Phase 2/10: Deploying automation contracts..."
	@$(MAKE) deploy-avalanche-automation-complete-mock-no-test
	@echo ""
	@echo "🔧 Phase 3/10: Configuring vault automation..."
	@$(MAKE) configure-avalanche-vault-automation
	@echo ""
	@echo "🎯 Phase 4/10: Configuring default risk thresholds..."
	@$(MAKE) configure-avalanche-default-risk-thresholds
	@echo ""
	@echo "🔧 Phase 5/10: Fixing vault allowances..."
	@$(MAKE) fix-avalanche-vault-allowances
	@echo ""
	@echo "🔗 Phase 6/10: Configuring automation integration..."
	@$(MAKE) configure-avalanche-automation-complete
	@echo ""
	@echo "🤖 Phase 7/10: Setting automation adapter reference..."
	@$(MAKE) configure-avalanche-automation-adapter-reference
	@echo ""
	@echo "⚡ Phase 8/10: Quick system check..."
	@$(MAKE) quick-avalanche-system-check
	@echo ""
	@echo "🧪 Phase 9/10: Testing automation flow..."
	@$(MAKE) test-avalanche-automation-flow
	@echo ""
	@echo "🔬 Phase 10/10: Testing complete liquidation flow..."
	@$(MAKE) test-avalanche-liquidation-flow
	@echo ""
	@echo "🎉 COMPLETE AVALANCHE STACK DEPLOYMENT FINISHED!"
	@echo "✅ All systems deployed and configured successfully!"
	@echo "📊 Summary:"
	@echo "   - Core lending system: DEPLOYED"
	@echo "   - Mock oracle: CONFIGURED"
	@echo "   - Asset handlers: CONFIGURED"
	@echo "   - Automation: DEPLOYED & CONFIGURED"
	@echo "   - Risk thresholds: SET TO DEFAULTS (100/95/90)"
	@echo "   - Vault allowances: FIXED"
	@echo "   - Automation adapter: CONFIGURED FOR AUTO-TRACKING"
	@echo "   - System tested: PASSED"
	@echo "   - Liquidation flow: DIAGNOSED & TESTED"
	@echo ""
	@echo "🚀 AVALANCHE FUJI DEPLOYMENT READY FOR USE!"
	@echo "🤖 NEW POSITIONS WILL BE AUTOMATICALLY TRACKED!"
	@echo "Next: make avalanche-quick-test"

# ========================================
# 🔧 AVALANCHE CORE DEPLOYMENT
# ========================================

# Deploy core system on Avalanche Fuji - ORIGINAL VERSION
deploy-avalanche-complete-mock:
	@echo "🏔️ DEPLOYING COMPLETE CORE SYSTEM ON AVALANCHE FUJI"
	@echo "===================================================="
	@echo "⚠️  Using 25 Gwei gas price (reliable for Avalanche Fuji)"
	@echo "📦 Building contracts..."
	@forge build
	@echo ""
	@echo "🚀 Step 1/4: Deploying unified system with Mock Oracle on Avalanche..."
	@. ./.env && forge script script/deploy/DeployUnifiedSystemMock.s.sol:DeployUnifiedSystemMock \
		--rpc-url $$RPC_URL --private-key $$PRIVATE_KEY --broadcast --legacy \
		--gas-price 2000000000 --with-gas-price 2000000000 --slow --timeout 900
	@echo ""
	@echo "⏳ Waiting 10 seconds before oracle configuration..."
	@sleep 10
	@echo ""
	@echo "🔧 Step 2/4: Configuring Mock Oracle with realistic prices..."
	@. ./.env && forge script script/config/ConfigureMockOracle.s.sol:ConfigureMockOracle \
		--rpc-url $$RPC_URL --private-key $$PRIVATE_KEY --broadcast --legacy \
		--gas-price 2000000000 --with-gas-price 2000000000 --slow --timeout 600
	@echo ""
	@echo "⏳ Waiting 10 seconds before price configuration..."
	@sleep 10
	@echo ""
	@echo "💰 Step 3/4: Setting VCOP Price in Mock..."
	@. ./.env && forge script script/config/ConfigureMockVCOPPrice.s.sol:ConfigureMockVCOPPrice \
		--rpc-url $$RPC_URL --private-key $$PRIVATE_KEY --broadcast --legacy \
		--gas-price 2000000000 --with-gas-price 2000000000 --slow --timeout 600
	@echo ""
	@echo "⏳ Waiting 10 seconds before asset handlers configuration..."
	@sleep 10
	@echo ""
	@echo "🔗 Step 4/4: Configuring Avalanche Assets and Liquidity..."
	@. ./.env && forge script script/automation/ConfigureAvalancheAssets.s.sol:ConfigureAvalancheAssets \
		--rpc-url $$RPC_URL --private-key $$PRIVATE_KEY --broadcast --legacy \
		--gas-price 2000000000 --with-gas-price 2000000000 --slow --timeout 600
	@echo ""
	@echo "✅ AVALANCHE COMPLETE CORE DEPLOYMENT FINISHED!"
	@echo "🎯 All contracts deployed and configured automatically"
	@echo "📋 Check deployed-addresses-mock.json for all addresses"

# ========================================
# 🤖 AVALANCHE AUTOMATION DEPLOYMENT
# ========================================

# Deploy automation contracts on Avalanche Fuji
deploy-avalanche-automation:
	@echo "🤖 DEPLOYING CHAINLINK AUTOMATION ON AVALANCHE FUJI"
	@echo "===================================================="
	@echo "⚠️  Using 2 Gwei gas price (optimized for Avalanche Fuji)"
	@echo "🔗 Using official Chainlink Automation Registry for Avalanche Fuji"
	@echo "📦 Building contracts..."
	@forge build
	@echo ""
	@echo "🚀 Deploying automation contracts with official Chainlink addresses..."
	@. ./.env && forge script script/automation/DeployAutomationMock.s.sol:DeployAutomationMock \
		--rpc-url $$RPC_URL --private-key $$PRIVATE_KEY --broadcast --legacy \
		--gas-price 2000000000 --with-gas-price 2000000000 --slow --timeout 600
	@echo ""
	@echo "📝 Updating deployed-addresses-mock.json with automation addresses..."
	@./tools/update-automation-addresses-mock.sh
	@echo ""
	@echo "✅ AVALANCHE AUTOMATION DEPLOYMENT COMPLETED!"
	@echo "🔗 Chainlink Registry: 0x819B58A646CDd8289275A87653a2aA4902b14fe6"
	@echo "📋 Check deployed-addresses-mock.json for automation contract addresses"

# Deploy automation contracts for Avalanche without testing
deploy-avalanche-automation-complete-mock-no-test:
	@echo "🤖 DEPLOYING AUTOMATION FOR AVALANCHE (NO TEST)"
	@echo "================================================"
	@echo "This will deploy automation contracts only (no testing)."
	@echo ""
	@echo "📋 Deploying mock automation contracts on Avalanche..."
	@$(MAKE) deploy-avalanche-automation
	@echo ""
	@echo "✅ AVALANCHE AUTOMATION CONTRACTS DEPLOYED!"
	@echo "Ready for configuration and testing"

# ========================================
# 🔧 AVALANCHE CONFIGURATION
# ========================================

# Ensure proper Avalanche configuration
ensure-avalanche-config:
	@echo "🔧 ENSURING AVALANCHE CONFIGURATION"
	@echo "==================================="
	@if [ ! -f ".env" ]; then \
		echo "❌ .env file not found!"; \
		exit 1; \
	fi
	@. ./.env && if [ "$$CHAIN_ID" != "43113" ]; then \
		echo "❌ Error: CHAIN_ID should be 43113 for Avalanche Fuji"; \
		echo "Current CHAIN_ID: $$CHAIN_ID"; \
		echo "Please run: make switch-to-avalanche"; \
		exit 1; \
	fi
	@echo "✅ Avalanche Fuji configuration verified"

# Configure vault automation for Avalanche
configure-avalanche-vault-automation:
	@echo "🔧 CONFIGURING VAULT AUTOMATION ON AVALANCHE"
	@echo "============================================="
	@echo "⚠️  Using low gas prices (2 Gwei)"
	@. ./.env && forge script script/automation/ConfigureVaultAutomation.s.sol:ConfigureVaultAutomation \
		--rpc-url $$RPC_URL --private-key $$PRIVATE_KEY --broadcast --legacy \
		--gas-price 2000000000 --priority-gas-price 2000000000 --slow --timeout 600
	@echo "✅ Vault automation configured for Avalanche!"

# Configure risk thresholds to default values on Avalanche
configure-avalanche-default-risk-thresholds:
	@echo "🎯 CONFIGURING DEFAULT RISK THRESHOLDS ON AVALANCHE"
	@echo "===================================================="
	@echo "This will set risk thresholds to default values:"
	@echo "   Critical: 100 (immediate liquidation)"
	@echo "   Danger: 95 (high priority liquidation)"
	@echo "   Warning: 90 (regular liquidation)"
	@echo "   MinRiskThreshold: 85 (automation detection)"
	@echo ""
	@echo "⚠️  Using low gas prices (2 Gwei)"
	@. ./.env && forge script script/automation/ConfigureDefaultRiskThresholds.s.sol:ConfigureDefaultRiskThresholds \
		--rpc-url $$RPC_URL --private-key $$PRIVATE_KEY --broadcast --legacy \
		--gas-price 2000000000 --priority-gas-price 2000000000 --slow --timeout 600
	@echo "✅ Default risk thresholds configured for Avalanche!"

# Test complete liquidation flow: create position, crash price, diagnose issues
test-avalanche-liquidation-flow:
	@echo "🧪 TESTING COMPLETE LIQUIDATION FLOW ON AVALANCHE"
	@echo "=================================================="
	@echo "This will:"
	@echo "   1. Create a loan position (1 ETH collateral, 2000 USDC loan)"
	@echo "   2. Crash ETH price by 70%"
	@echo "   3. Diagnose automation system step by step"
	@echo "   4. Fix configuration issues"
	@echo "   5. Verify checkUpkeep works"
	@echo ""
	@echo "⚠️  Using low gas prices (2 Gwei)"
	@. ./.env && forge script script/automation/CreatePositionCrashAndDiagnose.s.sol:CreatePositionCrashAndDiagnose \
		--rpc-url $$RPC_URL --private-key $$PRIVATE_KEY --broadcast --legacy \
		--gas-price 2000000000 --priority-gas-price 2000000000 --slow --timeout 600
	@echo "✅ Liquidation flow test completed!"

# Fix vault allowances for Avalanche
fix-avalanche-vault-allowances:
	@echo "🔧 FIXING VAULT ALLOWANCES ON AVALANCHE"
	@echo "======================================="
	@echo "⚠️  Using low gas prices (2 Gwei)"
	@. ./.env && forge script script/automation/FixVaultAllowancesAvalanche.s.sol:FixVaultAllowancesAvalanche \
		--rpc-url $$RPC_URL --private-key $$PRIVATE_KEY --broadcast --legacy \
		--gas-price 2000000000 --priority-gas-price 2000000000 --slow --timeout 600
	@echo "SUCCESS: Vault allowances fixed for Avalanche!"

# Quick system check for Avalanche
quick-avalanche-system-check:
	@echo "🔍 QUICK AVALANCHE SYSTEM CHECK"
	@echo "==============================="
	@. ./.env && forge script script/CheckMockOracleStatus.s.sol:CheckMockOracleStatus \
		--rpc-url $$RPC_URL --legacy --gas-price 2000000000
	@echo "✅ Avalanche system check completed!"

# ========================================
# 🧪 AVALANCHE TESTING
# ========================================

# Test complete automation flow on Avalanche (EQUIVALENT TO BASE SEPOLIA)
test-avalanche-automation-flow:
	@echo "🧪 TESTING COMPLETE AUTOMATION FLOW ON AVALANCHE"
	@echo "================================================"
	@if [ ! -f "deployed-addresses-mock.json" ]; then \
		echo "❌ Mock system not deployed! Run 'make deploy-avalanche-complete-mock' first"; \
		exit 1; \
	fi
	@AUTOMATION_KEEPER=$$(jq -r '.automation.automationKeeper // ""' deployed-addresses-mock.json) && \
	if [ "$$AUTOMATION_KEEPER" = "" ] || [ "$$AUTOMATION_KEEPER" = "null" ]; then \
		echo "❌ Automation not deployed! Run 'make deploy-avalanche-automation' first"; \
		exit 1; \
	fi
	@echo "Running complete automation test using TestAutomationWithMockOracle..."
	@echo "⚠️  Using low gas prices (2 Gwei)"
	@. ./.env && forge script script/test/TestAutomationWithMockOracle.s.sol:TestAutomationWithMockOracle \
		--rpc-url $$RPC_URL --private-key $$PRIVATE_KEY --broadcast --legacy \
		--gas-price 2000000000 --priority-gas-price 2000000000 --timeout 600
	@echo ""
	@echo "✅ COMPLETE AVALANCHE AUTOMATION FLOW TEST FINISHED!"
	@echo "🎯 Automation system verified and working!"

# Test automation flow on Avalanche (LEGACY NAME FOR COMPATIBILITY)
test-avalanche-automation:
	@echo "🧪 TESTING AUTOMATION FLOW ON AVALANCHE"
	@echo "======================================="
	@if [ ! -f "deployed-addresses-mock.json" ]; then \
		echo "❌ System not deployed! Run 'make deploy-avalanche-full-stack-mock' first"; \
		exit 1; \
	fi
	@echo "Running automation test..."
	@echo "⚠️  Using low gas prices (2 Gwei)"
	@. ./.env && forge script script/test/TestAutomationWithMockOracle.s.sol:TestAutomationWithMockOracle \
		--rpc-url $$RPC_URL --private-key $$PRIVATE_KEY --broadcast --legacy \
		--gas-price 2000000000 --priority-gas-price 2000000000 --timeout 600
	@echo "✅ AVALANCHE AUTOMATION TEST COMPLETED!"

# ========================================
# 🧪 AVALANCHE TESTING COMMANDS
# ========================================

# Mint test tokens for Avalanche (prerequisite for testing)
mint-avalanche-test-tokens:
	@echo "🪙 MINTING TEST TOKENS ON AVALANCHE"
	@echo "=================================="
	@if [ ! -f "deployed-addresses-mock.json" ]; then \
		echo "❌ System not deployed! Run 'make deploy-avalanche-full-stack-mock' first"; \
		exit 1; \
	fi
	@echo "⚠️  Using low gas prices (2 Gwei)"
	@. ./.env && \
	DEPLOYER_ADDR=$$(cast wallet address $$PRIVATE_KEY) && \
	ETH_TOKEN=$$(jq -r '.tokens.mockETH' deployed-addresses-mock.json) && \
	USDC_TOKEN=$$(jq -r '.tokens.mockUSDC' deployed-addresses-mock.json) && \
	WBTC_TOKEN=$$(jq -r '.tokens.mockWBTC' deployed-addresses-mock.json) && \
	echo "Minting to: $$DEPLOYER_ADDR" && \
	echo "ETH Token: $$ETH_TOKEN" && \
	echo "USDC Token: $$USDC_TOKEN" && \
	echo "WBTC Token: $$WBTC_TOKEN" && \
	cast send $$ETH_TOKEN "mint(address,uint256)" $$DEPLOYER_ADDR 2000000000000000000 \
		--rpc-url $$RPC_URL --private-key $$PRIVATE_KEY --legacy \
		--gas-price 2000000000 --priority-gas-price 2000000000 && \
	cast send $$USDC_TOKEN "mint(address,uint256)" $$DEPLOYER_ADDR 500000000000 \
		--rpc-url $$RPC_URL --private-key $$PRIVATE_KEY --legacy \
		--gas-price 2000000000 --priority-gas-price 2000000000 && \
	cast send $$WBTC_TOKEN "mint(address,uint256)" $$DEPLOYER_ADDR 1000000000 \
		--rpc-url $$RPC_URL --private-key $$PRIVATE_KEY --legacy \
		--gas-price 2000000000 --priority-gas-price 2000000000
	@echo "✅ Tokens minted: 100 ETH, 500k USDC, 10 WBTC"

# Create test loan on Avalanche
create-avalanche-test-loan:
	@echo "🧪 CREATING TEST LOAN ON AVALANCHE"
	@echo "================================="
	@if [ ! -f "deployed-addresses-mock.json" ]; then \
		echo "❌ System not deployed! Run 'make deploy-avalanche-full-stack-mock' first"; \
		exit 1; \
	fi
	@echo "First ensuring test tokens are available..."
	@$(MAKE) mint-avalanche-test-tokens
	@echo ""
	@echo "Creating loan position (1 ETH collateral, 1500 USDC loan)..."
	@echo "⚠️  Using low gas prices (2 Gwei)"
	@. ./.env && \
	export LOAN_MANAGER_ADDRESS=$$(jq -r '.coreLending.flexibleLoanManager' deployed-addresses-mock.json) && \
	export COLLATERAL_TOKEN_ADDRESS=$$(jq -r '.tokens.mockETH' deployed-addresses-mock.json) && \
	export LOAN_TOKEN_ADDRESS=$$(jq -r '.tokens.mockUSDC' deployed-addresses-mock.json) && \
	forge script script/test/CreateTestLoanPosition.s.sol \
		--rpc-url $$RPC_URL --private-key $$PRIVATE_KEY --broadcast --legacy \
		--gas-price 2000000000 --priority-gas-price 2000000000 --timeout 600
	@echo "✅ Test loan position created on Avalanche!"

# Crash market prices on Avalanche
crash-avalanche-market:
	@echo "💥 CRASHING MARKET PRICES ON AVALANCHE"
	@echo "====================================="
	@if [ ! -f "deployed-addresses-mock.json" ]; then \
		echo "❌ System not deployed! Run 'make deploy-avalanche-full-stack-mock' first"; \
		exit 1; \
	fi
	@echo "⚠️  Using low gas prices (2 Gwei)"
	@. ./.env && forge script script/test/CrashMarket.s.sol:CrashMarket \
		--rpc-url $$RPC_URL --private-key $$PRIVATE_KEY --broadcast --legacy \
		--gas-price 2000000000 --priority-gas-price 2000000000 --timeout 600
	@echo "✅ Market crashed on Avalanche! Positions should be liquidatable now"

# Increase market prices on Avalanche  
increase-avalanche-market:
	@echo "📈 INCREASING MARKET PRICES ON AVALANCHE"
	@echo "======================================="
	@if [ ! -f "deployed-addresses-mock.json" ]; then \
		echo "❌ System not deployed! Run 'make deploy-avalanche-full-stack-mock' first"; \
		exit 1; \
	fi
	@echo "⚠️  Using low gas prices (2 Gwei)"
	@. ./.env && forge script script/test/IncreaseMarket.s.sol:IncreaseMarket \
		--rpc-url $$RPC_URL --private-key $$PRIVATE_KEY --broadcast --legacy \
		--gas-price 2000000000 --priority-gas-price 2000000000 --timeout 600
	@echo "✅ Market prices increased on Avalanche!"

# Liquidate position on Avalanche
liquidate-avalanche-position:
	@echo "⚡ LIQUIDATING POSITION ON AVALANCHE"
	@echo "=================================="
	@echo "Position ID: $(if $(POSITION_ID),$(POSITION_ID),1)"
	@if [ ! -f "deployed-addresses-mock.json" ]; then \
		echo "❌ System not deployed! Run 'make deploy-avalanche-full-stack-mock' first"; \
		exit 1; \
	fi
	@echo "⚠️  Using low gas prices (2 Gwei)"
	@. ./.env && \
	export LOAN_MANAGER_ADDRESS=$$(jq -r '.coreLending.flexibleLoanManager' deployed-addresses-mock.json) && \
	export FLEXIBLE_ASSET_HANDLER_ADDRESS=$$(jq -r '.coreLending.flexibleAssetHandler' deployed-addresses-mock.json) && \
	export VAULT_BASED_HANDLER_ADDRESS=$$(jq -r '.coreLending.vaultBasedHandler' deployed-addresses-mock.json) && \
	export COLLATERAL_TOKEN_ADDRESS=$$(jq -r '.tokens.mockETH' deployed-addresses-mock.json) && \
	export LOAN_TOKEN_ADDRESS=$$(jq -r '.tokens.mockUSDC' deployed-addresses-mock.json) && \
	export POSITION_ID=$(if $(POSITION_ID),$(POSITION_ID),1) && \
	forge script script/test/LiquidateTestPosition.s.sol \
		--rpc-url $$RPC_URL --private-key $$PRIVATE_KEY --broadcast --legacy \
		--gas-price 2000000000 --priority-gas-price 2000000000 --timeout 600
	@echo "✅ Position liquidated on Avalanche!"

# Check Avalanche token balances
check-avalanche-balances:
	@echo "💰 CHECKING TOKEN BALANCES ON AVALANCHE"
	@echo "======================================="
	@if [ ! -f "deployed-addresses-mock.json" ]; then \
		echo "❌ System not deployed! Run 'make deploy-avalanche-full-stack-mock' first"; \
		exit 1; \
	fi
	@. ./.env && \
	export LOAN_MANAGER_ADDRESS=$$(jq -r '.coreLending.flexibleLoanManager' deployed-addresses-mock.json) && \
	export COLLATERAL_TOKEN_ADDRESS=$$(jq -r '.tokens.mockETH' deployed-addresses-mock.json) && \
	export LOAN_TOKEN_ADDRESS=$$(jq -r '.tokens.mockUSDC' deployed-addresses-mock.json) && \
	forge script script/test/CreateTestLoanPosition.s.sol:CreateTestLoanPosition \
		--sig "checkBalances()" --rpc-url $$RPC_URL --legacy \
		--gas-price 2000000000
	@echo "✅ Balance check completed on Avalanche!"

# Test complete automation flow on Avalanche
test-avalanche-automation-complete:
	@echo "🧪 COMPLETE AVALANCHE AUTOMATION TEST"
	@echo "====================================="
	@if [ ! -f "deployed-addresses-mock.json" ]; then \
		echo "❌ System not deployed! Run 'make deploy-avalanche-full-stack-mock' first"; \
		exit 1; \
	fi
	@echo "Running complete automation test using TestAutomationWithMockOracle..."
	@echo "⚠️  Using low gas prices (2 Gwei)"
	@. ./.env && forge script script/test/TestAutomationWithMockOracle.s.sol:TestAutomationWithMockOracle \
		--rpc-url $$RPC_URL --private-key $$PRIVATE_KEY --broadcast --legacy \
		--gas-price 2000000000 --priority-gas-price 2000000000 --timeout 600
	@echo ""
	@echo "✅ COMPLETE AVALANCHE AUTOMATION TEST FINISHED!"
	@echo "🎯 Check Chainlink dashboard for automation results:"
	@echo "   https://automation.chain.link/avalanche-fuji"

# Create multiple risky positions for testing
create-avalanche-risky-positions:
	@echo "🧪 CREATING RISKY POSITIONS ON AVALANCHE"
	@echo "======================================="
	@if [ ! -f "deployed-addresses-mock.json" ]; then \
		echo "❌ System not deployed! Run 'make deploy-avalanche-full-stack-mock' first"; \
		exit 1; \
	fi
	@echo "Creating multiple at-risk positions for automation testing..."
	@echo "⚠️  Using low gas prices (2 Gwei)"
	@. ./.env && forge script script/automation/CreatePositionsAndCrash.s.sol:CreatePositionsAndCrash \
		--rpc-url $$RPC_URL --private-key $$PRIVATE_KEY --broadcast --legacy \
		--gas-price 2000000000 --priority-gas-price 2000000000 --timeout 600
	@echo "✅ Risky positions created on Avalanche!"

# Test Oracle functionality on Avalanche
test-avalanche-oracle:
	@echo "🔍 TESTING ORACLE ON AVALANCHE"
	@echo "============================="
	@if [ ! -f "deployed-addresses-mock.json" ]; then \
		echo "❌ System not deployed! Run 'make deploy-avalanche-full-stack-mock' first"; \
		exit 1; \
	fi
	@. ./.env && forge script script/CheckMockOracleStatus.s.sol:CheckMockOracleStatus \
		--rpc-url $$RPC_URL --legacy --gas-price 2000000000
	@echo "✅ Oracle test completed on Avalanche!"

# ========================================
# 🎯 AVALANCHE QUICK TEST COMBINATIONS
# ========================================

# Quick end-to-end test
avalanche-quick-test:
	@echo "⚡ QUICK AVALANCHE TEST"
	@echo "======================"
	@echo "This will create a position and immediately test liquidation"
	@$(MAKE) mint-avalanche-test-tokens
	@$(MAKE) create-avalanche-test-loan  
	@$(MAKE) crash-avalanche-market
	@echo "✅ Quick test completed! Check automation dashboard for results"

# Reset market and create fresh position
avalanche-reset-and-test:
	@echo "🔄 RESETTING AVALANCHE MARKET AND TESTING"
	@echo "========================================="
	@$(MAKE) increase-avalanche-market
	@$(MAKE) mint-avalanche-test-tokens
	@$(MAKE) create-avalanche-test-loan
	@echo "✅ Market reset and new position created"
	@echo "💡 Run 'make crash-avalanche-market' to trigger liquidation"

# ========================================
# 🔍 AVALANCHE MONITORING COMMANDS  
# ========================================

# Monitor Avalanche automation status
monitor-avalanche-automation:
	@echo "📊 MONITORING AVALANCHE AUTOMATION"
	@echo "=================================="
	@if [ ! -f "deployed-addresses-mock.json" ]; then \
		echo "❌ System not deployed!"; \
		exit 1; \
	fi
	@echo "🔗 Automation addresses:"
	@jq '.automation' deployed-addresses-mock.json
	@echo ""
	@echo "🌐 Dashboards:"
	@echo "   Chainlink: https://automation.chain.link/avalanche-fuji"
	@echo "   Snowtrace: https://testnet.snowtrace.io"
	@echo ""
	@echo "📋 Contract links:"
	@KEEPER=$$(jq -r '.automation.automationKeeper' deployed-addresses-mock.json) && \
	echo "   Keeper: https://testnet.snowtrace.io/address/$$KEEPER"
	@ADAPTER=$$(jq -r '.automation.loanAdapter' deployed-addresses-mock.json) && \
	echo "   Adapter: https://testnet.snowtrace.io/address/$$ADAPTER"

# Show Avalanche testing help
# ========================================
# 🔧 AVALANCHE CHAINLINK AUTOMATION DIAGNOSIS
# ========================================

# Diagnose why Chainlink Automation is not executing performUpkeep
diagnose-avalanche-chainlink:
	@echo "🔧 DIAGNOSING CHAINLINK AUTOMATION ISSUES"
	@echo "=========================================="
	@echo "This will check why Chainlink nodes are not executing performUpkeep automatically"
	@echo ""
	@. ./.env && forge script script/automation/DiagnoseAndFixChainlinkAutomation.s.sol:DiagnoseAndFixChainlinkAutomation \
		--rpc-url $$RPC_URL --legacy --gas-price 2000000000
	@echo ""
	@echo "✅ DIAGNOSIS COMPLETED!"
	@echo "📋 Follow the step-by-step solutions shown above"

# Diagnose VaultBasedHandler authorization issues preventing liquidations
diagnose-avalanche-vault-auth:
	@echo "🔍 DIAGNOSING VAULT AUTHORIZATION ISSUES"
	@echo "========================================"
	@echo "This will check why automated liquidations are failing with 'Unauthorized automation' errors"
	@echo ""
	@. ./.env && forge script script/automation/DiagnoseVaultAuthorizations.s.sol:DiagnoseVaultAuthorizations \
		--rpc-url $$RPC_URL --legacy --gas-price 2000000000
	@echo ""
	@echo "✅ VAULT AUTHORIZATION DIAGNOSIS COMPLETED!"
	@echo "📋 Check the authorization status and required fixes shown above"

# Fix VaultBasedHandler authorization issues preventing automated liquidations
fix-avalanche-vault-auth:
	@echo "🔧 FIXING VAULT AUTHORIZATION ISSUES"
	@echo "===================================="
	@echo "This will fix all authorization issues preventing automated liquidations"
	@echo ""
	@. ./.env && forge script script/automation/FixVaultAuthorizations.s.sol:FixVaultAuthorizations \
		--rpc-url $$RPC_URL --private-key $$PRIVATE_KEY --broadcast --legacy \
		--gas-price 25000000000 --priority-gas-price 25000000000
	@echo ""
	@echo "✅ VAULT AUTHORIZATION FIXES COMPLETED!"
	@echo "🎯 Test automated liquidations with: make crash-avalanche-market"

# Fix specific VaultBasedHandler authorization for FlexibleLoanManager
fix-avalanche-vaulthandler-auth:
	@echo "🔧 FIXING VAULTBASEDHANDLER AUTHORIZATION"
	@echo "========================================"
	@echo "This will specifically authorize FlexibleLoanManager in VaultBasedHandler"
	@echo ""
	@. ./.env && forge script script/automation/FixVaultBasedHandlerAuth.s.sol:FixVaultBasedHandlerAuth \
		--rpc-url $$RPC_URL --private-key $$PRIVATE_KEY --broadcast --legacy \
		--gas-price 25000000000 --priority-gas-price 25000000000
	@echo ""
	@echo "✅ VAULTBASEDHANDLER AUTHORIZATION FIXED!"
	@echo "🎯 Test automated liquidations with: make crash-avalanche-market"

# Diagnose why liquidations are not executing despite successful automation
diagnose-avalanche-liquidation-issues:
	@echo "🔍 DIAGNOSING LIQUIDATION ISSUES"
	@echo "================================"
	@echo "This will diagnose why liquidations are not executing despite successful automation"
	@echo ""
	@. ./.env && forge script script/automation/DiagnoseLiquidationIssues.s.sol:DiagnoseLiquidationIssues \
		--rpc-url $$RPC_URL --legacy --gas-price 2000000000
	@echo ""
	@echo "✅ LIQUIDATION DIAGNOSIS COMPLETED!"

# Diagnose why ETH collateral positions are not being liquidated
diagnose-avalanche-eth-liquidation:
	@echo "🔍 DIAGNOSING ETH LIQUIDATION ISSUES"
	@echo "===================================="
	@echo "This will diagnose why ETH collateral positions are not being liquidated automatically"
	@echo ""
	@. ./.env && forge script script/automation/DiagnoseETHLiquidationIssues.s.sol:DiagnoseETHLiquidationIssues \
		--rpc-url $$RPC_URL --legacy --gas-price 2000000000
	@echo ""
	@echo "✅ ETH LIQUIDATION DIAGNOSIS COMPLETED!"

# Test manual ETH liquidation to identify automation issues
test-avalanche-eth-liquidation:
	@echo "🧪 TESTING ETH LIQUIDATION MANUALLY"
	@echo "==================================="
	@echo "This will test manual liquidation of ETH positions to identify automation issues"
	@echo ""
	@. ./.env && forge script script/automation/TestETHLiquidation.s.sol:TestETHLiquidation \
		--rpc-url $$RPC_URL --private-key $$PRIVATE_KEY --broadcast --legacy \
		--gas-price 25000000000 --priority-gas-price 25000000000
	@echo ""
	@echo "✅ ETH LIQUIDATION TEST COMPLETED!"

# Configure ETH in FlexibleAssetHandler to enable automated ETH liquidations
configure-avalanche-eth-handler:
	@echo "🔧 CONFIGURING ETH IN FLEXIBLEASSETHANDLER"
	@echo "=========================================="
	@echo "This will configure ETH to enable automated ETH liquidations"
	@echo ""
	@. ./.env && forge script script/automation/ConfigureETHInFlexibleHandler.s.sol:ConfigureETHInFlexibleHandler \
		--rpc-url $$RPC_URL --private-key $$PRIVATE_KEY --broadcast --legacy \
		--gas-price 25000000000 --priority-gas-price 25000000000
	@echo ""
	@echo "✅ ETH CONFIGURATION COMPLETED!"
	@echo "🎯 ETH liquidations should now work automatically!"

# Add USDC liquidity to VaultBasedHandler for automated liquidations
add-avalanche-vault-liquidity:
	@echo "💰 ADDING VAULT LIQUIDITY FOR AUTOMATED LIQUIDATIONS"
	@echo "===================================================="
	@echo "This will add 20,000 USDC liquidity to enable automated liquidations"
	@echo ""
	@. ./.env && forge script script/automation/AddVaultLiquidity.s.sol:AddVaultLiquidity \
		--rpc-url $$RPC_URL --private-key $$PRIVATE_KEY --broadcast --legacy \
		--gas-price 25000000000 --priority-gas-price 25000000000
	@echo ""
	@echo "✅ VAULT LIQUIDITY ADDED!"
	@echo "🎯 Automated liquidations should now work!"

# Mint USDC and add liquidity to VaultBasedHandler (simpler approach)
mint-and-add-avalanche-liquidity:
	@echo "💰 MINTING USDC AND ADDING VAULT LIQUIDITY"
	@echo "=========================================="
	@echo "This will mint 20,000 USDC and add it as vault liquidity"
	@echo ""
	@. ./.env && forge script script/automation/MintAndAddLiquidity.s.sol:MintAndAddLiquidity \
		--rpc-url $$RPC_URL --private-key $$PRIVATE_KEY --broadcast --legacy \
		--gas-price 25000000000 --priority-gas-price 25000000000
	@echo ""
	@echo "✅ USDC MINTED AND VAULT LIQUIDITY ADDED!"
	@echo "🎯 Automated liquidations should now work!"

# Test checkUpkeep manually with your deployed contracts
test-avalanche-checkupkeep:
	@echo "🧪 TESTING CHECKUPKEEP MANUALLY"
	@echo "==============================="
	@if [ ! -f "deployed-addresses-mock.json" ]; then \
		echo "❌ deployed-addresses-mock.json not found!"; \
		echo "   Run: make deploy-avalanche-full-stack-mock"; \
		exit 1; \
	fi
	@AUTOMATION_KEEPER=$$(jq -r '.automation.automationKeeper // ""' deployed-addresses-mock.json) && \
	LOAN_ADAPTER=$$(jq -r '.automation.loanAdapter // ""' deployed-addresses-mock.json) && \
	if [ "$$AUTOMATION_KEEPER" = "" ] || [ "$$AUTOMATION_KEEPER" = "null" ]; then \
		echo "❌ Automation contracts not found in deployed-addresses-mock.json"; \
		echo "   Run: make deploy-avalanche-automation"; \
		exit 1; \
	fi && \
	echo "Testing with:" && \
	echo "  AutomationKeeper: $$AUTOMATION_KEEPER" && \
	echo "  LoanAdapter: $$LOAN_ADAPTER" && \
	echo "" && \
	. ./.env && forge script script/automation/DiagnoseAndFixChainlinkAutomation.s.sol:DiagnoseAndFixChainlinkAutomation \
		--sig "testCheckUpkeepManual(address,address)" $$AUTOMATION_KEEPER $$LOAN_ADAPTER \
		--rpc-url $$RPC_URL --legacy --gas-price 2000000000
	@echo "✅ CHECKUPKEEP TEST COMPLETED!"

# Generate checkData for Chainlink registration
generate-avalanche-checkdata:
	@echo "📝 GENERATING CHECKDATA FOR CHAINLINK REGISTRATION"
	@echo "=================================================="
	@if [ ! -f "deployed-addresses-mock.json" ]; then \
		echo "❌ deployed-addresses-mock.json not found!"; \
		echo "   Run: make deploy-avalanche-full-stack-mock"; \
		exit 1; \
	fi
	@LOAN_ADAPTER=$$(jq -r '.automation.loanAdapter // ""' deployed-addresses-mock.json) && \
	if [ "$$LOAN_ADAPTER" = "" ] || [ "$$LOAN_ADAPTER" = "null" ]; then \
		echo "❌ LoanAdapter not found in deployed-addresses-mock.json"; \
		echo "   Run: make deploy-avalanche-automation"; \
		exit 1; \
	fi && \
	echo "Generating checkData for LoanAdapter: $$LOAN_ADAPTER" && \
	echo "" && \
	. ./.env && forge script -vvv script/automation/DiagnoseAndFixChainlinkAutomation.s.sol:DiagnoseAndFixChainlinkAutomation \
		--sig "_generateCheckData()" --rpc-url $$RPC_URL --legacy
	@echo ""
	@echo "✅ COPY THE CHECKDATA HEX ABOVE FOR CHAINLINK REGISTRATION!"
	@echo "🌐 Register at: https://automation.chain.link/avalanche-fuji"

# Sync new positions that are not yet tracked
sync-avalanche-positions:
	@echo "🔄 SYNCING NEW POSITIONS TO TRACKING"
	@echo "===================================="
	@echo "This will find and add any new positions that are not yet tracked"
	@echo ""
	@. ./.env && forge script script/automation/SyncNewPositions.s.sol:SyncNewPositions \
		--rpc-url $$RPC_URL --private-key $$PRIVATE_KEY --broadcast --legacy \
		--gas-price 25000000000 --priority-gas-price 25000000000
	@echo ""
	@echo "✅ POSITION SYNC COMPLETED!"
	@echo "💡 Run this command after creating new loan positions"

# Configure complete loan manager adapter integration
configure-avalanche-automation-complete:
	@echo "🔧 CONFIGURING COMPLETE AUTOMATION INTEGRATION"
	@echo "=============================================="
	@echo "This will configure the LoanManager <-> Adapter integration"
	@echo ""
	@. ./.env && forge script script/automation/ConfigureLoanManagerAdapter.s.sol:ConfigureLoanManagerAdapter \
		--rpc-url $$RPC_URL --private-key $$PRIVATE_KEY --broadcast --legacy \
		--gas-price 25000000000 --priority-gas-price 25000000000
	@echo ""
	@echo "✅ AUTOMATION INTEGRATION CONFIGURED!"

# Configure automation adapter reference in FlexibleLoanManager for automatic tracking
configure-avalanche-automation-adapter-reference:
	@echo "🤖 CONFIGURING AUTOMATION ADAPTER REFERENCE"
	@echo "==========================================="
	@echo "This will set the adapter reference in FlexibleLoanManager for automatic position tracking"
	@echo ""
	@. ./.env && forge script script/automation/SetAutomationAdapterReference.s.sol:SetAutomationAdapterReference \
		--rpc-url $$RPC_URL --private-key $$PRIVATE_KEY --broadcast --legacy \
		--gas-price 25000000000 --priority-gas-price 25000000000
	@echo ""
	@echo "✅ AUTOMATION ADAPTER REFERENCE CONFIGURED!"
	@echo "🎯 NEW POSITIONS WILL BE AUTOMATICALLY TRACKED!"

# Complete automation diagnosis and setup guide
fix-avalanche-automation-complete:
	@echo "🚀 COMPLETE AUTOMATION DIAGNOSIS AND FIX"
	@echo "========================================"
	@echo "This will run a complete diagnosis and give you step-by-step instructions"
	@echo ""
	@echo "PHASE 1: Checking system status..."
	@$(MAKE) diagnose-avalanche-chainlink
	@echo ""
	@echo "PHASE 2: Testing checkUpkeep manually..."
	@$(MAKE) test-avalanche-checkupkeep
	@echo ""
	@echo "PHASE 3: Generating checkData for registration..."
	@$(MAKE) generate-avalanche-checkdata
	@echo ""
	@echo "==========================================";
	@echo "🎯 SUMMARY OF NEXT STEPS:"
	@echo "==========================================";
	@echo ""
	@echo "If checkUpkeep works but automation doesn't execute:"
	@echo "1. Your contracts are correctly configured ✅"
	@echo "2. The problem is Chainlink registration/funding ❌"
	@echo ""
	@echo "SOLUTION:"
	@echo "--------"
	@echo "1. Go to: https://automation.chain.link/avalanche-fuji"
	@echo "2. Register new upkeep with the checkData generated above"
	@echo "3. Fund with 5-10 LINK tokens from https://faucets.chain.link/fuji"
	@echo "4. Wait 1-2 minutes and test with: make crash-avalanche-market"
	@echo ""
	@echo "If checkUpkeep doesn't work:"
	@echo "1. Run: make configure-avalanche-vault-automation"
	@echo "2. Run: make configure-avalanche-default-risk-thresholds"
	@echo "3. Run: make create-avalanche-test-loan"
	@echo "4. Run: make crash-avalanche-market"
	@echo "5. Try again: make test-avalanche-checkupkeep"
	@echo ""
	@echo "🔗 Useful links:"
	@echo "  Dashboard: https://automation.chain.link/avalanche-fuji"
	@echo "  LINK Faucet: https://faucets.chain.link/fuji"
	@echo "  Docs: https://docs.chain.link/chainlink-automation"

help-avalanche-testing:
	@echo ""
	@echo "🏔️ AVALANCHE TESTING COMMANDS"
	@echo "=============================="
	@echo ""
	@echo "🎯 QUICK TESTS:"
	@echo "avalanche-quick-test                    - Complete test in 3 steps"
	@echo "avalanche-reset-and-test                - Reset market and create new position"
	@echo ""
	@echo "🧪 INDIVIDUAL TESTS:"
	@echo "mint-avalanche-test-tokens              - Mint tokens for testing"
	@echo "create-avalanche-test-loan              - Create test loan position"
	@echo "crash-avalanche-market                  - Crash prices by 50%"
	@echo "increase-avalanche-market               - Increase prices by 50%"
	@echo "liquidate-avalanche-position            - Manually liquidate position"
	@echo "check-avalanche-balances                - Check token balances"
	@echo ""
	@echo "🤖 AUTOMATION TESTS:"
	@echo "test-avalanche-automation               - Test automation with MockOracle"
	@echo "test-avalanche-automation-complete      - Full automation test sequence"
	@echo "create-avalanche-risky-positions        - Create multiple risky positions"
	@echo ""
	@echo "🔍 MONITORING:"
	@echo "monitor-avalanche-automation            - Show automation status & links"
	@echo "test-avalanche-oracle                   - Test Oracle functionality"
	@echo ""
	@echo "💡 TYPICAL WORKFLOW:"
	@echo "1. make avalanche-quick-test            - Create position & crash market"
	@echo "2. make monitor-avalanche-automation    - Check automation dashboard"
	@echo "3. make avalanche-reset-and-test        - Reset for next test"
	@echo ""
	@echo "⚠️  All commands use 2 Gwei gas for Avalanche Fuji"
	@echo "🔗 Automation Dashboard: https://automation.chain.link/avalanche-fuji"

# ========================================
# 🆘 EMERGENCY HIGH GAS COMMANDS
# ========================================

# Emergency deployment with VERY high gas (use if everything else fails)
deploy-avalanche-emergency-high-gas:
	@echo "🆘 EMERGENCY DEPLOYMENT WITH MAXIMUM GAS (300 Gwei)"
	@echo "=================================================="
	@echo "⚠️  WARNING: This uses 300 Gwei gas prices - VERY EXPENSIVE!"
	@echo "💰 Make sure you have enough AVAX in your wallet"
	@echo ""
	@read -p "Continue with MAXIMUM gas deployment? (y/N): " confirm && [ "$$confirm" = "y" ] || exit 1
	@echo ""
	@echo "📦 Building contracts..."
	@forge build
	@echo ""
	@echo "🚀 Deploying with MAXIMUM GAS..."
	@. ./.env && forge script script/deploy/DeployUnifiedSystemMock.s.sol:DeployUnifiedSystemMock \
		--rpc-url $$RPC_URL --private-key $$PRIVATE_KEY --broadcast --legacy \
		--gas-price 200000000000 --priority-gas-price 200000000000 --slow --timeout 1200
	@echo "✅ EMERGENCY DEPLOYMENT COMPLETED!"

# Check current gas prices on Avalanche
check-avalanche-gas:
	@echo "⚡ CHECKING CURRENT AVALANCHE FUJI GAS PRICES"
	@echo "============================================="
	@echo "🔍 Fetching current gas prices..."
	@curl -s "https://api.avax-test.network/ext/bc/C/rpc" \
		-X POST \
		-H "Content-Type: application/json" \
		-d '{"jsonrpc":"2.0","method":"eth_gasPrice","params":[],"id":1}' \
		| jq -r '.result' \
		| xargs -I {} echo "Current gas price: {} wei" \
		| sed 's/0x//' \
		| xargs -I {} echo "ibase=16; {}" \
		| bc \
		| xargs -I {} echo "Current gas price: {} wei ({} Gwei)" \
		| sed 's/wei.*/wei/' \
		| xargs -I {} echo "{} = $$(echo "scale=2; {}/1000000000" | bc) Gwei"
	@echo ""
	@echo "📊 RECOMMENDED GAS PRICES FOR AVALANCHE FUJI:"
	@echo "   Normal:    50-100 Gwei"
	@echo "   Fast:      100-200 Gwei"
	@echo "   Emergency: 200-300 Gwei"

# Check system status on Avalanche
check-avalanche-status:
	@echo "🔍 AVALANCHE SYSTEM STATUS"
	@echo "=========================="
	@echo "🏔️ Network: Avalanche Fuji Testnet"
	@echo "⛽ Chain ID: 43113"
	@echo "🔗 RPC: https://api.avax-test.network/ext/bc/C/rpc"
	@echo "🌐 Explorer: https://testnet.snowtrace.io"
	@echo ""
	@echo "🔗 CHAINLINK AUTOMATION (Avalanche Fuji):"
	@echo "   Registry:  0x819B58A646CDd8289275A87653a2aA4902b14fe6"
	@echo "   Registrar: 0xD23D3D1b81711D75E1012211f1b65Cc7dBB474e2"
	@echo "   LINK:      0x0b9d5D9136855f6FEc3c0993feE6E9CE8a297846"
	@echo ""
	@echo "💰 FAUCETS:"
	@echo "   AVAX: https://faucet.avax.network/"
	@echo "   LINK: https://faucets.chain.link/fuji"
	@echo ""
	@echo "🎯 AUTOMATION DASHBOARD:"
	@echo "   https://automation.chain.link/avalanche-fuji"
	@if [ -f "deployed-addresses-mock.json" ]; then \
		echo ""; \
		echo "📋 DEPLOYED CONTRACTS:"; \
		echo "   Check deployed-addresses-mock.json for addresses"; \
	else \
		echo ""; \
		echo "❌ No deployment found. Run: make deploy-avalanche-full-stack-mock"; \
	fi

# ========================================
# 🔄 NETWORK SWITCHING
# ========================================

# Switch to Avalanche configuration
switch-to-avalanche:
	@echo "🔄 SWITCHING TO AVALANCHE FUJI"
	@echo "=============================="
	@if [ ! -f ".env" ]; then \
		echo "❌ .env file not found!"; \
		exit 1; \
	fi
	@echo "✅ Already configured for Avalanche Fuji"
	@echo "Current configuration:"
	@echo "   Chain ID: 43113"
	@echo "   RPC: https://api.avax-test.network/ext/bc/C/rpc"
	@echo "   Explorer: https://testnet.snowtrace.io"

# Switch back to Base Sepolia
switch-to-base:
	@echo "🔄 SWITCHING TO BASE SEPOLIA"
	@echo "============================"
	@echo "⚠️  This would require a different .env file"
	@echo "   The current .env is configured for Avalanche Fuji"
	@echo "   To use Base Sepolia, you would need to:"
	@echo "   1. Backup current .env: cp .env .env.avalanche"
	@echo "   2. Create .env.base with Base Sepolia config"
	@echo "   3. Copy .env.base to .env"

# ========================================
# 📋 INFORMATION & VERIFICATION
# ========================================

# Show Avalanche network information
show-avalanche-info:
	@echo ""
	@echo "🏔️ AVALANCHE FUJI TESTNET INFORMATION"
	@echo "====================================="
	@echo ""
	@echo "🌐 NETWORK DETAILS:"
	@echo "   Name: Avalanche Fuji Testnet"
	@echo "   Chain ID: 43113"
	@echo "   Currency: AVAX"
	@echo "   RPC URL: https://api.avax-test.network/ext/bc/C/rpc"
	@echo "   Explorer: https://testnet.snowtrace.io"
	@echo ""
	@echo "💰 FAUCETS (Get test tokens):"
	@echo "   AVAX Faucet: https://faucet.avax.network/"
	@echo "   LINK Faucet: https://faucets.chain.link/fuji"
	@echo ""
	@echo "🔗 CHAINLINK AUTOMATION:"
	@echo "   Dashboard: https://automation.chain.link/avalanche-fuji"
	@echo "   Registry: 0x819B58A646CDd8289275A87653a2aA4902b14fe6"
	@echo "   Registrar: 0xD23D3D1b81711D75E1012211f1b65Cc7dBB474e2"
	@echo "   LINK Token: 0x0b9d5D9136855f6FEc3c0993feE6E9CE8a297846"
	@echo ""
	@echo "⚙️ RECOMMENDED GAS SETTINGS:"
	@echo "   Gas Price: 25-50 Gwei (AUTO recommended)"
	@echo "   Gas Limit: 3,000,000 for deployments"
	@echo ""
	@echo "🚀 DEPLOYMENT COMMANDS:"
	@echo "   Full Stack: make deploy-avalanche-full-stack-mock"
	@echo "   Core Only:  make deploy-avalanche-complete-mock"
	@echo "   Status:     make check-avalanche-status"

# Verify contracts on Avalanche Fuji
verify-avalanche-contracts:
	@echo "🔍 VERIFYING CONTRACTS ON AVALANCHE FUJI"
	@echo "========================================"
	@echo "Using Snowtrace API for verification..."
	@if [ ! -f "deployed-addresses-mock.json" ]; then \
		echo "❌ No deployment found! Deploy contracts first."; \
		exit 1; \
	fi
	@echo "📋 Running verification script..."
	@CHAIN_ID=43113 EXPLORER_API_KEY=$$SNOWTRACE_API_KEY ./tools/verify-all-contracts-fixed.sh
	@echo "✅ Contract verification completed!"
	@echo "🌐 View verified contracts at: https://testnet.snowtrace.io" 