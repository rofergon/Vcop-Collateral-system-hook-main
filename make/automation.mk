# ========================================
# 🤖 AUTOMATION MODULE - ENHANCED
# ========================================

.PHONY: deploy-automation deploy-automation-mock help-automation \
	setup-chainlink-automation register-chainlink-upkeep configure-forwarder \
	deploy-automation-complete deploy-automation-complete-mock deploy-automation-complete-mock-no-test \
	check-chainlink-status update-forwarder-env configure-vault-automation

help-automation:
	@echo ""
	@echo "🤖 AUTOMATION COMMANDS - ENHANCED"
	@echo "=================================="
	@echo "🚀 COMPLETE FLOWS:"
	@echo "deploy-automation-complete      - Complete Chainlink automation setup"
	@echo "deploy-automation-complete-mock - Complete mock automation setup"
	@echo ""
	@echo "🔧 STEP-BY-STEP DEPLOYMENT:"
	@echo "deploy-automation               - Deploy automation contracts only"
	@echo "deploy-automation-mock          - Deploy automation for mock system"
	@echo "setup-chainlink-automation      - Setup environment for Chainlink"
	@echo "register-chainlink-upkeep       - Register upkeep with official Chainlink"
	@echo "update-forwarder-env            - Update .env with Forwarder address"
	@echo "configure-forwarder             - Configure Forwarder security"
	@echo ""
	@echo "🔍 STATUS & VERIFICATION:"
	@echo "check-automation-status         - Check deployment status"
	@echo "check-chainlink-status          - Check Chainlink upkeep status"
	@echo "test-automation-flow            - Test complete automation flow"
	@echo "test-automation-quick           - Quick automation check"
	@echo "configure-vault-automation      - Configure vault-funded liquidation"
	@echo "test-vault-liquidation          - Test vault-funded liquidation system"
	@echo ""

# ========================================
# 🚀 COMPLETE AUTOMATION FLOWS
# ========================================

# Complete Chainlink Automation setup (PRODUCTION)
deploy-automation-complete:
	@echo "🚀 COMPLETE CHAINLINK AUTOMATION DEPLOYMENT"
	@echo "============================================"
	@echo ""
	@echo "This will:"
	@echo "1. Deploy your automation contracts"
	@echo "2. Setup Chainlink environment"
	@echo "3. Register upkeep with official Chainlink Registry"
	@echo "4. Configure Forwarder security"
	@echo ""
	@read -p "Continue? (y/N): " confirm && [ "$$confirm" = "y" ] || exit 1
	@echo ""
	@echo "📋 Step 1/4: Deploying automation contracts..."
	@$(MAKE) deploy-automation
	@echo ""
	@echo "🔧 Step 2/4: Setting up Chainlink environment..."
	@$(MAKE) setup-chainlink-automation
	@echo ""
	@echo "⚠️  MANUAL STEP REQUIRED:"
	@echo "Before continuing, ensure you have at least 5 LINK tokens."
	@echo "Get them from: https://faucets.chain.link/ (Base Sepolia)"
	@echo ""
	@read -p "Do you have 5+ LINK tokens? (y/N): " haslink && [ "$$haslink" = "y" ] || exit 1
	@echo ""
	@echo "🔗 Step 3/4: Registering upkeep with Chainlink..."
	@$(MAKE) register-chainlink-upkeep
	@echo ""
	@echo "🛡️  Step 4/4: Configuring Forwarder security..."
	@echo "⚠️  IMPORTANT: Update .env with the Forwarder address from above"
	@echo ""
	@echo "Option 1: Use the helper script (recommended)"
	@echo "   ./update-env-forwarder.sh"
	@echo ""
	@echo "Option 2: Manually add to .env:"
	@echo "   CHAINLINK_FORWARDER_ADDRESS=0x[your_forwarder_address]"
	@echo ""
	@read -p "Continue to run update-env-forwarder.sh? (y/N): " update_env && \
	if [ "$$update_env" = "y" ]; then \
		./update-env-forwarder.sh; \
	else \
		echo "Please update .env manually with the Forwarder address"; \
		read -p "Press Enter after updating .env..."; \
	fi
	@$(MAKE) configure-forwarder
	@echo ""
	@echo "🎉 COMPLETE AUTOMATION SETUP FINISHED!"
	@echo "✅ Your system is now fully automated with Chainlink"
	@echo "🌐 Monitor at: https://automation.chain.link/"

