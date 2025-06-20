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
	@echo "🔗 REGISTERING UPKEEP WITH CHAINLINK"
	@echo "==================================="
	@echo "⚠️  REQUIREMENTS:"
	@echo "   - At least 5 LINK tokens in your wallet"
	@echo "   - Connected to Base Sepolia network"
	@echo ""
	@if [ ! -f "deployed-addresses.json" ]; then \
		echo "❌ deployed-addresses.json not found!"; \
		exit 1; \
	fi
	@AUTOMATION_KEEPER=$$(jq -r '.automation.automationKeeper // ""' deployed-addresses.json) && \
	FLEXIBLE_LOAN_MANAGER=$$(jq -r '.coreLending.flexibleLoanManager // ""' deployed-addresses.json) && \
	if [ "$$AUTOMATION_KEEPER" = "" ] || [ "$$AUTOMATION_KEEPER" = "null" ]; then \
		echo "❌ Automation contracts not deployed! Run 'make deploy-automation' first"; \
		exit 1; \
	fi && \
	export AUTOMATION_KEEPER_ADDRESS="$$AUTOMATION_KEEPER" && \
	export FLEXIBLE_LOAN_MANAGER_ADDRESS="$$FLEXIBLE_LOAN_MANAGER" && \
	. ./.env && forge script script/automation/RegisterChainlinkUpkeep.s.sol:RegisterChainlinkUpkeep \
		--rpc-url $$RPC_URL --private-key $$PRIVATE_KEY --broadcast --gas-price 2000000000
	@echo ""
	@echo "✅ UPKEEP REGISTERED WITH CHAINLINK!"
	@echo "📋 IMPORTANT: Note the Forwarder address from the output above."
	@echo "    You'll need it for the next step."

# Configure Forwarder security
configure-forwarder:
	@echo "🛡️  CONFIGURING FORWARDER SECURITY"
	@echo "=================================="
	@echo "⚠️  REQUIRED: Set CHAINLINK_FORWARDER_ADDRESS in .env"
	@echo ""
	@if [ ! -f ".env" ]; then \
		echo "❌ .env file not found!"; \
		exit 1; \
	fi
	@. ./.env && \
	if [ -z "$$CHAINLINK_FORWARDER_ADDRESS" ]; then \
		echo "❌ CHAINLINK_FORWARDER_ADDRESS not set in .env"; \
		echo "   Add: CHAINLINK_FORWARDER_ADDRESS=0x..."; \
		exit 1; \
	fi
	@AUTOMATION_KEEPER=$$(jq -r '.automation.automationKeeper // ""' deployed-addresses.json) && \
	FLEXIBLE_LOAN_MANAGER=$$(jq -r '.coreLending.flexibleLoanManager // ""' deployed-addresses.json) && \
	export AUTOMATION_KEEPER_ADDRESS="$$AUTOMATION_KEEPER" && \
	export FLEXIBLE_LOAN_MANAGER_ADDRESS="$$FLEXIBLE_LOAN_MANAGER" && \
	. ./.env && forge script script/automation/ConfigureForwarderSecurity.s.sol:ConfigureForwarderSecurity \
		--rpc-url $$RPC_URL --private-key $$PRIVATE_KEY --broadcast --gas-price 2000000000
	@echo "✅ FORWARDER SECURITY CONFIGURED!"

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
	@echo "🔍 CHECKING AUTOMATION STATUS"
	@echo "============================="
	@if [ -f "deployed-addresses.json" ]; then \
		echo "📋 Production Automation Addresses:"; \
		echo "  Registry: $$(jq -r '.automation.automationRegistry // "❌ NOT DEPLOYED"' deployed-addresses.json)"; \
		echo "  Keeper: $$(jq -r '.automation.automationKeeper // "❌ NOT DEPLOYED"' deployed-addresses.json)"; \
		echo "  Adapter: $$(jq -r '.automation.loanAdapter // "❌ NOT DEPLOYED"' deployed-addresses.json)"; \
		echo "  Trigger: $$(jq -r '.automation.priceTrigger // "❌ NOT DEPLOYED"' deployed-addresses.json)"; \
		echo ""; \
	fi
	@if [ -f "deployed-addresses-mock.json" ]; then \
		echo "📋 Mock Automation Addresses:"; \
		echo "  Registry: $$(jq -r '.automation.automationRegistry // "❌ NOT DEPLOYED"' deployed-addresses-mock.json)"; \
		echo "  Keeper: $$(jq -r '.automation.automationKeeper // "❌ NOT DEPLOYED"' deployed-addresses-mock.json)"; \
		echo "  Adapter: $$(jq -r '.automation.loanAdapter // "❌ NOT DEPLOYED"' deployed-addresses-mock.json)"; \
		echo "  Trigger: $$(jq -r '.automation.priceTrigger // "❌ NOT DEPLOYED"' deployed-addresses-mock.json)"; \
	fi

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