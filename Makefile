# Network configuration
RPC_URL := https://sepolia.base.org
MAINNET_RPC_URL := https://mainnet.base.org

# Chain IDs
BASE_SEPOLIA_CHAIN_ID := 84532
BASE_MAINNET_CHAIN_ID := 8453

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
	@echo "🔍 Verifying contract..."
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
	@echo "🧪 Testing core lending system..."
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
	@echo "🔧 Testing advanced loan operations..."
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