# Complete Mock Automation setup (TESTING)
deploy-automation-complete-mock:
	@echo "🧪 COMPLETE MOCK AUTOMATION DEPLOYMENT"
	@echo "======================================"
	@echo ""
	@echo "This will deploy automation for testing with mock oracle."
	@echo ""
	@echo "📋 Step 1/2: Deploying mock automation contracts..."
	@$(MAKE) deploy-automation-mock
	@echo ""
	@echo "🧪 Step 2/2: Testing automation flow..."
	@$(MAKE) test-automation-flow
	@echo ""
	@echo "🎉 MOCK AUTOMATION SETUP COMPLETE!"
	@echo "✅ Ready for testing liquidations"

# Deploy automation without testing (for full-stack deployment)
deploy-automation-complete-mock-no-test:
	@echo "🧪 DEPLOYING MOCK AUTOMATION (NO TEST)"
	@echo "======================================"
	@echo ""
	@echo "This will deploy automation contracts only (no testing)."
	@echo ""
	@echo "📋 Deploying mock automation contracts..."
	@$(MAKE) deploy-automation-mock
	@echo ""
	@echo "✅ MOCK AUTOMATION CONTRACTS DEPLOYED!"
	@echo "Ready for configuration and testing"

# ========================================
# 🔧 STEP-BY-STEP COMMANDS
# ========================================

# Deploy Chainlink Automation contracts for production
deploy-automation:
	@echo "🤖 DEPLOYING CHAINLINK AUTOMATION CONTRACTS"
	@echo "============================================="
	@echo "Reading addresses from deployed-addresses.json..."
	@if [ ! -f "deployed-addresses.json" ]; then \
		echo "❌ deployed-addresses.json not found! Deploy core system first."; \
		echo "   Run: make deploy-complete"; \
		exit 1; \
	fi
	@. ./.env && \
	export ORACLE_ADDRESS=$$(jq -r '.vcopCollateral.oracle' deployed-addresses.json) && \
	export GENERIC_LOAN_MANAGER_ADDRESS=$$(jq -r '.coreLending.genericLoanManager' deployed-addresses.json) && \
	export FLEXIBLE_LOAN_MANAGER_ADDRESS=$$(jq -r '.coreLending.flexibleLoanManager' deployed-addresses.json) && \
	export RISK_CALCULATOR_ADDRESS=$$(jq -r '.coreLending.riskCalculator' deployed-addresses.json) && \
	export PRICE_REGISTRY_ADDRESS=$$(jq -r '.priceRegistry' deployed-addresses.json) && \
	forge script script/automation/DeployAutomationProduction.s.sol:DeployAutomationProduction \
		--rpc-url $$RPC_URL --private-key $$PRIVATE_KEY --broadcast --gas-price 2000000000 --legacy --slow
	@echo "Updating JSON with automation addresses..."
	@./update-automation-addresses.sh
	@echo "✅ AUTOMATION CONTRACTS DEPLOYED!"

# Deploy Chainlink Automation for mock system
deploy-automation-mock:
	@echo "🧪 DEPLOYING AUTOMATION FOR MOCK SYSTEM"
	@echo "======================================="
	@echo "Reading addresses from deployed-addresses-mock.json..."
	@if [ ! -f "deployed-addresses-mock.json" ]; then \
		echo "❌ deployed-addresses-mock.json not found! Deploy mock system first."; \
		echo "   Run: make deploy-complete-mock"; \
		exit 1; \
	fi
	@. ./.env && \
	export ORACLE_ADDRESS=$$(jq -r '.vcopCollateral.mockVcopOracle' deployed-addresses-mock.json) && \
	export GENERIC_LOAN_MANAGER_ADDRESS=$$(jq -r '.coreLending.genericLoanManager' deployed-addresses-mock.json) && \
	export FLEXIBLE_LOAN_MANAGER_ADDRESS=$$(jq -r '.coreLending.flexibleLoanManager' deployed-addresses-mock.json) && \
	export RISK_CALCULATOR_ADDRESS=$$(jq -r '.coreLending.riskCalculator' deployed-addresses-mock.json) && \
	export PRICE_REGISTRY_ADDRESS=$$(jq -r '.coreLending.dynamicPriceRegistry' deployed-addresses-mock.json) && \
	forge script script/automation/DeployAutomationMock.s.sol:DeployAutomationMock \
		--rpc-url $$RPC_URL --private-key $$PRIVATE_KEY --broadcast --gas-price 2000000000 --legacy --slow
	@echo "Updating mock JSON with automation addresses..."
	@./update-automation-addresses-mock.sh
	@echo "✅ MOCK AUTOMATION CONTRACTS DEPLOYED!"

