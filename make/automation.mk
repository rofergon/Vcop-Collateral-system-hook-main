# ========================================
# 🤖 AUTOMATION MODULE
# ========================================

.PHONY: deploy-automation deploy-automation-mock help-automation

help-automation:
	@echo ""
	@echo "🤖 AUTOMATION COMMANDS"
	@echo "======================"
	@echo "deploy-automation        - Deploy Chainlink Automation"
	@echo "deploy-automation-mock   - Deploy automation for mock system"
	@echo "check-automation-status  - Check automation deployment"
	@echo "test-automation-flow     - Complete automation test flow"
	@echo "test-automation-quick    - Quick automation check"
	@echo ""

# Deploy Chainlink Automation for production
deploy-automation:
	@echo "🤖 DEPLOYING CHAINLINK AUTOMATION SYSTEM"
	@echo "========================================"
	@echo "Reading addresses from deployed-addresses.json..."
	@. ./.env && \
	export ORACLE_ADDRESS=$$(jq -r '.vcopCollateral.oracle' deployed-addresses.json) && \
	export GENERIC_LOAN_MANAGER_ADDRESS=$$(jq -r '.coreLending.genericLoanManager' deployed-addresses.json) && \
	export FLEXIBLE_LOAN_MANAGER_ADDRESS=$$(jq -r '.coreLending.flexibleLoanManager' deployed-addresses.json) && \
	export RISK_CALCULATOR_ADDRESS=$$(jq -r '.coreLending.riskCalculator' deployed-addresses.json) && \
	export PRICE_REGISTRY_ADDRESS=$$(jq -r '.priceRegistry' deployed-addresses.json) && \
	forge script script/automation/DeployAutomationClean.s.sol:DeployAutomationClean \
		--rpc-url $$RPC_URL --private-key $$PRIVATE_KEY --broadcast --gas-price 2000000000 --legacy --slow
	@echo "Updating JSON with automation addresses..."
	@./update-automation-addresses.sh
	@echo "✅ AUTOMATION DEPLOYMENT COMPLETED!"

# Deploy Chainlink Automation for mock system
deploy-automation-mock:
	@echo "🧪 DEPLOYING AUTOMATION FOR MOCK SYSTEM"
	@echo "======================================="
	@echo "Reading addresses from deployed-addresses-mock.json..."
	@. ./.env && \
	export ORACLE_ADDRESS=$$(jq -r '.vcopCollateral.mockVcopOracle' deployed-addresses-mock.json) && \
	export GENERIC_LOAN_MANAGER_ADDRESS=$$(jq -r '.coreLending.genericLoanManager' deployed-addresses-mock.json) && \
	export FLEXIBLE_LOAN_MANAGER_ADDRESS=$$(jq -r '.coreLending.flexibleLoanManager' deployed-addresses-mock.json) && \
	export RISK_CALCULATOR_ADDRESS=$$(jq -r '.coreLending.riskCalculator' deployed-addresses-mock.json) && \
	export PRICE_REGISTRY_ADDRESS=$$(jq -r '.coreLending.dynamicPriceRegistry' deployed-addresses-mock.json) && \
	forge script script/automation/DeployAutomationClean.s.sol:DeployAutomationClean \
		--rpc-url $$RPC_URL --private-key $$PRIVATE_KEY --broadcast --gas-price 2000000000 --legacy --slow
	@echo "Updating mock JSON with automation addresses..."
	@./update-automation-addresses-mock.sh
	@echo "✅ MOCK AUTOMATION DEPLOYMENT COMPLETED!"

# Check automation system status
check-automation-status:
	@echo "🔍 CHECKING AUTOMATION STATUS"
	@echo "============================="
	@if [ -f "deployed-addresses.json" ]; then \
		echo "📋 Automation Addresses:"; \
		echo "  Registry: $$(jq -r '.automation.automationRegistry // "❌ NOT DEPLOYED"' deployed-addresses.json)"; \
		echo "  Keeper: $$(jq -r '.automation.automationKeeper // "❌ NOT DEPLOYED"' deployed-addresses.json)"; \
		echo "  Adapter: $$(jq -r '.automation.loanAdapter // "❌ NOT DEPLOYED"' deployed-addresses.json)"; \
		echo "  Trigger: $$(jq -r '.automation.priceTrigger // "❌ NOT DEPLOYED"' deployed-addresses.json)"; \
	else \
		echo "❌ deployed-addresses.json not found"; \
	fi

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