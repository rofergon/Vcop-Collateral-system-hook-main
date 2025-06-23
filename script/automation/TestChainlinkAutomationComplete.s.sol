// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {IERC20} from "v4-core/lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {FlexibleLoanManager} from "../../src/core/FlexibleLoanManager.sol";
import {VaultBasedHandler} from "../../src/core/VaultBasedHandler.sol";
import {LoanAutomationKeeperOptimized} from "../../src/automation/core/LoanAutomationKeeperOptimized.sol";
import {LoanManagerAutomationAdapter} from "../../src/automation/core/LoanManagerAutomationAdapter.sol";
import {PriceChangeLogTrigger} from "../../src/automation/core/PriceChangeLogTrigger.sol";
import {MockVCOPOracle} from "../../src/VcopCollateral/MockVCOPOracle.sol";
import {ILoanManager} from "../../src/interfaces/ILoanManager.sol";

/**
 * @title TestChainlinkAutomationComplete
 * @notice SCRIPT COMPLETO de testing para verificar automatización Chainlink
 * @dev Upkeep ID: 113929943640819780336579342444342105693806060483669440168281813464087586560700
 */
contract TestChainlinkAutomationComplete is Script {
    
    // ========== CONFIGURACIÓN DEL SISTEMA ==========
    
    struct SystemAddresses {
        address flexibleLoanManager;
        address vaultBasedHandler;
        address automationKeeper;
        address loanAdapter;
        address priceTrigger;
        address mockOracle;
        address mockETH;
        address mockWBTC;
        address mockUSDC;
        address vcopToken;
    }
    
    SystemAddresses public addrs;
    
    // Contratos
    FlexibleLoanManager public loanManager;
    VaultBasedHandler public vaultHandler;
    LoanAutomationKeeperOptimized public keeper;
    LoanManagerAutomationAdapter public adapter;
    PriceChangeLogTrigger public priceTrigger;
    MockVCOPOracle public oracle;
    
    // Configuración de testing
    uint256 public constant UPKEEP_ID = 113929943640819780336579342444342105693806060483669440168281813464087586560700;
    uint256 public testPosition1;
    uint256 public testPosition2;
    uint256 public testPosition3;
    
    // ========== FUNCIONES PRINCIPALES ==========
    
    function run() external {
        console.log("============================================================");
        console.log("CHAINLINK AUTOMATION TESTING SUITE");
        console.log("Upkeep ID:", UPKEEP_ID);
        console.log("============================================================");
        
        loadAddresses();
        initializeContracts();
        
        console.log("");
        console.log(" PHASE 1: SYSTEM ANALYSIS");
        analyzeCurrentConfiguration();
        
        console.log("");
        console.log(" PHASE 2: PREPARE TESTING ENVIRONMENT"); 
        vm.startBroadcast();
        prepareTestingEnvironment();
        
        console.log("");
        console.log(" PHASE 3: CREATE TEST POSITIONS");
        createTestPositions();
        
        console.log("");
        console.log(" PHASE 4: CRASH PRICES & TEST LIQUIDATION");
        testPriceCrashAndLiquidation();
        
        console.log("");
        console.log(" PHASE 5: VERIFY CHAINLINK AUTOMATION");
        verifyChainlinkAutomation();
        vm.stopBroadcast();
        
        console.log("");
        console.log(" PHASE 6: MONITORING DASHBOARD");
        printMonitoringDashboard();
        
        console.log("");
        console.log(" AUTOMATION TESTING COMPLETED!");
    }
    
    // ========== PHASE 1: ANÁLISIS DEL SISTEMA ==========
    
    function loadAddresses() internal {
        console.log("Loading addresses from deployed-addresses-mock.json...");
        
        string memory json = vm.readFile("deployed-addresses-mock.json");
        
        addrs.flexibleLoanManager = vm.parseJsonAddress(json, ".coreLending.flexibleLoanManager");
        addrs.vaultBasedHandler = vm.parseJsonAddress(json, ".coreLending.vaultBasedHandler");
        addrs.automationKeeper = vm.parseJsonAddress(json, ".automation.automationKeeper");
        addrs.loanAdapter = vm.parseJsonAddress(json, ".automation.loanAdapter");
        addrs.priceTrigger = vm.parseJsonAddress(json, ".automation.priceTrigger");
        addrs.mockOracle = vm.parseJsonAddress(json, ".vcopCollateral.mockVcopOracle");
        addrs.mockETH = vm.parseJsonAddress(json, ".tokens.mockETH");
        addrs.mockWBTC = vm.parseJsonAddress(json, ".tokens.mockWBTC");
        addrs.mockUSDC = vm.parseJsonAddress(json, ".tokens.mockUSDC");
        addrs.vcopToken = vm.parseJsonAddress(json, ".tokens.vcopToken");
        
        console.log(" Addresses loaded successfully");
    }
    
    function initializeContracts() internal {
        loanManager = FlexibleLoanManager(addrs.flexibleLoanManager);
        vaultHandler = VaultBasedHandler(addrs.vaultBasedHandler);
        keeper = LoanAutomationKeeperOptimized(addrs.automationKeeper);
        adapter = LoanManagerAutomationAdapter(addrs.loanAdapter);
        priceTrigger = PriceChangeLogTrigger(addrs.priceTrigger);
        oracle = MockVCOPOracle(addrs.mockOracle);
        
        console.log(" Contracts initialized successfully");
    }
    
    function analyzeCurrentConfiguration() internal view {
        console.log(" SYSTEM CONFIGURATION ANALYSIS");
        console.log("----------------------------------------");
        
        // Automation Keeper Analysis
        console.log(" AutomationKeeper Status:");
        console.log("   Address:", address(keeper));
        console.log("   Min Risk Threshold:", keeper.minRiskThreshold());
        console.log("   Max Positions Per Batch:", keeper.maxPositionsPerBatch());
        console.log("   Emergency Pause:", keeper.emergencyPause());
        
        // Loan Manager Analysis
        console.log("");
        console.log(" FlexibleLoanManager Status:");
        console.log("   Address:", address(loanManager));
        console.log("   Automation Enabled:", loanManager.isAutomationEnabled());
        console.log("   Authorized Contract:", loanManager.authorizedAutomationContract());
        console.log("   Next Position ID:", loanManager.nextPositionId());
        
        // Vault Handler Analysis
        console.log("");
        console.log(" VaultBasedHandler Status:");
        console.log("   Address:", address(vaultHandler));
        bool isAuthorized = vaultHandler.authorizedAutomationContracts(address(loanManager));
        console.log("   LoanManager Authorized:", isAuthorized);
        
        // Check USDC liquidity
        try vaultHandler.getAutomationLiquidityStatus(addrs.mockUSDC) returns (
            uint256 available,
            uint256 totalLiquidations,
            uint256 totalRecovered,
            bool canLiquidate
        ) {
            console.log("   Available USDC for automation:", available / 1e6);
            console.log("   Can perform liquidations:", canLiquidate);
        } catch {
            console.log("    Error getting liquidity status");
        }
        
        // Oracle Analysis
        console.log("");
        console.log(" MockVCOPOracle Status:");
        console.log("   Address:", address(oracle));
        (uint256 ethPrice, uint256 btcPrice, uint256 vcopPrice, uint256 usdCopRate) = oracle.getCurrentMarketPrices();
        console.log("   ETH Price: $", ethPrice / 1e6);
        console.log("   BTC Price: $", btcPrice / 1e6);
        console.log("   VCOP Price: $", vcopPrice / 1e6);
        console.log("   USD/COP Rate:", usdCopRate / 1e6);
    }
    
    // ========== PHASE 2: PREPARACIÓN DEL ENTORNO ==========
    
    function prepareTestingEnvironment() internal {
        console.log(" PREPARING TESTING ENVIRONMENT");
        console.log("----------------------------------------");
        
        // 1. Ensure automation is properly configured
        console.log("1. Configuring automation system...");
        
        // Set automation contract in loan manager
        try loanManager.setAutomationContract(address(keeper)) {
            console.log("   Automation contract set in LoanManager");
        } catch {
            console.log("    Already configured or error setting automation contract");
        }
        
        // Enable automation in loan manager
        try loanManager.setAutomationEnabled(true) {
            console.log("   Automation enabled in LoanManager");
        } catch {
            console.log("    Already enabled or error");
        }
        
        // Authorize loan manager in vault
        try vaultHandler.authorizeAutomationContract(address(loanManager)) {
            console.log("   LoanManager authorized in VaultBasedHandler");
        } catch {
            console.log("    Already authorized or error");
        }
        
        // 2. Ensure vault has liquidity
        console.log("");
        console.log("2. Ensuring vault liquidity...");
        
        uint256 vaultBalance = IERC20(addrs.mockUSDC).balanceOf(address(vaultHandler));
        console.log("   Current vault USDC balance:", vaultBalance / 1e6);
        
        if (vaultBalance < 10000 * 1e6) { // Less than 10k USDC
            console.log("   Adding USDC liquidity to vault...");
            
            // Mint USDC to deployer
            (bool success,) = addrs.mockUSDC.call(
                abi.encodeWithSignature("mint(address,uint256)", msg.sender, 50000 * 1e6)
            );
            require(success, "Failed to mint USDC");
            
            // Approve vault handler
            IERC20(addrs.mockUSDC).approve(address(vaultHandler), 50000 * 1e6);
            
            // Provide liquidity
            vaultHandler.provideLiquidity(addrs.mockUSDC, 50000 * 1e6, msg.sender);
            console.log("    Added 50,000 USDC liquidity to vault");
        } else {
            console.log("    Vault has sufficient liquidity");
        }
        
        // 3. Configure realistic prices
        console.log("");
        console.log("3. Setting realistic market prices...");
        oracle.setCurrentMarketDefaults();
        console.log("    Set realistic 2025 market prices");
        
        // 4. Configure mock tokens for testing
        oracle.setMockTokens(addrs.mockETH, addrs.mockWBTC, addrs.mockUSDC);
        console.log("    Mock tokens configured");
    }
    
    // ========== PHASE 3: CREACIÓN DE POSICIONES DE PRUEBA ==========
    
    function createTestPositions() internal {
        console.log(" CREATING TEST POSITIONS");
        console.log("----------------------------------------");
        
        // Configure ETH as collateral asset in vault handler
        console.log("1. Configuring ETH asset in vault handler...");
        try vaultHandler.configureAsset(
            addrs.mockETH,
            1500000, // 150% collateral ratio
            1200000, // 120% liquidation ratio
            1000000 * 1e18, // 1M max loan
            50000    // 5% interest rate
        ) {
            console.log("    ETH configured in vault handler");
        } catch {
            console.log("     ETH already configured or error");
        }
        
        // Create position 1: Healthy position (will become at risk)
        console.log("");
        console.log("2. Creating healthy ETH position...");
        testPosition1 = createEthPosition(2 * 1e18, 3000 * 1e6); // 2 ETH collateral, 3000 USDC loan
        console.log("    Position 1 created:", testPosition1);
        
        // Create position 2: Borderline position (will become liquidatable faster)
        console.log("");
        console.log("3. Creating borderline ETH position...");
        testPosition2 = createEthPosition(1 * 1e18, 2000 * 1e6); // 1 ETH collateral, 2000 USDC loan  
        console.log("    Position 2 created:", testPosition2);
        
        // Create position 3: Another test position
        console.log("");
        console.log("4. Creating another ETH position...");
        testPosition3 = createEthPosition(3 * 1e18, 4500 * 1e6); // 3 ETH collateral, 4500 USDC loan
        console.log("    Position 3 created:", testPosition3);
        
        // Show positions status
        console.log("");
        console.log(" INITIAL POSITIONS STATUS:");
        showPositionStatus(testPosition1, "Position 1");
        showPositionStatus(testPosition2, "Position 2");
        showPositionStatus(testPosition3, "Position 3");
    }
    
    function createEthPosition(uint256 ethAmount, uint256 usdcAmount) internal returns (uint256 positionId) {
        // Mint ETH to deployer
        (bool success,) = addrs.mockETH.call(
            abi.encodeWithSignature("mint(address,uint256)", msg.sender, ethAmount)
        );
        require(success, "Failed to mint ETH");
        
        // Approve loan manager
        IERC20(addrs.mockETH).approve(address(loanManager), ethAmount);
        
        // Create loan terms
        ILoanManager.LoanTerms memory terms = ILoanManager.LoanTerms({
            collateralAsset: addrs.mockETH,
            loanAsset: addrs.mockUSDC,
            collateralAmount: ethAmount,
            loanAmount: usdcAmount,
            maxLoanToValue: 800000, // 80% max LTV
            interestRate: 50000, // 5%
            duration: 0 // Perpetual loan
        });
        
        // Create loan position
        positionId = loanManager.createLoan(terms);
    }
    
    function showPositionStatus(uint256 positionId, string memory label) internal view {
        try loanManager.getCollateralizationRatio(positionId) returns (uint256 ratio) {
            console.log("   %s - Ratio: %s%%", label, ratio / 10000);
            
            (bool isAtRisk, uint256 riskLevel) = adapter.isPositionAtRisk(positionId);
            console.log("   %s - At Risk: %s, Risk Level: %s", label, isAtRisk, riskLevel);
        } catch {
            console.log("   %s - Error getting ratio", label);
        }
    }
    
    // ========== PHASE 4: CRASH DE PRECIOS Y TESTING ==========
    
    function testPriceCrashAndLiquidation() internal {
        console.log(" PRICE CRASH AND LIQUIDATION TESTING");
        console.log("----------------------------------------");
        
        // Show initial prices
        console.log("1. Current prices before crash:");
        (uint256 ethPrice, uint256 btcPrice, uint256 vcopPrice,) = oracle.getCurrentMarketPrices();
        console.log("   ETH: $", ethPrice / 1e6);
        console.log("   BTC: $", btcPrice / 1e6);
        console.log("   VCOP: $", vcopPrice / 1e6);
        
        // Show initial position health
        console.log("");
        console.log("2. Position health before crash:");
        showPositionStatus(testPosition1, "Position 1");
        showPositionStatus(testPosition2, "Position 2");
        showPositionStatus(testPosition3, "Position 3");
        
        // Simulate market crash
        console.log("");
        console.log("3. Simulating 40% market crash...");
        oracle.simulateMarketCrash(40); // 40% crash
        
        // Show new prices
        console.log("");
        console.log("4. Prices after crash:");
        (ethPrice, btcPrice, vcopPrice,) = oracle.getCurrentMarketPrices();
        console.log("   ETH: $", ethPrice / 1e6, "(-40%)");
        console.log("   BTC: $", btcPrice / 1e6, "(-40%)");
        console.log("   VCOP: $", vcopPrice / 1e6, "(-40%)");
        
        // Show position health after crash
        console.log("");
        console.log("5. Position health after crash:");
        showPositionStatus(testPosition1, "Position 1");
        showPositionStatus(testPosition2, "Position 2");
        showPositionStatus(testPosition3, "Position 3");
        
        // Test manual liquidation
        console.log("");
        console.log("6. Testing manual liquidation capability...");
        
        // Check if any position can be liquidated
        for (uint256 i = 1; i <= 3; i++) {
            uint256 posId = i == 1 ? testPosition1 : (i == 2 ? testPosition2 : testPosition3);
            
            if (loanManager.canLiquidate(posId)) {
                console.log("   Position", i, "can be liquidated manually");
                
                // Try manual liquidation
                try loanManager.liquidatePosition(posId) {
                    console.log("    Position", i, "liquidated manually");
                } catch Error(string memory reason) {
                    console.log("    Manual liquidation failed:", reason);
                } catch {
                    console.log("    Manual liquidation failed with unknown error");
                }
            } else {
                console.log("   Position", i, "not yet liquidatable");
            }
        }
    }
    
    // ========== PHASE 5: VERIFICACIÓN DE AUTOMATIZACIÓN ==========
    
    function verifyChainlinkAutomation() internal view {
        console.log(" CHAINLINK AUTOMATION VERIFICATION");
        console.log("----------------------------------------");
        
        // 1. Generate checkData for testing
        console.log("1. Generating checkData for Chainlink...");
        bytes memory checkData = keeper.generateOptimizedCheckData(
            address(adapter), // Use adapter instead of loan manager
            0, // Start from position 1
            25 // Batch size
        );
        console.log("   CheckData generated (length):", checkData.length);
        console.log("   CheckData (hex): 0x%s", bytes2hex(checkData));
        
        // 2. Test checkUpkeep
        console.log("");
        console.log("2. Testing checkUpkeep...");
        try keeper.checkUpkeep(checkData) returns (bool upkeepNeeded, bytes memory performData) {
            console.log("   Upkeep needed:", upkeepNeeded);
            console.log("   PerformData length:", performData.length);
            
            if (upkeepNeeded) {
                console.log("    Automation should trigger liquidations!");
            } else {
                console.log("     No liquidations needed at this time");
            }
        } catch Error(string memory reason) {
            console.log("    CheckUpkeep failed:", reason);
        } catch {
            console.log("    CheckUpkeep failed with unknown error");
        }
        
        // 3. Check automation adapter
        console.log("");
        console.log("3. Automation adapter status:");
        console.log("   Address:", address(adapter));
        console.log("   Automation enabled:", adapter.isAutomationEnabled());
        console.log("   Authorized contract:", adapter.authorizedAutomationContract());
        
        try adapter.getTotalActivePositions() returns (uint256 totalPositions) {
            console.log("   Total tracked positions:", totalPositions);
        } catch {
            console.log("    Error getting total positions");
        }
        
        // 4. Verify positions at risk
        console.log("");
        console.log("4. Checking positions at risk...");
        try adapter.getPositionsAtRisk() returns (uint256[] memory riskPositions, uint256[] memory riskLevels) {
            console.log("   Positions at risk:", riskPositions.length);
            for (uint256 i = 0; i < riskPositions.length; i++) {
                console.log("   Position ID:", riskPositions[i], "Risk Level:", riskLevels[i]);
            }
        } catch {
            console.log("    Error getting positions at risk");
        }
    }
    
    // ========== PHASE 6: DASHBOARD DE MONITOREO ==========
    
    function printMonitoringDashboard() internal view {
        console.log(" MONITORING DASHBOARD");
        console.log("============================================================");
        
        console.log("");
        console.log(" CHAINLINK AUTOMATION LINKS:");
        console.log("   Dashboard: https://automation.chain.link/base-sepolia");
        console.log("   Your Upkeep: https://automation.chain.link/base-sepolia/", UPKEEP_ID);
        console.log("   LINK Faucet: https://faucets.chain.link/");
        
        console.log("");
        console.log(" CONTRACT ADDRESSES:");
        console.log("   AutomationKeeper:", address(keeper));
        console.log("   FlexibleLoanManager:", address(loanManager));
        console.log("   LoanAdapter:", address(adapter));
        console.log("   MockVCOPOracle:", address(oracle));
        
        console.log("");
        console.log(" SYSTEM STATUS:");
        console.log("   Upkeep ID:", UPKEEP_ID);
        console.log("   Network: Base Sepolia");
        console.log("   Registry: 0x91D4a4C3D448c7f3CB477332B1c7D420a5810aC3");
        
        console.log("");
        console.log(" TEST POSITIONS CREATED:");
        console.log("   Position 1 ID:", testPosition1);
        console.log("   Position 2 ID:", testPosition2);
        console.log("   Position 3 ID:", testPosition3);
        
        console.log("");
        console.log(" NEXT STEPS:");
        console.log("   1. Monitor your upkeep in Chainlink dashboard");
        console.log("   2. Check if upkeep has sufficient LINK balance");
        console.log("   3. Verify upkeep executes liquidations automatically");
        console.log("   4. Use 'make test-automation-quick' for quick checks");
        
        console.log("");
        console.log(" QUICK COMMANDS:");
        console.log("   Test automation: make test-automation-flow");
        console.log("   Check status: make check-automation-status");
        console.log("   Crash prices more: oracle.simulateMarketCrash(60)");
    }
    
    // ========== UTILIDADES ==========
    
    function bytes2hex(bytes memory data) internal pure returns (string memory) {
        bytes memory alphabet = "0123456789abcdef";
        bytes memory str = new bytes(2 + data.length * 2);
        str[0] = "0";
        str[1] = "x";
        for (uint256 i = 0; i < data.length; i++) {
            str[2 + i * 2] = alphabet[uint256(uint8(data[i] >> 4))];
            str[3 + i * 2] = alphabet[uint256(uint8(data[i] & 0x0f))];
        }
        return string(str);
    }
} 