# Setup Chainlink environment
setup-chainlink-automation:
	@echo "🔧 SETTING UP CHAINLINK ENVIRONMENT"
	@echo "==================================="
	@if [ ! -f "deployed-addresses.json" ]; then \
		echo "❌ deployed-addresses.json not found!"; \
		exit 1; \
	fi
	@./setup-chainlink-automation.sh
	@echo "✅ CHAINLINK ENVIRONMENT CONFIGURED!"

# Register upkeep with official Chainlink Registry
register-chainlink-upkeep:
	@echo "📋 CHAINLINK UPKEEP REGISTRATION GUIDE"
	@echo "======================================"
	@echo ""
	@echo "🌐 Go to: https://automation.chain.link/base-sepolia"
	@echo ""
	@echo "📋 Registration Details:"
	@echo "   Network: Base Sepolia"
	@echo "   Trigger: Custom Logic"
	@echo "   Target Contract: $(shell cat deployed-addresses.json | jq -r '.AUTOMATION_KEEPER // "CHECK_DEPLOYED_ADDRESSES"')"
	@echo "   Gas Limit: 2000000"
	@echo "   Starting Balance: 5 LINK"
	@echo ""
	@echo "🔧 CheckData (copy this hex):"
	@cast call $(shell cat deployed-addresses.json | jq -r '.AUTOMATION_KEEPER // "0x0"') \
		"generateOptimizedCheckData(address,uint256,uint256)(bytes)" \
		$(shell cat deployed-addresses.json | jq -r '.FLEXIBLE_LOAN_MANAGER // "0x0"') \
		0 25 2>/dev/null || echo "❌ Run deploy-automation-production first"
	@echo ""
	@echo "💰 Get LINK tokens: https://faucets.chain.link/"

# Configure Forwarder security
configure-forwarder:
	@echo "⚡ Configuring Chainlink Forwarder..."
	@echo "Enter the forwarder address from your registered upkeep:"
	@read -p "Forwarder Address: " FORWARDER; \
	cast send $(shell cat deployed-addresses.json | jq -r '.AUTOMATION_KEEPER') \
		"setChainlinkForwarder(address)" \
		$$FORWARDER \
		--rpc-url $(BASE_SEPOLIA_RPC_URL) \
		--private-key $(PRIVATE_KEY)
	@echo "✅ Forwarder configured!"

# Update .env with Forwarder address
update-forwarder-env:
	@echo "🔧 UPDATING .ENV WITH FORWARDER ADDRESS"
	@echo "======================================="
	@./update-env-forwarder.sh

# ========================================
# 🔍 STATUS & VERIFICATION
# ========================================

# Check automation system status
check-automation-status:
	@echo "📊 AUTOMATION SYSTEM STATUS"
	@echo "=========================="
	@echo ""
	@echo "🎯 Keeper Contract: $(shell cat deployed-addresses.json | jq -r '.AUTOMATION_KEEPER // "NOT_DEPLOYED"')"
	@echo "📊 Stats:"
	@cast call $(shell cat deployed-addresses.json | jq -r '.AUTOMATION_KEEPER') \
		"getStats()(uint256,uint256,uint256,uint256,uint256)" \
		--rpc-url $(BASE_SEPOLIA_RPC_URL) 2>/dev/null | \
		awk 'BEGIN{print "   Total Liquidations: " $$1 "\n   Total Upkeeps: " $$2 "\n   Last Execution: " $$3 "\n   Avg Gas Used: " $$4 "\n   Registered Managers: " $$5}' || \
		echo "❌ Could not fetch stats - check deployment"
	@echo ""
	@echo "🏥 Emergency Status:"
	@cast call $(shell cat deployed-addresses.json | jq -r '.AUTOMATION_KEEPER') \
		"emergencyPause()(bool)" \
		--rpc-url $(BASE_SEPOLIA_RPC_URL) 2>/dev/null | \
		sed 's/true/🚨 EMERGENCY PAUSED/; s/false/✅ Active/' || \
		echo "❌ Could not check emergency status"

