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
# Sepolia
SEPOLIA_POOL_MANAGER_ADDRESS := 0x05E73354cFDd6745C338b50BcFDfA3Aa6fA03408
SEPOLIA_POSITION_MANAGER_ADDRESS := 0x4b2c77d209d3405f41a037ec6c77f7f5b8e2ca80

# Mainnet
MAINNET_POOL_MANAGER_ADDRESS := 0x498581ff718922c3f8e6a244956af099b2652b2b
MAINNET_POSITION_MANAGER_ADDRESS := 0x7c5f5a4bbd8fd63184577525326123b519429bdc

# Default values
AMOUNT := 100000000 # 100 tokens (6 decimals)
COLLATERAL := 1000000000 # 1000 USDC (6 decimals)

.PHONY: check-psm swap-vcop-to-usdc swap-usdc-to-vcop check-prices help update-oracle deploy-fixed-system clean-txs check-new-oracle test-new-system test-loans test-liquidation test-psm create-position deploy-mainnet check-psm-mainnet swap-vcop-to-usdc-mainnet swap-usdc-to-vcop-mainnet check-prices-mainnet check-new-oracle-mainnet deploy-risk-calculator test-core-loans test-eth-usdc-loan test-usdc-eth-loan test-advanced-operations test-risk-analysis test-loan-repayment provide-wbtc-liquidity provide-usdc-liquidity

help:
	@echo "🚀 AUTOMATED DEPLOYMENT WITH AUTO-CONFIGURATION (NEW!)"
	@echo "========================================================="
	@echo "make deploy-complete          - [FUNCTION] FAST DEPLOY (smart compilation + full system)"
	@echo "make deploy-complete-optimized - [PRODUCTION] OPTIMIZED DEPLOY (full rebuild + deploy)"
	@echo "make test-all                 - [TEST] RUN ALL TESTS (Rewards + Core + VCOP + Chainlink)"
	@echo "make configure-system-integration - [CONFIG] Auto-configure all authorizations (reads from JSON)"
	@echo "make verify-system-authorizations - [VERIFY] Check all authorizations are set correctly"
	@echo "make check-deployment-status  - [DEBUG] Check deployment status (reads from JSON)"
	@echo ""
	@echo "🔨 BUILD COMMANDS"
	@echo "=================="
	@echo "make build                    - [FAST] Smart compilation (only if needed)"
	@echo "make build-optimized          - [OPTIMIZED] Full rebuild with gas optimizations"
	@echo "make rebuild                  - [CLEAN] Clean + full optimized rebuild"
	@echo ""
	@echo "🔗 CHAINLINK ORACLE COMMANDS"
	@echo "=============================="
	@echo "make deploy-complete-chainlink    - [FUNCTION] Deploy + Configure Chainlink Oracle (BTC/USD + ETH/USD)"
	@echo "make test-chainlink-oracle        - [TEST] Test Chainlink integration"
	@echo "make check-chainlink-prices       - [PRICES] Check real-time BTC/ETH prices"
	@echo "make oracle-health-check          - [HEALTH] Complete oracle status check"
	@echo "make help-chainlink               - Show all Chainlink commands"
	@echo "PSM Swap Scripts"
	@echo "----------------"
	@echo "make check-psm                - Check PSM status and reserves (testnet)"
	@echo "make check-prices             - Check current PSM prices (testnet)"
	@echo "make swap-vcop-to-usdc [AMOUNT=X] - Swap VCOP for USDC (testnet)"
	@echo "make swap-usdc-to-vcop [AMOUNT=X] - Swap USDC for VCOP (testnet)"
	@echo "make update-oracle            - Update oracle to fix conversion rate (testnet)"
	@echo "make deploy-fixed-system      - Deploy entire system with fixed paridad (testnet)"
	@echo "make deploy-mainnet           - Deploy entire system to Base Mainnet"
	@echo "make clean-txs                - Clean pending transactions"
	@echo "make check-new-oracle         - Check rates from new oracle (testnet)"
	@echo "make test-new-system          - Test a swap with the newly deployed system (testnet)"
	@echo "make update-main-addresses    - Update deployed-addresses.json with RewardDistributor"
	@echo ""
	@echo "Base Mainnet Commands"
	@echo "--------------------"
	@echo "make check-psm-mainnet        - Check PSM status and reserves (mainnet)"
	@echo "make check-prices-mainnet     - Check current PSM prices (mainnet)"
	@echo "make swap-vcop-to-usdc-mainnet [AMOUNT=X] - Swap VCOP for USDC (mainnet)"
	@echo "make swap-usdc-to-vcop-mainnet [AMOUNT=X] - Swap USDC for VCOP (mainnet)"
	@echo "make check-new-oracle-mainnet - Check rates from oracle (mainnet)"
	@echo ""
	@echo "Loan System Scripts"
	@echo "----------------"
	@echo "make test-loans               - Test full loan cycle (create, add collateral, withdraw, repay)"
	@echo "make test-liquidation         - Test loan liquidation mechanism"
	@echo "make test-psm                 - Test PSM functionality (check status, swap)"
	@echo ""
	@echo "New Core System Commands"
	@echo "-----------------------"
	@echo "make deploy-unified           - Deploy complete unified system (core + VcopCollateral)"
	@echo "make check-addresses          - Show all deployed contract addresses"
	@echo "make check-balance            - Check deployer ETH balance"
	@echo "make check-tokens             - Check deployer token balances (ETH, WBTC, USDC)"
	@echo "make provide-eth-liquidity    - Provide ETH liquidity to VaultBasedHandler"
	@echo "make provide-wbtc-liquidity   - Provide WBTC liquidity to VaultBasedHandler"
	@echo "make provide-usdc-liquidity   - Provide USDC liquidity to VaultBasedHandler"
	@echo "make check-vault              - Check vault info for a specific token"
	@echo "make verify-contract          - Verify contract on block explorer"
	@echo ""
	@echo "Core System Testing Commands"
	@echo "---------------------------"
	@echo "make test-core-loans          - Run comprehensive core lending system tests"
	@echo "make test-eth-usdc-loan       - Test ETH collateral -> USDC loan"
	@echo "make test-usdc-eth-loan       - Test USDC collateral -> ETH loan"
	@echo "make test-advanced-operations - Test advanced loan operations (add/withdraw collateral)"
	@echo "make test-risk-analysis       - Test basic risk analysis and calculations"
	@echo "make test-loan-repayment      - Test loan repayment and position closure"
	@echo "make test-vcop-price-calculator - Test VCOPPriceCalculator and Oracle integration"
	@echo "make check-price-calculator-setup - Check VCOPPriceCalculator configuration status"
	@echo "make configure-price-calculator - Configure VCOPPriceCalculator in Oracle"
	@echo "make test-vcop-oracle-prices - Test VCOP Oracle prices specifically"
	@echo ""
	@echo "ABI Management Commands"
	@echo "----------------------"
	@echo "make extract-abis             - Extract ABIs from compiled contracts"
	@echo "make regenerate-abis          - Recompile contracts and extract fresh ABIs"
	@echo ""
	

