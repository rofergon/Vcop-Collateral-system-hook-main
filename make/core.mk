# ========================================
# 🚀 CORE DEPLOYMENT MODULE
# ========================================

.PHONY: deploy-complete deploy-complete-mock deploy-complete-optimized help-core

help-core:
	@echo ""
	@echo "🚀 CORE DEPLOYMENT COMMANDS"
	@echo "============================"
	@echo "deploy-complete          - Complete deployment with real Oracle"
	@echo "deploy-complete-mock     - Complete deployment with MockOracle"
	@echo "deploy-complete-optimized - Production deployment with optimizations"
	@echo "deploy-emergency-registry - Deploy emergency registry system"
	@echo ""

# Main deployment with real Oracle
deploy-complete:
	@echo "🚀 STARTING COMPLETE DEPLOYMENT"
	@echo "==============================="
	@forge build
	@echo "Deploying unified system..."
	@forge script script/deploy/DeployUnifiedSystem.s.sol:DeployUnifiedSystem \
		--rpc-url $(RPC_URL) --broadcast --legacy --gas-price 30000000000 --slow
	@echo "Deploying Emergency Registry..."
	@. ./.env && forge script script/deploy/DeployEmergencyRegistry.s.sol:DeployEmergencyRegistry \
		--rpc-url $$RPC_URL --private-key $$PRIVATE_KEY --broadcast --legacy --gas-price 30000000000 --slow
	@echo "Configuring Oracle..."
	@forge script script/config/ConfigureChainlinkOracle.s.sol:ConfigureChainlinkOracle \
		--rpc-url $(RPC_URL) --broadcast --legacy --gas-price 30000000000 --slow
	@echo "Setting VCOP Price..."
	@forge script script/config/ConfigureVCOPPrice.s.sol:ConfigureVCOPPrice \
		--rpc-url $(RPC_URL) --broadcast --legacy --gas-price 30000000000 --slow
	@echo "Deploying Dynamic Price Registry..."
	@. ./.env && forge script script/deploy/DeployDynamicPriceRegistry.s.sol:DeployDynamicPriceRegistry \
		--rpc-url $$RPC_URL --private-key $$PRIVATE_KEY --broadcast --legacy --gas-price 30000000000 --slow
	@echo "Configuring system..."
	@. ./.env && forge script script/config/ConfigureDynamicPricing.s.sol:ConfigureDynamicPricing \
		--rpc-url $$RPC_URL --private-key $$PRIVATE_KEY --broadcast --legacy --gas-price 30000000000 --slow
	@echo "Configuring Asset Handlers..."
	@. ./.env && forge script script/deploy/ConfigureAssetHandlers.s.sol:ConfigureAssetHandlers \
		--rpc-url $$RPC_URL --private-key $$PRIVATE_KEY --broadcast --legacy --gas-price 30000000000 --slow
	@echo "✅ DEPLOYMENT COMPLETED!"

# Deployment with MockOracle for testing
deploy-complete-mock:
	@echo "🧪 STARTING MOCK DEPLOYMENT"
	@echo "==========================="
	@forge build
	@echo "Deploying unified system with Mock Oracle..."
	@forge script script/deploy/DeployUnifiedSystemMock.s.sol:DeployUnifiedSystemMock \
		--rpc-url $(RPC_URL) --broadcast --legacy --gas-price 30000000000 --slow
	@echo "Configuring Mock Oracle..."
	@forge script script/config/ConfigureMockOracle.s.sol:ConfigureMockOracle \
		--rpc-url $(RPC_URL) --broadcast --legacy --gas-price 30000000000 --slow
	@echo "Setting VCOP Price in Mock..."
	@forge script script/config/ConfigureMockVCOPPrice.s.sol:ConfigureMockVCOPPrice \
		--rpc-url $(RPC_URL) --broadcast --legacy --gas-price 30000000000 --slow
	@echo "✅ MOCK DEPLOYMENT COMPLETED!"

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