# Check Chainlink upkeep status
check-chainlink-status:
	@echo "🔗 CHAINLINK AUTOMATION STATUS"
	@echo "=============================="
	@echo "🌐 Official Chainlink Addresses (Base Sepolia):"
	@echo "  Registry:  0x91D4a4C3D448c7f3CB477332B1c7D420a5810aC3"
	@echo "  Registrar: 0xf28D56F3A707E25B71Ce529a21AF388751E1CF2A"
	@echo "  LINK:      0xE4aB69C077896252FAFBD49EFD26B5D171A32410"
	@echo ""
	@echo "🎯 Monitor your upkeeps at:"
	@echo "   https://automation.chain.link/"
	@echo "   (Select Base Sepolia network)"
	@echo ""
	@echo "💰 Get LINK tokens at:"
	@echo "   https://faucets.chain.link/"

# ========================================
# 🧪 TESTING COMMANDS
# ========================================

# Test complete automation flow
test-automation-flow:
	@echo "🧪 TESTING COMPLETE AUTOMATION FLOW"
	@echo "=================================="
	@if [ ! -f "deployed-addresses-mock.json" ]; then \
		echo "❌ Mock system not deployed! Run 'make deploy-complete-mock' first"; \
		exit 1; \
	fi
	@AUTOMATION_KEEPER=$$(jq -r '.automation.automationKeeper // ""' deployed-addresses-mock.json) && \
	if [ "$$AUTOMATION_KEEPER" = "" ] || [ "$$AUTOMATION_KEEPER" = "null" ]; then \
		echo "❌ Automation not deployed! Run 'make deploy-automation-mock' first"; \
		exit 1; \
	fi
	@echo "Running complete automation test..."
	@. ./.env && forge script script/test/TestAutomationWithMockOracle.s.sol:TestAutomationWithMockOracle \
		--rpc-url $(RPC_URL) --private-key $$PRIVATE_KEY --broadcast --gas-price 2000000000
	@echo "✅ AUTOMATION FLOW TEST COMPLETED!"

# Quick automation check
test-automation-quick:
	@echo "⚡ QUICK AUTOMATION CHECK"
	@echo "========================"
	@. ./.env && forge script script/test/TestAutomationWithMockOracle.s.sol:TestAutomationWithMockOracle \
		--sig "quickAutomationCheck()" --rpc-url $(RPC_URL)
	@echo "✅ Quick check completed!"

# Configure vault automation for liquidation funding
configure-vault-automation:
	@echo "🔧 CONFIGURING VAULT-FUNDED LIQUIDATION"
	@echo "======================================="
	@if [ ! -f "deployed-addresses-mock.json" ]; then \
		echo "❌ Mock system not deployed! Run 'make deploy-complete-mock' first"; \
		exit 1; \
	fi
	@. ./.env && forge script script/automation/ConfigureVaultAutomation.s.sol:ConfigureVaultAutomation \
		--rpc-url $$RPC_URL --private-key $$PRIVATE_KEY --broadcast --gas-price 2000000000
	@echo "✅ Vault-funded liquidation configured!"

# Test vault-funded liquidation
test-vault-liquidation:
	@echo "🏦 TESTING VAULT-FUNDED LIQUIDATION"
	@echo "==================================="
	@if [ ! -f "deployed-addresses-mock.json" ]; then \
		echo "❌ Mock system not deployed! Run 'make deploy-complete-mock' first"; \
		exit 1; \
	fi
	@. ./.env && forge script script/test/TestVaultFundedLiquidation.s.sol:TestVaultFundedLiquidation \
		--rpc-url $$RPC_URL --private-key $$PRIVATE_KEY --broadcast --gas-price 2000000000
	@echo "✅ Vault liquidation test completed!"