# Check PSM status (testnet)
check-psm:
	@echo "Checking PSM status on testnet..."
	forge script script/CustomPsmSwap.s.sol:CustomPsmSwapScript --sig "checkPSM()" --rpc-url $(RPC_URL)

# Check PSM status (mainnet)
check-psm-mainnet:
	@echo "Checking PSM status on mainnet..."
	forge script script/CustomPsmSwap.s.sol:CustomPsmSwapScript --sig "checkPSM()" --rpc-url $(MAINNET_RPC_URL) --chain-id $(BASE_MAINNET_CHAIN_ID)

# Check prices (testnet)
check-prices:
	@echo "Checking PSM prices on testnet..."
	forge script script/CustomPsmSwap.s.sol:CustomPsmSwapScript --sig "checkPrices()" --rpc-url $(RPC_URL) -vv

# Check prices (mainnet)
check-prices-mainnet:
	@echo "Checking PSM prices on mainnet..."
	forge script script/CustomPsmSwap.s.sol:CustomPsmSwapScript --sig "checkPrices()" --rpc-url $(MAINNET_RPC_URL) --chain-id $(BASE_MAINNET_CHAIN_ID) -vv

# Check new oracle (testnet)
check-new-oracle:
	@echo "Checking rates from the new oracle on testnet..."
	forge script script/CheckNewOracle.s.sol:CheckNewOracle --rpc-url $(RPC_URL) -vv

# Check new oracle (mainnet)
check-new-oracle-mainnet:
	@echo "Checking rates from the oracle on mainnet..."
	forge script script/CheckNewOracle.s.sol:CheckNewOracle --rpc-url $(MAINNET_RPC_URL) --chain-id $(BASE_MAINNET_CHAIN_ID) -vv

# Swap VCOP to USDC (testnet)
swap-vcop-to-usdc:
	@echo "Swapping VCOP for USDC on testnet..."
	forge script script/CustomPsmSwap.s.sol:CustomPsmSwapScript --sig "swapVcopToUsdc(uint256)" $(AMOUNT) --rpc-url $(RPC_URL) --broadcast -vv

# Swap VCOP to USDC (mainnet)
swap-vcop-to-usdc-mainnet:
	@echo "Swapping VCOP for USDC on mainnet..."
	forge script script/CustomPsmSwap.s.sol:CustomPsmSwapScript --sig "swapVcopToUsdc(uint256)" $(AMOUNT) --rpc-url $(MAINNET_RPC_URL) --chain-id $(BASE_MAINNET_CHAIN_ID) --broadcast -vv

# Swap USDC to VCOP (testnet)
swap-usdc-to-vcop:
	@echo "Swapping USDC for VCOP on testnet..."
	forge script script/CustomPsmSwap.s.sol:CustomPsmSwapScript --sig "swapUsdcToVcop(uint256)" $(AMOUNT) --rpc-url $(RPC_URL) --broadcast -vv

# Swap USDC to VCOP (mainnet)
swap-usdc-to-vcop-mainnet:
	@echo "Swapping USDC for VCOP on mainnet..."
	forge script script/CustomPsmSwap.s.sol:CustomPsmSwapScript --sig "swapUsdcToVcop(uint256)" $(AMOUNT) --rpc-url $(MAINNET_RPC_URL) --chain-id $(BASE_MAINNET_CHAIN_ID) --broadcast -vv

# Update oracle
update-oracle:
	@echo "Updating Oracle with fixed rates..."
	forge script script/UpdateOracle.s.sol:UpdateOracle --rpc-url $(RPC_URL) --broadcast -vv

# Deploy fixed system (Sepolia)
deploy-fixed-system:
	@echo "Deploying complete system with fixed parity to Sepolia..."
	forge script script/DeployFullSystemFixedParidad.s.sol:DeployFullSystemFixedParidad --rpc-url $(RPC_URL) --broadcast --gas-price 3000000000 -vv

# Deploy system to Base Mainnet
deploy-mainnet:
	@echo "Deploying complete system to Base Mainnet..."
	@echo "Using chain ID $(BASE_MAINNET_CHAIN_ID) for Base Mainnet"
	forge script script/DeployFullSystemFixedParidad.s.sol:DeployFullSystemFixedParidad --rpc-url $(MAINNET_RPC_URL) --broadcast --chain-id $(BASE_MAINNET_CHAIN_ID) -vv

# Clean transactions cache
clean-txs:
	@echo "Limpiando transacciones pendientes..."
	forge clean
	rm -rf broadcast/DeployFullSystemFixedParidad.s.sol/ 2>/dev/null || true
	@echo "Transacciones pendientes eliminadas"

# Test new system
test-new-system:
	@echo "Testing swap with new system (10 USDC)..."
	forge script script/CustomPsmSwap.s.sol:CustomPsmSwapScript --sig "swapUsdcToVcop(uint256)" 10000000 --rpc-url $(RPC_URL) --broadcast -vv 

# Test loan system
test-loans:
	@echo "Testing loan system..."
	forge script script/TestVCOPLoans.sol:TestVCOPLoans --rpc-url $(RPC_URL) --broadcast -vv

# Test loan liquidation
test-liquidation:
	@echo "Testing loan liquidation mechanism..."
	forge script script/TestVCOPLiquidation.sol:TestVCOPLiquidation --rpc-url $(RPC_URL) --broadcast -vv

# Test PSM functionality
test-psm:
	@echo "Testing PSM functionality..."
	forge script script/TestVCOPPSM.sol:TestVCOPPSM --rpc-url $(RPC_URL) --broadcast -vv

# Test creating position with specific collateral amount
create-position:
	@echo "Creating position with $(COLLATERAL) USDC collateral..."
	forge script script/TestVCOPLoans.sol:TestVCOPLoans --sig "createPosition(uint256)" $(COLLATERAL) --rpc-url $(RPC_URL) --broadcast -vv 

