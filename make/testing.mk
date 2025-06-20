# ========================================
# 🧪 TESTING MODULE
# ========================================

.PHONY: create-test-loan liquidate-position help-testing

help-testing:
	@echo ""
	@echo "🧪 TESTING COMMANDS"
	@echo "=================="
	@echo "create-test-loan         - Create test loan position"
	@echo "liquidate-position       - Liquidate test position"
	@echo "test-oracle              - Test Oracle functionality"
	@echo "test-dynamic-system      - Test complete dynamic system"
	@echo "mint-test-tokens         - Mint test tokens"
	@echo "check-balances           - Check token balances"
	@echo ""

# Create test loan position with auto-minting
create-test-loan:
	@echo "🧪 CREATING TEST LOAN POSITION"
	@echo "============================="
	@echo "Reading addresses from deployed-addresses.json..."
	@echo "Creating position (1 ETH collateral, 1500 USDC loan)..."
	@CURRENT_GAS=$$(cast gas-price --rpc-url $(RPC_URL)) && \
	SAFE_GAS=$$(echo "$$CURRENT_GAS * 2" | bc) && \
	. ./.env && \
	export LOAN_MANAGER_ADDRESS=$$(jq -r '.coreLending.genericLoanManager' deployed-addresses.json) && \
	export COLLATERAL_TOKEN_ADDRESS=$$(jq -r '.mockTokens.ETH' deployed-addresses.json) && \
	export LOAN_TOKEN_ADDRESS=$$(jq -r '.mockTokens.USDC' deployed-addresses.json) && \
	forge script script/test/CreateTestLoanPosition.s.sol \
		--rpc-url $(RPC_URL) --private-key $$PRIVATE_KEY --broadcast --gas-price $$SAFE_GAS
	@echo "✅ Test loan position created!"

# Liquidate test position with ratio configuration
liquidate-position:
	@echo "⚡ LIQUIDATING TEST POSITION"
	@echo "==========================="
	@echo "Position ID: $(if $(POSITION_ID),$(POSITION_ID),1)"
	@CURRENT_GAS=$$(cast gas-price --rpc-url $(RPC_URL)) && \
	SAFE_GAS=$$(echo "$$CURRENT_GAS * 2" | bc) && \
	. ./.env && \
	export LOAN_MANAGER_ADDRESS=$$(jq -r '.coreLending.genericLoanManager' deployed-addresses.json) && \
	export FLEXIBLE_ASSET_HANDLER_ADDRESS=$$(jq -r '.coreLending.flexibleAssetHandler' deployed-addresses.json) && \
	export VAULT_BASED_HANDLER_ADDRESS=$$(jq -r '.coreLending.vaultBasedHandler' deployed-addresses.json) && \
	export COLLATERAL_TOKEN_ADDRESS=$$(jq -r '.mockTokens.ETH' deployed-addresses.json) && \
	export LOAN_TOKEN_ADDRESS=$$(jq -r '.mockTokens.USDC' deployed-addresses.json) && \
	export POSITION_ID=$(if $(POSITION_ID),$(POSITION_ID),1) && \
	forge script script/test/LiquidateTestPosition.s.sol \
		--rpc-url $(RPC_URL) --private-key $$PRIVATE_KEY --broadcast --gas-price $$SAFE_GAS
	@echo "✅ Position liquidated!"

# Test Oracle functionality
test-oracle:
	@echo "🔍 TESTING ORACLE FUNCTIONALITY"
	@echo "==============================="
	@forge script script/CheckOracleStatus.s.sol:CheckOracleStatus --rpc-url $(RPC_URL)
	@echo "✅ Oracle test completed!"

# Test complete dynamic system
test-dynamic-system:
	@echo "🧪 TESTING DYNAMIC PRICING SYSTEM"
	@echo "================================="
	@echo "Step 1: Creating test position..."
	@$(MAKE) create-test-loan
	@echo "Step 2: Testing price calculations..."
	@if [ -f "deployed-addresses.json" ]; then \
		PRICE_REGISTRY=$$(jq -r '.priceRegistry' deployed-addresses.json) && \
		ETH_TOKEN=$$(jq -r '.mockTokens.ETH' deployed-addresses.json) && \
		. ./.env && \
		cast call $$PRICE_REGISTRY "getTokenPrice(address)" $$ETH_TOKEN --rpc-url $(RPC_URL) | \
		xargs -I {} echo "ETH Price: {} (6 decimals)"; \
	fi
	@echo "Step 3: Testing liquidation..."
	@$(MAKE) liquidate-position POSITION_ID=1
	@echo "✅ Dynamic system test completed!"

# Mint test tokens manually
mint-test-tokens:
	@echo "🪙 MINTING TEST TOKENS"
	@echo "====================="
	@CURRENT_GAS=$$(cast gas-price --rpc-url $(RPC_URL)) && \
	SAFE_GAS=$$(echo "$$CURRENT_GAS * 2" | bc) && \
	. ./.env && \
	DEPLOYER_ADDR=$$(cast wallet address $$PRIVATE_KEY) && \
	ETH_TOKEN=$$(jq -r '.mockTokens.ETH' deployed-addresses.json) && \
	USDC_TOKEN=$$(jq -r '.mockTokens.USDC' deployed-addresses.json) && \
	WBTC_TOKEN=$$(jq -r '.mockTokens.WBTC' deployed-addresses.json) && \
	echo "Minting to: $$DEPLOYER_ADDR" && \
	cast send $$ETH_TOKEN "mint(address,uint256)" $$DEPLOYER_ADDR 100000000000000000000 --rpc-url $(RPC_URL) --private-key $$PRIVATE_KEY --gas-price $$SAFE_GAS && \
	cast send $$USDC_TOKEN "mint(address,uint256)" $$DEPLOYER_ADDR 500000000000 --rpc-url $(RPC_URL) --private-key $$PRIVATE_KEY --gas-price $$SAFE_GAS && \
	cast send $$WBTC_TOKEN "mint(address,uint256)" $$DEPLOYER_ADDR 1000000000 --rpc-url $(RPC_URL) --private-key $$PRIVATE_KEY --gas-price $$SAFE_GAS
	@echo "✅ Tokens minted: 100 ETH, 500k USDC, 10 WBTC"

# Check token balances
check-balances:
	@echo "💰 CHECKING TOKEN BALANCES"
	@echo "========================="
	@. ./.env && \
	export LOAN_MANAGER_ADDRESS=$$(jq -r '.coreLending.genericLoanManager' deployed-addresses.json) && \
	export COLLATERAL_TOKEN_ADDRESS=$$(jq -r '.mockTokens.ETH' deployed-addresses.json) && \
	export LOAN_TOKEN_ADDRESS=$$(jq -r '.mockTokens.USDC' deployed-addresses.json) && \
	forge script script/test/CreateTestLoanPosition.s.sol:CreateTestLoanPosition --sig "checkBalances()" --rpc-url $(RPC_URL)
	@echo "✅ Balance check completed!" 