# 🚀 CHAINLINK AUTOMATION - OFFICIAL REGISTRY COMMANDS
# =====================================================
# Updated to use official Chainlink Automation Registry
# Base Sepolia: 0x91D4a4C3D448c7f3CB477332B1c7D420a5810aC3

# ✅ PRODUCTION DEPLOYMENT (Official Chainlink Registry)
.PHONY: deploy-automation-production
deploy-automation-production:
	@echo "🚀 Deploying automation with OFFICIAL Chainlink Registry..."
	@echo "📋 Make sure you have set these environment variables:"
	@echo "   - PRIVATE_KEY"
	@echo "   - PRICE_REGISTRY_ADDRESS" 
	@echo "   - LOAN_MANAGER_ADDRESS"
	@echo ""
	forge script script/automation/DeployAutomationProduction.s.sol \
		--rpc-url $(BASE_SEPOLIA_RPC_URL) \
		--broadcast \
		--verify \
		-vvvv
	@echo "✅ Automation contracts deployed with official Chainlink Registry!"

# 📋 UPKEEP REGISTRATION HELPER
.PHONY: register-chainlink-upkeep
register-chainlink-upkeep:
	@echo "📋 CHAINLINK UPKEEP REGISTRATION GUIDE"
	@echo "======================================"
	@echo ""
	@echo "🌐 Go to: https://automation.chain.link/base-sepolia"
	@echo ""
	@echo "📋 Registration Details:"
	@echo "   Network: Base Sepolia"
	@echo "   Trigger: Custom Logic"
	@echo "   Target Contract: $(shell cat deployed-addresses.json | jq -r '.AUTOMATION_KEEPER // "CHECK_DEPLOYED_ADDRESSES"')"
	@echo "   Gas Limit: 2000000"
	@echo "   Starting Balance: 5 LINK"
	@echo ""
	@echo "🔧 CheckData (copy this hex):"
	@cast call $(shell cat deployed-addresses.json | jq -r '.AUTOMATION_KEEPER // "0x0"') \
		"generateOptimizedCheckData(address,uint256,uint256)(bytes)" \
		$(shell cat deployed-addresses.json | jq -r '.FLEXIBLE_LOAN_MANAGER // "0x0"') \
		0 25 2>/dev/null || echo "❌ Run deploy-automation-production first"
	@echo ""
	@echo "💰 Get LINK tokens: https://faucets.chain.link/"

# ⚡ CONFIGURE FORWARDER (Run after upkeep registration)
.PHONY: configure-forwarder
configure-forwarder:
	@echo "⚡ Configuring Chainlink Forwarder..."
	@echo "Enter the forwarder address from your registered upkeep:"
	@read -p "Forwarder Address: " FORWARDER; \
	cast send $(shell cat deployed-addresses.json | jq -r '.AUTOMATION_KEEPER') \
		"setChainlinkForwarder(address)" \
		$$FORWARDER \
		--rpc-url $(BASE_SEPOLIA_RPC_URL) \
		--private-key $(PRIVATE_KEY)
	@echo "✅ Forwarder configured!"

# 🔒 ENABLE FORWARDER RESTRICTION (For production security)
.PHONY: enable-forwarder-restriction
enable-forwarder-restriction:
	@echo "🔒 Enabling forwarder restriction for production security..."
	cast send $(shell cat deployed-addresses.json | jq -r '.AUTOMATION_KEEPER') \
		"setForwarderRestriction(bool)" \
		true \
		--rpc-url $(BASE_SEPOLIA_RPC_URL) \
		--private-key $(PRIVATE_KEY)
	@echo "✅ Forwarder restriction enabled!"

# 🎛️ CONFIGURE RISK THRESHOLDS
.PHONY: configure-risk-thresholds
configure-risk-thresholds:
	@echo "🎛️ Configuring risk thresholds..."
	cast send $(shell cat deployed-addresses.json | jq -r '.AUTOMATION_KEEPER') \
		"setMinRiskThreshold(uint256)" \
		85 \
		--rpc-url $(BASE_SEPOLIA_RPC_URL) \
		--private-key $(PRIVATE_KEY)
	@echo "✅ Risk threshold set to 85%"