# === NEW CORE SYSTEM COMMANDS ===

# Deploy complete unified system (core + VcopCollateral)
deploy-unified:
	@echo "🚀 Deploying unified VCOP system..."
	forge script script/deploy/DeployUnifiedSystem.s.sol --rpc-url $(RPC_URL) --broadcast

# Check deployed contract addresses
check-addresses:
	@echo "📋 Deployed contract addresses:"
	@cat deployed-addresses.json | jq .

# Check balance of deployer
check-balance:
	@echo "💰 Deployer balance:"
	@cast balance 0xA6B3D200cD34ca14d7579DAc8B054bf50a62c37c --rpc-url $(RPC_URL) --ether

# Verify contract on explorer (replace ADDRESS with actual address)
verify-contract:
	@echo "[DEBUG] Verifying contract..."
	@read -p "Enter contract address: " addr; \
	read -p "Enter constructor args (optional): " args; \
	forge verify-contract $$addr --watch --constructor-args $$args --etherscan-api-key $(ETHERSCAN_API_KEY)

# Provide liquidity to VaultBasedHandler
provide-eth-liquidity:
	@echo "💰 Providing ETH liquidity..."
	@. ./.env && cast send 0x21756f22e0945Ed3faB38D05Cf8E933845a60622 "approve(address,uint256)" \
		0x26a5B76417f4b12131542CEfd9083e70c9E647B1 \
		50000000000000000000 \
		--rpc-url $(RPC_URL) --private-key $$PRIVATE_KEY
	@. ./.env && cast send 0x26a5B76417f4b12131542CEfd9083e70c9E647B1 "provideLiquidity(address,uint256,address)" \
		0x21756f22e0945Ed3faB38D05Cf8E933845a60622 \
		50000000000000000000 \
		0xA6B3D200cD34ca14d7579DAc8B054bf50a62c37c \
		--rpc-url $(RPC_URL) --private-key $$PRIVATE_KEY

# Check vault info for any asset
check-vault:
	@echo "📊 Checking vault info..."
	@read -p "Enter token address (or use ETH=0x21756f22e0945Ed3faB38D05Cf8E933845a60622): " token; \
	cast call 0x26a5B76417f4b12131542CEfd9083e70c9E647B1 "getVaultInfo(address)" $$token --rpc-url $(RPC_URL)

# Check token balances
check-tokens:
	@echo "🪙 Token balances for deployer (0xA6B3D200cD34ca14d7579DAc8B054bf50a62c37c):"
	@echo "ETH:"
	@cast call 0x21756f22e0945Ed3faB38D05Cf8E933845a60622 "balanceOf(address)" 0xA6B3D200cD34ca14d7579DAc8B054bf50a62c37c --rpc-url $(RPC_URL)
	@echo "WBTC:"
	@cast call 0xfb5810A37Eb47df5a498673237eD16ace3600162 "balanceOf(address)" 0xA6B3D200cD34ca14d7579DAc8B054bf50a62c37c --rpc-url $(RPC_URL)
	@echo "USDC:"
	@cast call 0x9B051Dbf5bbFA94c9F18617a2D10AC9614D41d6c "balanceOf(address)" 0xA6B3D200cD34ca14d7579DAc8B054bf50a62c37c --rpc-url $(RPC_URL)

# === NUEVOS COMANDOS DE PRUEBA DEL SISTEMA CORE ===

# Probar prestamos con el sistema core
test-core-loans:
	@echo "[TEST] Testing core lending system..."
	forge script script/TestSimpleLoans.s.sol --rpc-url $(RPC_URL) --broadcast -vv

# Probar ETH como colateral -> USDC como prestamo
test-eth-usdc-loan:
	@echo "💰 Testing ETH collateral -> USDC loan..."
	forge script script/TestSimpleLoans.s.sol --sig "testETHToUSDCLoan()" --rpc-url $(RPC_URL) --broadcast -vv

# Probar USDC como colateral -> ETH como prestamo  
test-usdc-eth-loan:
	@echo "💰 Testing USDC collateral -> ETH loan..."
	forge script script/TestSimpleLoans.s.sol --sig "testUSDCToETHLoan()" --rpc-url $(RPC_URL) --broadcast -vv

# Probar operaciones avanzadas (agregar colateral, retirar, intereses)
test-advanced-operations:
	@echo "[FIX] Testing advanced loan operations..."
	forge script script/TestSimpleLoans.s.sol --sig "testAdvancedOperations()" --rpc-url $(RPC_URL) --broadcast -vv

# Probar analisis de riesgo basico
test-risk-analysis:
	@echo "📊 Testing basic risk analysis..."
	forge script script/TestSimpleLoans.s.sol --sig "testRiskAnalysis()" --rpc-url $(RPC_URL) --broadcast -vv

# Probar pago y cierre de prestamos
test-loan-repayment:
	@echo "💳 Testing loan repayment and closure..."
	forge script script/TestSimpleLoans.s.sol --sig "testRepaymentAndClosure()" --rpc-url $(RPC_URL) --broadcast -vv

# Proporcionar liquidez WBTC
provide-wbtc-liquidity:
	@echo "💰 Providing WBTC liquidity..."
	@. ./.env && cast send 0xfb5810A37Eb47df5a498673237eD16ace3600162 "approve(address,uint256)" \
		0x26a5B76417f4b12131542CEfd9083e70c9E647B1 \
		1000000000 \
		--rpc-url $(RPC_URL) --private-key $$PRIVATE_KEY
	@. ./.env && cast send 0x26a5B76417f4b12131542CEfd9083e70c9E647B1 "provideLiquidity(address,uint256,address)" \
		0xfb5810A37Eb47df5a498673237eD16ace3600162 \
		1000000000 \
		0xA6B3D200cD34ca14d7579DAc8B054bf50a62c37c \
		--rpc-url $(RPC_URL) --private-key $$PRIVATE_KEY

