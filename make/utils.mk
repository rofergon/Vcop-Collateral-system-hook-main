# ========================================
# 🛠️ UTILITIES MODULE
# ========================================

.PHONY: check-status check-addresses check-gas help-utils

help-utils:
	@echo ""
	@echo "🛠️ UTILITY COMMANDS"
	@echo "==================="
	@echo "check-status      - Check deployment status"
	@echo "check-addresses   - Show all contract addresses"
	@echo "check-gas         - Check gas prices and network"
	@echo "clear-pending     - Clear pending transactions"
	@echo "deploy-quick      - Quick deployment with high gas"
	@echo ""

# Check deployment status
check-status:
	@echo "🔍 CHECKING DEPLOYMENT STATUS"
	@echo "============================"
	@if [ -f "deployed-addresses-mock.json" ]; then \
		echo "✅ deployed-addresses-mock.json found"; \
		echo "📋 Key contracts:"; \
		cat deployed-addresses-mock.json | jq -r '.tokens.vcopToken // "N/A"' | xargs -I {} echo "  VCOP Token: {}"; \
		cat deployed-addresses-mock.json | jq -r '.vcopCollateral.mockVcopOracle // "N/A"' | xargs -I {} echo "  Oracle: {}"; \
		cat deployed-addresses-mock.json | jq -r '.coreLending.genericLoanManager // "N/A"' | xargs -I {} echo "  GenericLoanManager: {}"; \
		cat deployed-addresses-mock.json | jq -r '.coreLending.flexibleLoanManager // "N/A"' | xargs -I {} echo "  FlexibleLoanManager: {}"; \
		cat deployed-addresses-mock.json | jq -r '.rewards.rewardDistributor // "N/A"' | xargs -I {} echo "  RewardDistributor: {}"; \
	else \
		echo "❌ deployed-addresses-mock.json not found - run make deploy-complete first"; \
	fi

# Show all deployed contract addresses
check-addresses:
	@echo "📋 DEPLOYED CONTRACT ADDRESSES"
	@echo "=============================="
	@if [ -f "deployed-addresses-mock.json" ]; then \
		cat deployed-addresses-mock.json | jq .; \
	else \
		echo "❌ deployed-addresses-mock.json not found"; \
		echo "Run 'make deploy-complete' first"; \
	fi

# Check gas prices and network status
check-gas:
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
	@echo "🧹 CLEARING PENDING TRANSACTIONS"
	@echo "================================"
	@echo "⚠️ WARNING: This will send an empty transaction with higher gas"
	@read -p "Continue? [y/N]: " confirm && [ "$$confirm" = "y" ] || [ "$$confirm" = "Y" ] || (echo "Cancelled." && exit 1)
	@. ./.env && \
	DEPLOYER_ADDR=$$(cast wallet address $$PRIVATE_KEY) && \
	CURRENT_GAS=$$(cast gas-price --rpc-url $(RPC_URL)) && \
	HIGH_GAS=$$(echo "$$CURRENT_GAS * 10" | bc) && \
	CURRENT_NONCE=$$(cast nonce $$DEPLOYER_ADDR --rpc-url $(RPC_URL)) && \
	echo "Sending clearing transaction with nonce $$CURRENT_NONCE and gas price $$HIGH_GAS gwei..." && \
	cast send --rpc-url $(RPC_URL) --private-key $$PRIVATE_KEY --gas-price $$HIGH_GAS --nonce $$CURRENT_NONCE --value 0 $$DEPLOYER_ADDR && \
	echo "✅ Clearing transaction sent!"

# Quick deployment with high gas prices
deploy-quick:
	@echo "🚀 QUICK DEPLOYMENT WITH HIGH GAS"
	@echo "================================="
	@$(MAKE) clear-pending
	@sleep 5
	@$(MAKE) deploy-complete

# Verify system authorizations
verify-authorizations:
	@echo "✅ VERIFYING SYSTEM AUTHORIZATIONS"
	@echo "=================================="
	@echo "Checking contract permissions and roles..."
	@if [ -f "deployed-addresses-mock.json" ]; then \
		REWARD_DISTRIBUTOR=$$(jq -r '.rewards.rewardDistributor' deployed-addresses-mock.json) && \
		FLEXIBLE_LOAN_MANAGER=$$(jq -r '.coreLending.flexibleLoanManager' deployed-addresses-mock.json) && \
		. ./.env && \
		echo "RewardDistributor: $$REWARD_DISTRIBUTOR" && \
		echo "FlexibleLoanManager: $$FLEXIBLE_LOAN_MANAGER" && \
		echo "Checking authorizations..." && \
		cast call $$REWARD_DISTRIBUTOR "owner()" --rpc-url $(RPC_URL) | \
		xargs -I {} echo "  RewardDistributor owner: {}"; \
	fi
	@echo "✅ Authorization check completed!"

# Show contract sizes (for optimization)
check-contract-sizes:
	@echo "📏 CHECKING CONTRACT SIZES"
	@echo "========================="
	@forge build --sizes | head -20
	@echo "✅ Size check completed!" 