# 📈 CONFIGURE PRICE CHANGE TRIGGERS
.PHONY: configure-price-triggers
configure-price-triggers:
	@echo "📈 Configuring price change triggers..."
	cast send $(shell cat deployed-addresses.json | jq -r '.PRICE_TRIGGER // "NOT_DEPLOYED"') \
		"setPriceChangeThresholds(uint256,uint256,uint256,uint256)" \
		50000 75000 100000 150000 \
		--rpc-url $(BASE_SEPOLIA_RPC_URL) \
		--private-key $(PRIVATE_KEY) 2>/dev/null || \
		echo "❌ Price trigger not deployed or configured"
	@echo "✅ Price thresholds configured (5%, 7.5%, 10%, 15%)"

# 🚨 EMERGENCY CONTROLS
.PHONY: emergency-pause
emergency-pause:
	@echo "🚨 EMERGENCY PAUSE - Stopping all automation..."
	cast send $(shell cat deployed-addresses.json | jq -r '.AUTOMATION_KEEPER') \
		"setEmergencyPause(bool)" \
		true \
		--rpc-url $(BASE_SEPOLIA_RPC_URL) \
		--private-key $(PRIVATE_KEY)
	@echo "🚨 Automation PAUSED!"

.PHONY: emergency-resume
emergency-resume:
	@echo "✅ Resuming automation..."
	cast send $(shell cat deployed-addresses.json | jq -r '.AUTOMATION_KEEPER') \
		"setEmergencyPause(bool)" \
		false \
		--rpc-url $(BASE_SEPOLIA_RPC_URL) \
		--private-key $(PRIVATE_KEY)
	@echo "✅ Automation RESUMED!"

# 🔍 TESTING & SIMULATION
.PHONY: simulate-upkeep
simulate-upkeep:
	@echo "🔍 Simulating upkeep execution..."
	@CHECKDATA=$$(cast call $(shell cat deployed-addresses.json | jq -r '.AUTOMATION_KEEPER') \
		"generateOptimizedCheckData(address,uint256,uint256)(bytes)" \
		$(shell cat deployed-addresses.json | jq -r '.FLEXIBLE_LOAN_MANAGER') \
		0 25 --rpc-url $(BASE_SEPOLIA_RPC_URL) 2>/dev/null); \
	echo "📋 CheckData: $$CHECKDATA"; \
	cast call $(shell cat deployed-addresses.json | jq -r '.AUTOMATION_KEEPER') \
		"checkUpkeep(bytes)(bool,bytes)" \
		$$CHECKDATA \
		--rpc-url $(BASE_SEPOLIA_RPC_URL) 2>/dev/null || \
		echo "❌ Simulation failed - check deployment and configuration"

# 📊 MONITORING DASHBOARD
.PHONY: automation-dashboard
automation-dashboard:
	@echo "📊 CHAINLINK AUTOMATION DASHBOARD"
	@echo "=================================="
	@echo ""
	@echo "🌐 Official Dashboard:"
	@echo "   https://automation.chain.link/base-sepolia"
	@echo ""
	@echo "🔗 Your Contracts:"
	@echo "   Keeper: https://sepolia.basescan.org/address/$(shell cat deployed-addresses.json | jq -r '.AUTOMATION_KEEPER // "NOT_DEPLOYED"')"
	@echo "   Price Trigger: https://sepolia.basescan.org/address/$(shell cat deployed-addresses.json | jq -r '.PRICE_TRIGGER // "NOT_DEPLOYED"')"
	@echo ""
	@echo "📈 Quick Status Check:"
	@make check-automation-status