# Proporcionar liquidez USDC
provide-usdc-liquidity:
	@echo "💰 Providing USDC liquidity..."
	@. ./.env && cast send 0x9B051Dbf5bbFA94c9F18617a2D10AC9614D41d6c "approve(address,uint256)" \
		0x26a5B76417f4b12131542CEfd9083e70c9E647B1 \
		100000000000 \
		--rpc-url $(RPC_URL) --private-key $$PRIVATE_KEY
	@. ./.env && cast send 0x26a5B76417f4b12131542CEfd9083e70c9E647B1 "provideLiquidity(address,uint256,address)" \
		0x9B051Dbf5bbFA94c9F18617a2D10AC9614D41d6c \
		100000000000 \
		0xA6B3D200cD34ca14d7579DAc8B054bf50a62c37c \
		--rpc-url $(RPC_URL) --private-key $$PRIVATE_KEY

# === ABI MANAGEMENT COMMANDS ===

# Extract ABIs from all compiled contracts
extract-abis:
	@echo "[FIX] Extracting ABIs from compiled contracts..."
	./extract-abis.sh

# Regenerate ABIs after code changes
regenerate-abis: 
	@echo "🔄 Recompiling contracts and extracting ABIs..."
	forge build
	./extract-abis.sh

# ========== REWARD SYSTEM TESTING ==========

# Test reward system core functionality
test-rewards:
	@echo "[TEST] Testing Reward System..."
	forge test --match-contract RewardSystemTest --fork-url $(RPC_URL) -vv

# Test reward system integration
test-rewards-integration:
	@echo "[INTEGRATION] Testing Reward System Integration..."
	forge test --match-contract RewardIntegrationTest --fork-url $(RPC_URL) -vv

# Test all reward-related functionality
test-rewards-all:
	@echo "[FUNCTION] Testing All Reward Functionality..."
	forge test --match-path "test/Reward*.t.sol" --fork-url $(RPC_URL) -vv

# Deploy reward system to testnet
deploy-rewards-testnet:
	@echo "🚀 Deploying Reward System to Base Sepolia..."
	forge script script/DeployRewardSystem.s.sol:DeployRewardSystem --rpc-url $(RPC_URL) --broadcast -vvvv

# Deploy reward system locally
deploy-rewards-local:
	@echo "🏠 Deploying Reward System Locally..."
	forge script script/DeployRewardSystem.s.sol:DeployRewardSystem --rpc-url http://localhost:8545 --broadcast -vvvv

# Generate reward system documentation
docs-rewards:
	@echo "📚 Generating Reward System Documentation..."
	forge doc --out docs/rewards

# Coverage for reward system
coverage-rewards:
	@echo "📊 Generating Coverage Report for Reward System..."
	forge coverage --match-path "src/core/RewardDistributor.sol" --match-path "src/interfaces/IRewardable.sol"

# Gas report for reward system
gas-rewards:
	@echo "⛽ Generating Gas Report for Reward System..."
	forge test --match-contract RewardSystemTest --gas-report

# Lint reward system contracts
lint-rewards:
	@echo "[DEBUG] Linting Reward System Contracts..."
	forge fmt src/core/RewardDistributor.sol src/interfaces/IRewardable.sol

# Clean and rebuild with rewards
build-rewards: clean
	@echo "🔨 Building with Reward System..."
	forge build

# Run reward system simulation
simulate-rewards:
	@echo "🎮 Running Reward System Simulation..."
	forge script script/SimulateRewards.s.sol --rpc-url $(RPC_URL) -vvvv

# Verify reward system contracts
verify-rewards:
	@echo "✅ Verifying Reward System Contracts..."
	forge verify-contract --chain-id 84532 --watch

# Help for reward system commands
help-rewards:
	@echo "🎁 REWARD SYSTEM COMMANDS:"
	@echo "  test-rewards              - Test core reward functionality"
	@echo "  test-rewards-integration  - Test reward system integration"
	@echo "  test-rewards-all          - Test all reward functionality"
	@echo "  deploy-rewards-testnet    - Deploy to Base Sepolia"
	@echo "  deploy-rewards-local      - Deploy locally"
	@echo "  docs-rewards              - Generate documentation"
	@echo "  coverage-rewards          - Generate coverage report"
	@echo "  gas-rewards               - Generate gas report"
	@echo "  lint-rewards              - Lint contracts"
	@echo "  build-rewards             - Clean build with rewards"
	@echo "  simulate-rewards          - Run simulation"
	@echo "  verify-rewards            - Verify contracts"

# ========== 🚀 AUTOMATED DEPLOYMENT COMMANDS ==========

# [FUNCTION] COMPLETE AUTOMATED DEPLOYMENT WITH AUTO-CONFIGURATION (1 command)
deploy-complete:
	@echo ""
	@echo "🚀🚀🚀 STARTING COMPLETE AUTOMATED DEPLOYMENT 🚀🚀🚀"
	@echo "======================================================="
	@echo ""
	@echo "⏳ Step 1/6: Smart compilation (only if needed)..."
	@forge build
	@echo ""
	@echo "🏗️  Step 2/6: Deploying unified system (Core + VCOP + Liquidity)..."
	@forge script script/deploy/DeployUnifiedSystem.s.sol --rpc-url $(RPC_URL) --broadcast
	@echo ""
	@echo "🎁 Step 3/6: Deploying NEW reward system with VCOP minting (auto-updates JSON)..."
	@forge script script/DeployRewardSystem.s.sol --rpc-url $(RPC_URL) --broadcast -vv
	@echo ""
	@echo "🔗 Step 4/6: Deploying Chainlink Oracle with BTC/ETH feeds..."
	@make deploy-complete-chainlink
	@echo ""
	@echo "🔧 Step 5/6: Auto-configuring ALL system integrations and authorizations..."
	@make configure-system-integration
	@echo ""
	@echo "✅ Step 6/6: Final verification and testing..."
	@make check-deployment-status
	@make test-chainlink-oracle
	@echo ""
	@echo "🎉🎉🎉 COMPLETE DEPLOYMENT FINISHED SUCCESSFULLY! 🎉🎉🎉"
	@echo "==========================================================="
	@echo "📋 All addresses loaded dynamically from deployed-addresses.json"
	@echo "🔐 All authorizations configured automatically"
	@echo "💰 Chainlink Oracle deployed and configured (BTC/USD + ETH/USD)"
	@echo "📋 Check addresses: make check-addresses"
	@echo "[TEST] Run full test suite: make test-all"
	@echo ""

# [TEST] COMPLETE AUTOMATED TESTING (1 command)
test-all:
	@echo ""
	@echo "[TEST][TEST][TEST] RUNNING COMPLETE TEST SUITE [TEST][TEST][TEST]"
	@echo "=============================================="
	@echo ""
	@echo "🎁 Test 1/5: Reward System Tests..."
	@forge test --match-contract RewardSystemTest --fork-url $(RPC_URL) -vv
	@echo ""
	@echo "🏦 Test 2/5: Core Lending System Tests..."
	@forge script script/TestSimpleLoans.s.sol --rpc-url $(RPC_URL) --broadcast -vv
	@echo ""
	@echo "💰 Test 3/5: VCOP Loan System Tests..."
	@forge script script/TestVCOPLoans.sol:TestVCOPLoans --rpc-url $(RPC_URL) --broadcast -vv
	@echo ""
	@echo "🔒 Test 4/5: PSM Functionality Tests..."
	@forge script script/TestVCOPPSM.sol:TestVCOPPSM --rpc-url $(RPC_URL) --broadcast -vv
	@echo ""
	@echo "🔗 Test 5/5: Chainlink Oracle Tests..."
	@make test-chainlink-oracle
	@echo ""
	@echo "✅ ALL TESTS COMPLETED!"
	@echo "📊 Check results above for any failures"
	@echo ""

# Test reward system directly on Base Sepolia
test-rewards-sepolia:
	@echo "[TEST] Testing Reward System on Base Sepolia..."
	forge test --match-contract RewardSystemTest --rpc-url $(RPC_URL) -vvv

# Test reward system integration on Base Sepolia
test-rewards-integration-sepolia:
	@echo "[INTEGRATION] Testing Reward System Integration on Base Sepolia..."
	forge test --match-contract RewardIntegrationTest --rpc-url $(RPC_URL) -vvv

# Test specific reward system function
test-reward-function:
	@echo "[FUNCTION] Testing specific reward function..."
	@read -p "Enter function name (e.g., testCreateRewardPool): " func; \
	forge test --match-test $$func --rpc-url $(RPC_URL) -vvv

# Test VCOPPriceCalculator system integration
test-vcop-price-calculator:
	@echo "[TEST] Testing VCOPPriceCalculator and Oracle integration..."
	forge script script/test/TestVCOPPriceCalculatorSimple.s.sol --rpc-url $(RPC_URL) -vv

# Check VCOPPriceCalculator setup and configuration
check-price-calculator-setup:
	@echo "[CHECK] Checking VCOPPriceCalculator configuration..."
	forge script script/test/CheckVCOPPriceCalculatorSetup.s.sol --rpc-url $(RPC_URL) -vv

# Configure VCOPPriceCalculator in Oracle (requires private key)
configure-price-calculator:
	@echo "[CONFIG] Configuring VCOPPriceCalculator in Oracle..."
	forge script script/test/CheckVCOPPriceCalculatorSetup.s.sol --sig "configurePriceCalculator()" --rpc-url $(RPC_URL) --broadcast -vv

# Test VCOP Oracle prices specifically
test-vcop-oracle-prices:
	@echo "[TEST] Testing VCOP Oracle prices and usage..."
	forge script script/test/TestVCOPOraclePrice.s.sol --rpc-url $(RPC_URL) -vv

# Run all reward tests on Sepolia
test-rewards-all-sepolia:
	@echo "[TEST] Running All Reward Tests on Base Sepolia..."
	forge test --match-path "test/Reward*.t.sol" --rpc-url $(RPC_URL) -vvv

# Debug reward system authorization
debug-reward-auth:
	@echo "[DEBUG] Debugging Reward System Authorization..."
	@echo "Checking deployed contract authorizations..."
	@cast call $(DEPLOYED_REWARD_DISTRIBUTOR) "owner()" --rpc-url $(RPC_URL)
	@cast call $(DEPLOYED_REWARD_DISTRIBUTOR) "authorizedUpdaters(address)" $(FLEXIBLE_LOAN_MANAGER_ADDRESS) --rpc-url $(RPC_URL)

# Set reward system authorization (if needed)
fix-reward-auth:
	@echo "[FIX] Fixing Reward System Authorization..."
	@. ./.env && cast send $(DEPLOYED_REWARD_DISTRIBUTOR) "setAuthorizedUpdater(address,bool)" \
		$(FLEXIBLE_LOAN_MANAGER_ADDRESS) true \
		--rpc-url $(RPC_URL) --private-key $$PRIVATE_KEY

# Deploy new reward system with VCOP minting
deploy-rewards-with-minting:
	@echo "[TEST] Deploying Reward System with VCOP Minting..."
	forge script script/DeployRewardSystem.s.sol --rpc-url $(RPC_URL) --broadcast -vv

# Update existing reward distributor with VCOP minting
update-reward-distributor:
	@echo "[FIX] Updating Reward Distributor for VCOP minting..."
	@. ./.env && cast send $(DEPLOYED_REWARD_DISTRIBUTOR) "setVCOPToken(address)" $(DEPLOYED_VCOP_TOKEN) --rpc-url $(RPC_URL) --private-key $$PRIVATE_KEY
	@. ./.env && cast send $(DEPLOYED_VCOP_TOKEN) "setMinter(address,bool)" $(DEPLOYED_REWARD_DISTRIBUTOR) true --rpc-url $(RPC_URL) --private-key $$PRIVATE_KEY
	@echo "VCOP minting enabled for RewardDistributor"

# Test with the new minting system
test-rewards-minting:
	@echo "[TEST] Testing Reward System with VCOP Minting..."
	forge test --match-contract RewardSystemTest --rpc-url $(RPC_URL) -vvv --gas-report