# 🧪 FULL AUTOMATION SETUP (One command for everything)
.PHONY: setup-automation-complete
setup-automation-complete:
	@echo "🧪 COMPLETE AUTOMATION SETUP"
	@echo "============================="
	@echo "This will deploy and configure your entire automation system"
	@echo ""
	@echo "Prerequisites:"
	@echo "✅ BASE_SEPOLIA_RPC_URL set"
	@echo "✅ PRIVATE_KEY set"  
	@echo "✅ PRICE_REGISTRY_ADDRESS set"
	@echo "✅ LOAN_MANAGER_ADDRESS set"
	@echo "✅ 5+ LINK tokens in wallet"
	@echo ""
	@read -p "Continue? [y/N]: " confirm && [[ $$confirm == [yY] ]] || exit 1
	@echo ""
	@echo "🚀 Step 1: Deploying contracts..."
	@make deploy-automation-production
	@echo ""
	@echo "⚡ Step 2: Configuring system..."
	@make configure-risk-thresholds
	@make configure-price-triggers  
	@echo ""
	@echo "📋 Step 3: Registration instructions..."
	@make register-chainlink-upkeep
	@echo ""
	@echo "✅ SETUP COMPLETE!"
	@echo "Next: Register your upkeep at https://automation.chain.link/base-sepolia"

# 📚 HELP
.PHONY: automation-help
automation-help:
	@echo "📚 CHAINLINK AUTOMATION COMMANDS"
	@echo "================================"
	@echo ""
	@echo "🚀 DEPLOYMENT:"
	@echo "   make deploy-automation-production  Deploy with official Chainlink Registry"
	@echo "   make setup-automation-complete     Full automated setup"
	@echo ""
	@echo "📋 REGISTRATION:"
	@echo "   make register-chainlink-upkeep     Show registration guide"
	@echo "   make configure-forwarder          Configure forwarder after registration"
	@echo "   make enable-forwarder-restriction Enable security"
	@echo ""
	@echo "🎛️ CONFIGURATION:"
	@echo "   make configure-risk-thresholds    Set liquidation risk levels"
	@echo "   make configure-price-triggers     Configure price change triggers"
	@echo ""
	@echo "🚨 EMERGENCY:"
	@echo "   make emergency-pause              Pause all automation"
	@echo "   make emergency-resume             Resume automation"
	@echo ""
	@echo "📊 MONITORING:"
	@echo "   make check-automation-status      Check system status"
	@echo "   make simulate-upkeep             Test upkeep execution"
	@echo "   make automation-dashboard        Open monitoring links"
	@echo ""
	@echo "For more help: https://docs.chain.link/chainlink-automation/"

# 🧪 LOCAL TESTING (NO CHAINLINK REGISTRATION REQUIRED)
.PHONY: test-automation-local
test-automation-local:
	@echo "🧪 TESTING AUTOMATION LOCALLY (NO CHAINLINK REGISTRATION REQUIRED)"
	@echo "===================================================================="
	@echo "These tests work WITHOUT registering on Chainlink's website"
	@echo "They directly call checkUpkeep() and performUpkeep() functions"
	@echo ""
	forge script script/test/TestAutomationSimple.s.sol \
		--rpc-url $(BASE_SEPOLIA_RPC_URL) \
		--broadcast \
		-vvv
	@echo "✅ Local automation test completed!"

# 🎯 COMPREHENSIVE AUTOMATION TEST (WITH MOCK ORACLE)
.PHONY: test-automation-comprehensive
test-automation-comprehensive:
	@echo "🎯 COMPREHENSIVE AUTOMATION TEST"
	@echo "================================="
	@echo "Full test: Position creation → Price crash → Automatic liquidation"
	@echo "This demonstrates the complete automation flow locally"
	@echo ""
	forge script script/test/TestAutomationWithMockOracle.s.sol \
		--rpc-url $(BASE_SEPOLIA_RPC_URL) \
		--broadcast \
		-vvv
	@echo "✅ Comprehensive automation test completed!"

# 🔍 QUICK AUTOMATION CHECK
.PHONY: check-automation-locally
check-automation-locally:
	@echo "🔍 QUICK LOCAL AUTOMATION CHECK"
	@echo "==============================="
	@echo "Checking if checkUpkeep() detects any liquidatable positions..."
	@echo ""
	forge script script/test/TestAutomationWithMockOracle.s.sol:TestAutomationWithMockOracle \
		--sig "quickAutomationCheck()" \
		--rpc-url $(BASE_SEPOLIA_RPC_URL) \
		-v
	@echo "✅ Quick check completed!"