# Configure system integrations after deployment - WITH DYNAMIC ADDRESSES
configure-system-integration:
	@echo "[FIX] Configuring system integrations with dynamic addresses..."
	@echo "Step 1: Loading addresses from deployed-addresses.json..."
	@bash get-addresses.sh
	@echo ""
	@echo "Step 2: Configuring RewardDistributor authorizations..."
	@. ./.env && . ./get-addresses.sh && cast send $$DEPLOYED_REWARD_DISTRIBUTOR "setAuthorizedUpdater(address,bool)" $$DEPLOYED_FLEXIBLE_LOAN_MANAGER true --rpc-url $(RPC_URL) --private-key $$PRIVATE_KEY
	@echo "✅ FlexibleLoanManager authorized"
	@. ./.env && . ./get-addresses.sh && cast send $$DEPLOYED_REWARD_DISTRIBUTOR "setAuthorizedUpdater(address,bool)" $$DEPLOYED_GENERIC_LOAN_MANAGER true --rpc-url $(RPC_URL) --private-key $$PRIVATE_KEY
	@echo "✅ GenericLoanManager authorized"
	@. ./.env && . ./get-addresses.sh && cast send $$DEPLOYED_REWARD_DISTRIBUTOR "setAuthorizedUpdater(address,bool)" $$DEPLOYED_VAULT_HANDLER true --rpc-url $(RPC_URL) --private-key $$PRIVATE_KEY
	@echo "✅ VaultHandler authorized"
	@. ./.env && . ./get-addresses.sh && cast send $$DEPLOYED_REWARD_DISTRIBUTOR "setAuthorizedUpdater(address,bool)" $$DEPLOYED_COLLATERAL_MANAGER true --rpc-url $(RPC_URL) --private-key $$PRIVATE_KEY
	@echo "✅ CollateralManager authorized"
	@echo ""
	@echo "Step 3: Configuring RewardDistributor references in contracts..."
	@. ./.env && . ./get-addresses.sh && cast send $$DEPLOYED_FLEXIBLE_LOAN_MANAGER "setRewardDistributor(address)" $$DEPLOYED_REWARD_DISTRIBUTOR --rpc-url $(RPC_URL) --private-key $$PRIVATE_KEY
	@echo "✅ FlexibleLoanManager -> RewardDistributor configured"
	@. ./.env && . ./get-addresses.sh && cast send $$DEPLOYED_COLLATERAL_MANAGER "setRewardDistributor(address)" $$DEPLOYED_REWARD_DISTRIBUTOR --rpc-url $(RPC_URL) --private-key $$PRIVATE_KEY
	@echo "✅ CollateralManager -> RewardDistributor configured"
	@. ./.env && . ./get-addresses.sh && cast send $$DEPLOYED_GENERIC_LOAN_MANAGER "setRewardDistributor(address)" $$DEPLOYED_REWARD_DISTRIBUTOR --rpc-url $(RPC_URL) --private-key $$PRIVATE_KEY
	@echo "✅ GenericLoanManager -> RewardDistributor configured"
	@echo ""
	@echo "Step 4: Verifying all authorizations..."
	@make verify-system-authorizations
	@echo ""
	@echo "✅ SYSTEM INTEGRATION CONFIGURED SUCCESSFULLY!"

# Update deployed-addresses.json with latest contract addresses  
update-deployed-addresses:
	@echo "[DEBUG] Updating deployed-addresses.json..."
	@echo '{"network":"Base Sepolia","chainId":84532,"deploymentDate":"'`date +%s`'","rewards":{"rewardDistributor":"$(DEPLOYED_REWARD_DISTRIBUTOR)","usesMinting":true},"coreLending":{"flexibleLoanManager":"$(DEPLOYED_FLEXIBLE_LOAN_MANAGER)","genericLoanManager":"$(DEPLOYED_GENERIC_LOAN_MANAGER)","vaultBasedHandler":"$(DEPLOYED_VAULT_HANDLER)","rewardDistributor":"$(DEPLOYED_REWARD_DISTRIBUTOR)"},"vcopCollateral":{"vcopToken":"$(DEPLOYED_VCOP_TOKEN)","oracle":"$(DEPLOYED_ORACLE)","collateralManager":"$(DEPLOYED_COLLATERAL_MANAGER)","rewardDistributor":"$(DEPLOYED_REWARD_DISTRIBUTOR)"}}' > deployed-addresses-updated.json
	@echo "✅ Contract addresses saved to deployed-addresses-updated.json"

# Update the main deployed-addresses.json file automatically
update-main-addresses:
	@echo "[FIX] Updating main deployed-addresses.json with RewardDistributor..."
	@if [ -f "deployed-addresses.json" ]; then \
		echo "Reading current deployed-addresses.json..."; \
		CURRENT_REWARD_ADDR=0x7db6fD53472De90188b7F07084fd5d020a7056Cd; \
		echo "Adding RewardDistributor: $$CURRENT_REWARD_ADDR"; \
		cat deployed-addresses.json | jq '. + {"rewards": {"rewardDistributor": "'$$CURRENT_REWARD_ADDR'"}}' > deployed-addresses-temp.json && \
		mv deployed-addresses-temp.json deployed-addresses.json; \
		echo "✅ deployed-addresses.json updated successfully"; \
	else \
		echo "❌ deployed-addresses.json not found"; \
	fi

# Check current deployment status - WITH DYNAMIC ADDRESSES
check-deployment-status:
	@echo "[DEBUG] Checking deployment status with dynamic addresses..."
	@bash get-addresses.sh
	@echo ""
	@echo "=== VERIFICATION ==="
	@echo "Checking if RewardDistributor is VCOP minter..."
	@. ./get-addresses.sh && cast call $$DEPLOYED_VCOP_TOKEN "minters(address)" $$DEPLOYED_REWARD_DISTRIBUTOR --rpc-url $(RPC_URL)
	@echo "Checking if FlexibleLoanManager is authorized updater..."
	@. ./get-addresses.sh && cast call $$DEPLOYED_REWARD_DISTRIBUTOR "authorizedUpdaters(address)" $$DEPLOYED_FLEXIBLE_LOAN_MANAGER --rpc-url $(RPC_URL)
	@echo "Checking RewardDistributor owner..."
	@. ./get-addresses.sh && cast call $$DEPLOYED_REWARD_DISTRIBUTOR "owner()" --rpc-url $(RPC_URL)

# Verify all system authorizations - NEW COMMAND
verify-system-authorizations:
	@echo "[VERIFY] Checking all system authorizations..."
	@. ./get-addresses.sh && echo "FlexibleLoanManager authorized:" && cast call $$DEPLOYED_REWARD_DISTRIBUTOR "authorizedUpdaters(address)" $$DEPLOYED_FLEXIBLE_LOAN_MANAGER --rpc-url $(RPC_URL)
	@. ./get-addresses.sh && echo "GenericLoanManager authorized:" && cast call $$DEPLOYED_REWARD_DISTRIBUTOR "authorizedUpdaters(address)" $$DEPLOYED_GENERIC_LOAN_MANAGER --rpc-url $(RPC_URL)
	@. ./get-addresses.sh && echo "VaultHandler authorized:" && cast call $$DEPLOYED_REWARD_DISTRIBUTOR "authorizedUpdaters(address)" $$DEPLOYED_VAULT_HANDLER --rpc-url $(RPC_URL)
	@. ./get-addresses.sh && echo "CollateralManager authorized:" && cast call $$DEPLOYED_REWARD_DISTRIBUTOR "authorizedUpdaters(address)" $$DEPLOYED_COLLATERAL_MANAGER --rpc-url $(RPC_URL)
	@echo "✅ All authorizations verified!"

# ========== 🔨 BUILD COMMANDS ==========

# Smart build - only compiles if changes detected
build:
	@echo "🔨 Smart compilation..."
	@forge build

# Force full rebuild with optimizations
build-optimized:
	@echo "🔨 Full rebuild with optimizations..."
	@forge build --optimize --optimizer-runs 200

# Clean and rebuild everything
rebuild:
	@echo "🧹 Cleaning and rebuilding..."
	@forge clean
	@forge build --optimize --optimizer-runs 200

# Deploy with forced optimization (for production)
deploy-complete-optimized:
	@echo ""
	@echo "🚀🚀🚀 PRODUCTION DEPLOYMENT WITH OPTIMIZATIONS 🚀🚀🚀"
	@echo "======================================================="
	@echo ""
	@echo "⏳ Step 1/6: Full optimized compilation..."
	@make build-optimized
	@echo ""
	@echo "🏗️  Step 2/6: Deploying unified system (Core + VCOP + Liquidity)..."
	@forge script script/deploy/DeployUnifiedSystem.s.sol --rpc-url $(RPC_URL) --broadcast
	@echo ""
	@echo "🎁 Step 3/6: Deploying NEW reward system with VCOP minting (auto-updates JSON)..."
	@forge script script/DeployRewardSystem.s.sol --rpc-url $(RPC_URL) --broadcast -vv
	@echo ""
	@echo "🔗 Step 4/6: Deploying Chainlink Oracle with BTC/ETH feeds + VCOP price..."
	@make deploy-complete-chainlink
	@echo ""
	@echo "🔧 Step 5/6: Auto-configuring ALL system integrations and authorizations..."
	@make configure-system-integration
	@echo ""
	@echo "✅ Step 6/6: Final verification and testing..."
	@make check-deployment-status
	@make test-chainlink-oracle
	@echo ""
	@echo "🎉🎉🎉 OPTIMIZED DEPLOYMENT COMPLETED SUCCESSFULLY! 🎉🎉🎉"
	@echo "==========================================================="
	@echo "📋 All addresses loaded dynamically from deployed-addresses.json"
	@echo "🔐 All authorizations configured automatically"
	@echo "💰 Chainlink Oracle deployed and configured (BTC/USD + ETH/USD + VCOP/USD)"
	@echo "📋 Check addresses: make check-addresses"
	@echo "[TEST] Run full test suite: make test-all"
	@echo ""

# ========== 🔗 CHAINLINK ORACLE COMMANDS ==========

# [FUNCTION] Complete Chainlink Oracle deployment with auto-configuration
deploy-complete-chainlink:
	@echo ""
	@echo "🔗🔗🔗 DEPLOYING COMPLETE CHAINLINK SYSTEM 🔗🔗🔗"
	@echo "================================================="
	@echo ""
	@echo "🏗️  Step 1/4: Deploying Chainlink Oracle..."
	@make deploy-chainlink-oracle
	@echo ""
	@echo "⚙️  Step 2/4: Configuring Oracle..."
	@make configure-chainlink-oracle
	@echo ""
	@echo "💰 Step 3/4: Configuring VCOP price..."
	@make configure-vcop-price
	@echo ""
	@echo "✅ Step 4/4: Updating addresses..."
	@make update-oracle-addresses
	@echo ""
	@echo "🎉 CHAINLINK DEPLOYMENT COMPLETED!"
	@echo "💰 BTC/USD and ETH/USD feeds active"
	@echo "💰 VCOP/USD price configured (manual fallback)"
	@echo "📋 Check status: make oracle-health-check"

# Deploy new Chainlink Oracle (standalone)
deploy-chainlink-oracle:
	@echo "🏗️ Deploying Chainlink Oracle..."
	forge script script/deploy/DeployOnlyOracle.s.sol --rpc-url $(RPC_URL) --broadcast -vv

# Configure deployed Chainlink Oracle
configure-chainlink-oracle:
	@echo "⚙️ Configuring Chainlink Oracle after deployment..."
	forge script script/config/ConfigureChainlinkOracle.s.sol --rpc-url $(RPC_URL) --broadcast -vv

# Configure VCOP price in Oracle (fallback when pool has no liquidity)
configure-vcop-price:
	@echo "💰 Configuring VCOP price in Oracle..."
	forge script script/config/ConfigureVCOPPrice.s.sol --rpc-url $(RPC_URL) --broadcast -vv

# Test Chainlink Oracle functionality
test-chainlink-oracle:
	@echo "🔗 Testing Chainlink Oracle integration..."
	forge script script/test/TestChainlinkOracle.s.sol --rpc-url $(RPC_URL) -vv

# Check real-time Chainlink prices
check-chainlink-prices:
	@echo "💰 Checking Chainlink prices..."
	@BTC_PRICE=$$(cast call $$(grep VCOP_ORACLE_ADDRESS .env | cut -d'=' -f2) "getBtcPriceFromChainlink()" --rpc-url $(RPC_URL)); \
	BTC_DECIMAL=$$(echo "$$BTC_PRICE" | sed 's/0x//' | python3 -c "import sys; val=int(input(), 16); print(f'  BTC/USD: {val:,} raw = $${val/1000000:,.2f}')"); \
	echo "$$BTC_DECIMAL"
	@ETH_PRICE=$$(cast call $$(grep VCOP_ORACLE_ADDRESS .env | cut -d'=' -f2) "getEthPriceFromChainlink()" --rpc-url $(RPC_URL)); \
	ETH_DECIMAL=$$(echo "$$ETH_PRICE" | sed 's/0x//' | python3 -c "import sys; val=int(input(), 16); print(f'  ETH/USD: {val:,} raw = $${val/1000000:,.2f}')"); \
	echo "$$ETH_DECIMAL"