# 🎲 CREATE TEST POSITIONS WITH DIFFERENT RISK LEVELS
.PHONY: create-risk-positions
create-risk-positions:
	@echo "🎲 CREATING TEST POSITIONS WITH DIFFERENT RISK LEVELS"
	@echo "====================================================="
	@echo "Creating multiple positions: Safe, Medium Risk, High Risk"
	@echo ""
	forge script script/test/TestAutomationWithMockOracle.s.sol:TestAutomationWithMockOracle \
		--sig "createRiskPositions()" \
		--rpc-url $(BASE_SEPOLIA_RPC_URL) \
		--broadcast \
		-vv
	@echo "✅ Risk positions created for testing!"

# 🧪 MANUAL CHECKUPKEEP TEST
.PHONY: manual-checkupkeep-test
manual-checkupkeep-test:
	@echo "🧪 MANUAL CHECKUPKEEP TEST"
	@echo "=========================="
	@echo "Directly calling checkUpkeep() function..."
	@echo ""
	@CHECKDATA=$$(cast call $(shell cat deployed-addresses.json | jq -r '.AUTOMATION_KEEPER // "0x0"') \
		"generateOptimizedCheckData(address,uint256,uint256)(bytes)" \
		$(shell cat deployed-addresses.json | jq -r '.FLEXIBLE_LOAN_MANAGER // "0x0"') \
		0 25 --rpc-url $(BASE_SEPOLIA_RPC_URL) 2>/dev/null); \
	echo "📋 Generated CheckData: $$CHECKDATA"; \
	echo "🔍 Calling checkUpkeep..."; \
	cast call $(shell cat deployed-addresses.json | jq -r '.AUTOMATION_KEEPER') \
		"checkUpkeep(bytes)(bool,bytes)" \
		"$$CHECKDATA" \
		--rpc-url $(BASE_SEPOLIA_RPC_URL) 2>/dev/null || \
		echo "❌ Make sure automation contracts are deployed first"

# 🎮 INTERACTIVE AUTOMATION TESTING
.PHONY: test-automation-interactive
test-automation-interactive:
	@echo "🎮 INTERACTIVE AUTOMATION TESTING"
	@echo "=================================="
	@echo ""
	@echo "Choose your test:"
	@echo "1. Simple automation test (basic functionality)"
	@echo "2. Comprehensive test (full liquidation flow)"
	@echo "3. Quick upkeep check (checkUpkeep only)"
	@echo "4. Create risk positions for testing"
	@echo "5. Manual checkUpkeep test"
	@echo ""
	@read -p "Enter choice [1-5]: " choice; \
	case $$choice in \
		1) make test-automation-local ;; \
		2) make test-automation-comprehensive ;; \
		3) make check-automation-locally ;; \
		4) make create-risk-positions ;; \
		5) make manual-checkupkeep-test ;; \
		*) echo "Invalid choice" ;; \
	esac

# 📊 AUTOMATION TEST SUMMARY
.PHONY: automation-test-summary
automation-test-summary:
	@echo "📊 AUTOMATION TESTING SUMMARY"
	@echo "=============================="
	@echo ""
	@echo "Available local tests (NO CHAINLINK REGISTRATION REQUIRED):"
	@echo ""
	@echo "🧪 Basic Tests:"
	@echo "   make test-automation-local           Simple automation functionality test"
	@echo "   make manual-checkupkeep-test         Direct checkUpkeep() call"
	@echo "   make check-automation-locally        Quick upkeep detection check"
	@echo ""
	@echo "🎯 Advanced Tests:"
	@echo "   make test-automation-comprehensive   Full liquidation flow simulation"
	@echo "   make create-risk-positions          Create positions for testing"
	@echo ""
	@echo "🎮 Interactive:"
	@echo "   make test-automation-interactive     Choose test interactively"
	@echo ""
	@echo "✅ All these tests work WITHOUT Chainlink registration!"
	@echo "✅ They directly call your smart contract functions"
	@echo "✅ No LINK tokens required for local testing"
	@echo ""
	@echo "🌐 For LIVE automation, register at: https://automation.chain.link/" 