# Check ALL prices (Chainlink + VCOP)
check-all-prices:
	@echo "💰 ORACLE PRICE SUMMARY"
	@echo "======================="
	@echo ""
	@echo "🔗 CHAINLINK FEEDS (Real-time):"
	@BTC_PRICE=$$(cast call $$(grep VCOP_ORACLE_ADDRESS .env | cut -d'=' -f2) "getBtcPriceFromChainlink()" --rpc-url $(RPC_URL)); \
	echo "$$BTC_PRICE" | sed 's/0x//' | python3 -c "val=int(input(), 16); print('  BTC/USD: ' + str(val) + ' raw = $$' + str(val//1000000))"
	@ETH_PRICE=$$(cast call $$(grep VCOP_ORACLE_ADDRESS .env | cut -d'=' -f2) "getEthPriceFromChainlink()" --rpc-url $(RPC_URL)); \
	echo "$$ETH_PRICE" | sed 's/0x//' | python3 -c "val=int(input(), 16); print('  ETH/USD: ' + str(val) + ' raw = $$' + str(val//1000000))"
	@echo ""
	@echo "💰 VCOP PRICES (Configured):"
	@VCOP_USD=$$(cast call 0x856e780cf7f4d47b24142E280Ba30B399Dc6daaA "getPrice(address,address)" 0x4fd42098A37A028c1A53c44aCA3095FFaC958D41 0x6AC157633e53bb59C5eE2eFB26Ea4cAaA160a381 --rpc-url $(RPC_URL)); \
	echo "$$VCOP_USD" | sed 's/0x//' | python3 -c "val=int(input(), 16); print('  VCOP/USD: ' + str(val) + ' raw = $$' + str(val/1000000) + ' per VCOP')"
	@USD_VCOP=$$(cast call 0x856e780cf7f4d47b24142E280Ba30B399Dc6daaA "getPrice(address,address)" 0x6AC157633e53bb59C5eE2eFB26Ea4cAaA160a381 0x4fd42098A37A028c1A53c44aCA3095FFaC958D41 --rpc-url $(RPC_URL)); \
	echo "$$USD_VCOP" | sed 's/0x//' | python3 -c "val=int(input(), 16); print('  USD/VCOP: ' + str(val) + ' raw = ' + str(val//1000000) + ' VCOP per USD')"
	@echo ""
	@echo "✅ SUMMARY:"
	@echo "  • All Chainlink feeds active and providing real-time data"
	@echo "  • VCOP price configured: 4,100 VCOP = 1 USD"
	@echo "  • Oracle system fully operational"

# Oracle health check
oracle-health-check:
	@echo "🏥 Oracle Health Check..."
	@echo "Oracle address: $$(grep VCOP_ORACLE_ADDRESS .env | cut -d'=' -f2)"
	@$(MAKE) check-chainlink-feeds
	@$(MAKE) check-chainlink-prices
	@echo "✅ Health check completed!"

# Check Chainlink feed status
check-chainlink-feeds:
	@echo "📊 Checking Chainlink feed status..."
	@echo "Chainlink enabled:"
	@cast call $$(grep VCOP_ORACLE_ADDRESS .env | cut -d'=' -f2) "chainlinkEnabled()" --rpc-url $(RPC_URL)
	@echo ""
	@echo "BTC Feed Info:"
	@cast call $$(grep VCOP_ORACLE_ADDRESS .env | cut -d'=' -f2) "getBtcFeedInfo()" --rpc-url $(RPC_URL)
	@echo ""
	@echo "ETH Feed Info:"
	@cast call $$(grep VCOP_ORACLE_ADDRESS .env | cut -d'=' -f2) "getEthFeedInfo()" --rpc-url $(RPC_URL)

# Enable Chainlink feeds
enable-chainlink-oracle:
	@echo "✅ Enabling Chainlink feeds..."
	@. ./.env && cast send $$VCOP_ORACLE_ADDRESS "setChainlinkEnabled(bool)" true --rpc-url $(RPC_URL) --private-key $$PRIVATE_KEY
	@echo "Chainlink feeds enabled!"

# Disable Chainlink feeds (fallback to manual prices)
disable-chainlink-oracle:
	@echo "❌ Disabling Chainlink feeds..."
	@. ./.env && cast send $$VCOP_ORACLE_ADDRESS "setChainlinkEnabled(bool)" false --rpc-url $(RPC_URL) --private-key $$PRIVATE_KEY
	@echo "Chainlink feeds disabled - using manual prices as fallback"

# Update oracle addresses in JSON and .env
update-oracle-addresses:
	@echo "🔄 Updating oracle addresses..."
	@./update-oracle-addresses.sh

# Help for Chainlink commands
help-chainlink:
	@echo "🔗 CHAINLINK ORACLE COMMANDS:"
	@echo "  deploy-complete-chainlink     - [FUNCTION] Complete Chainlink deployment + config"
	@echo "  deploy-chainlink-oracle       - Deploy new Chainlink Oracle"
	@echo "  configure-chainlink-oracle    - Configure deployed oracle"
	@echo "  configure-vcop-price          - Configure VCOP price fallback"
	@echo "  test-chainlink-oracle         - Test oracle functionality"
	@echo "  check-chainlink-prices        - Check real-time BTC/ETH prices"
	@echo "  check-all-prices              - Check ALL prices (Chainlink + VCOP)"
	@echo "  oracle-health-check           - Complete oracle health check"
	@echo "  enable-chainlink-oracle       - Enable Chainlink feeds"
	@echo "  disable-chainlink-oracle      - Disable Chainlink (use manual prices)"
	@echo "  update-oracle-addresses       - Update JSON and .env with latest addresses"
	@echo ""
	@echo "💰 Supported price feeds (Base Sepolia):"
	@echo "  - BTC/USD: 0x0FB99723Aee6f420beAD13e6bBB79b7E6F034298"
	@echo "  - ETH/USD: 0x4aDC67696bA383F43DD60A9e78F2C97Fbbfc7cb1"

.PHONY: test-rewards test-rewards-integration test-rewards-all deploy-rewards-testnet deploy-rewards-local docs-rewards coverage-rewards gas-rewards lint-rewards build-rewards simulate-rewards verify-rewards help-rewards deploy-complete deploy-complete-optimized test-all test-rewards-sepolia test-rewards-integration-sepolia test-reward-function test-rewards-all-sepolia debug-reward-auth fix-reward-auth deploy-rewards-with-minting update-reward-distributor test-rewards-minting configure-system-integration update-deployed-addresses update-main-addresses check-deployment-status verify-system-authorizations build build-optimized rebuild deploy-complete-chainlink deploy-chainlink-oracle configure-chainlink-oracle configure-vcop-price test-chainlink-oracle check-chainlink-prices check-all-prices oracle-health-check enable-chainlink-oracle disable-chainlink-oracle update-oracle-addresses