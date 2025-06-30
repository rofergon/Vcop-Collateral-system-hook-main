// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {FlexibleLoanManager} from "../../src/core/FlexibleLoanManager.sol";
import {ILoanManager} from "../../src/interfaces/ILoanManager.sol";
import {VaultBasedHandler} from "../../src/core/VaultBasedHandler.sol";
import {MockVCOPOracle} from "../../src/VcopCollateral/MockVCOPOracle.sol";
import {LoanAutomationKeeperOptimized} from "../../src/automation/core/LoanAutomationKeeperOptimized.sol";
import {LoanManagerAutomationAdapter} from "../../src/automation/core/LoanManagerAutomationAdapter.sol";
import {IERC20} from "v4-core/lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

/**
 * @title CreatePositionCrashAndDiagnose
 * @notice Script completo para crear posición, crashear precio y diagnosticar liquidación automática
 */
contract CreatePositionCrashAndDiagnose is Script {
    
    // Contracts
    FlexibleLoanManager public loanManager;
    VaultBasedHandler public vaultHandler;
    MockVCOPOracle public oracle;
    LoanAutomationKeeperOptimized public keeper;
    LoanManagerAutomationAdapter public adapter;
    
    // Tokens (from deployment)
    address public mockETH;
    address public mockUSDC;
    address public mockWBTC;
    
    // Test amounts
    uint256 constant COLLATERAL_AMOUNT = 1 ether; // 1 ETH
    uint256 constant LOAN_AMOUNT = 2000 * 1e6; // 2000 USDC
    uint256 constant CRASH_PERCENTAGE = 70; // 70% price crash
    
    function run() external {
        console.log("==================================================");
        console.log("CREATE POSITION, CRASH PRICE & DIAGNOSE LIQUIDATION");
        console.log("==================================================");
        
        // Load contracts
        _loadContracts();
        
        // Step 1: Pre-crash analysis
        console.log("");
        console.log("=== STEP 1: PRE-CRASH ANALYSIS ===");
        _preAnalysis();
        
        // Step 2: Create position
        console.log("");
        console.log("=== STEP 2: CREATE POSITION ===");
        uint256 positionId = _createPosition();
        
        // Step 3: Verify position health before crash
        console.log("");
        console.log("=== STEP 3: POSITION HEALTH BEFORE CRASH ===");
        _analyzePositionHealth(positionId, "BEFORE CRASH");
        
        // Step 4: Crash the price
        console.log("");
        console.log("=== STEP 4: CRASH ETH PRICE ===");
        _crashPrice();
        
        // Step 5: Verify position health after crash
        console.log("");
        console.log("=== STEP 5: POSITION HEALTH AFTER CRASH ===");
        _analyzePositionHealth(positionId, "AFTER CRASH");
        
        // Step 6: Diagnose automation system
        console.log("");
        console.log("=== STEP 6: DIAGNOSE AUTOMATION SYSTEM ===");
        _diagnoseAutomationSystem(positionId);
        
        // Step 7: Test checkUpkeep manually
        console.log("");
        console.log("=== STEP 7: TEST CHECKUPKEEP MANUALLY ===");
        _testCheckUpkeepManually(positionId);
        
        // Step 8: Fix configuration and test again
        console.log("");
        console.log("=== STEP 8: FIX CONFIGURATION & TEST ===");
        _fixConfigurationAndTest(positionId);
        
        console.log("");
        console.log("=== DIAGNOSTIC COMPLETE ===");
    }
    
    function _loadContracts() internal {
        // Read addresses from deployment file
        string memory json = vm.readFile("deployed-addresses-mock.json");
        
        loanManager = FlexibleLoanManager(vm.parseJsonAddress(json, ".coreLending.flexibleLoanManager"));
        vaultHandler = VaultBasedHandler(vm.parseJsonAddress(json, ".coreLending.vaultBasedHandler"));
        oracle = MockVCOPOracle(vm.parseJsonAddress(json, ".vcopCollateral.mockVcopOracle"));
        keeper = LoanAutomationKeeperOptimized(vm.parseJsonAddress(json, ".automation.automationKeeper"));
        adapter = LoanManagerAutomationAdapter(vm.parseJsonAddress(json, ".automation.loanAdapter"));
        
        mockETH = vm.parseJsonAddress(json, ".tokens.mockETH");
        mockUSDC = vm.parseJsonAddress(json, ".tokens.mockUSDC");
        mockWBTC = vm.parseJsonAddress(json, ".tokens.mockWBTC");
        
        console.log("Contracts loaded:");
        console.log("  LoanManager:", address(loanManager));
        console.log("  VaultHandler:", address(vaultHandler));
        console.log("  Oracle:", address(oracle));
        console.log("  Keeper:", address(keeper));
        console.log("  Adapter:", address(adapter));
    }
    
    function _preAnalysis() internal {
        console.log("TOKEN PRICES:");
        try oracle.getCurrentMarketPrices() returns (
            uint256 ethPrice,
            uint256 btcPrice,
            uint256 vcopPrice,
            uint256 usdCopRate
        ) {
            console.log("  ETH Price: $", ethPrice / 1e6);
            console.log("  BTC Price: $", btcPrice / 1e6);
            console.log("  VCOP Price: $", vcopPrice / 1e6);
            console.log("  USD/COP Rate:", usdCopRate / 1e6);
        } catch {
            console.log("  Could not get prices from oracle");
        }
        
        console.log("");
        console.log("AUTOMATION CONFIGURATION:");
        try keeper.minRiskThreshold() returns (uint256 threshold) {
            console.log("  Keeper Min Risk Threshold:", threshold);
        } catch {
            console.log("  Could not get keeper threshold");
        }
        
        try adapter.criticalRiskThreshold() returns (uint256 critical) {
            console.log("  Adapter Critical Threshold:", critical);
        } catch {
            console.log("  Could not get adapter thresholds");
        }
        
        try keeper.registeredManagers(address(adapter)) returns (bool registered) {
            console.log("  Adapter Registered in Keeper:", registered);
        } catch {
            console.log("  Could not check adapter registration");
        }
    }
    
    function _createPosition() internal returns (uint256 positionId) {
        vm.startBroadcast();
        
        console.log("Creating loan position...");
        console.log("  Collateral: 1 ETH");
        console.log("  Loan: 2000 USDC");
        
        // Approve collateral
        IERC20(mockETH).approve(address(loanManager), COLLATERAL_AMOUNT);
        
        // Create loan terms
        ILoanManager.LoanTerms memory terms = ILoanManager.LoanTerms({
            collateralAsset: mockETH,
            loanAsset: mockUSDC,
            collateralAmount: COLLATERAL_AMOUNT,
            loanAmount: LOAN_AMOUNT,
            maxLoanToValue: 8000000, // 80% max LTV (6 decimals: 80% = 800000)
            interestRate: 50000, // 5% annual rate
            duration: 0 // Perpetual loan
        });
        
        // Create position
        positionId = loanManager.createLoan(terms);
        
        vm.stopBroadcast();
        
        console.log("Position created with ID:", positionId);
        return positionId;
    }
    
    function _analyzePositionHealth(uint256 positionId, string memory label) internal {
        console.log("POSITION HEALTH", label, ":");
        
        try loanManager.getPosition(positionId) returns (ILoanManager.LoanPosition memory position) {
            console.log("  Position ID:", positionId);
            console.log("  Borrower:", position.borrower);
            console.log("  Collateral Amount:", position.collateralAmount / 1e18, "ETH");
            console.log("  Loan Amount:", position.loanAmount / 1e6, "USDC");
            console.log("  Is Active:", position.isActive ? "YES" : "NO");
        } catch {
            console.log("  Could not get position details");
        }
        
        try loanManager.getCollateralizationRatio(positionId) returns (uint256 ratio) {
            console.log("  Collateralization Ratio:", ratio / 10000, "%");
            
            if (ratio < 1200000) { // Below 120%
                console.log("  >>> POSITION IS AT HIGH RISK <<<");
            } else if (ratio < 1500000) { // Below 150%
                console.log("  >>> POSITION IS AT MODERATE RISK <<<");
            } else {
                console.log("  Position is healthy");
            }
        } catch {
            console.log("  Could not calculate collateralization ratio");
        }
        
        try loanManager.canLiquidate(positionId) returns (bool canLiq) {
            console.log("  Can Liquidate:", canLiq ? "YES" : "NO");
        } catch {
            console.log("  Could not check liquidation status");
        }
        
        try loanManager.getTotalDebt(positionId) returns (uint256 debt) {
            console.log("  Total Debt:", debt / 1e6, "USDC");
        } catch {
            console.log("  Could not get total debt");
        }
    }
    
    function _crashPrice() internal {
        vm.startBroadcast();
        
        console.log("Crashing ETH price by", CRASH_PERCENTAGE, "%...");
        
        try oracle.simulateMarketCrash(CRASH_PERCENTAGE) {
            console.log("Price crash executed successfully");
            
            try oracle.getCurrentMarketPrices() returns (
                uint256 ethPrice,
                uint256 btcPrice,
                uint256 vcopPrice,
                uint256 usdCopRate
            ) {
                console.log("NEW PRICES:");
                console.log("  ETH Price: $", ethPrice / 1e6);
                console.log("  BTC Price: $", btcPrice / 1e6);
            } catch {
                console.log("Could not get new prices");
            }
        } catch {
            console.log("Failed to crash prices");
        }
        
        vm.stopBroadcast();
    }
    
    function _diagnoseAutomationSystem(uint256 positionId) internal {
        console.log("AUTOMATION SYSTEM DIAGNOSIS:");
        
        // 1. Check if automation is enabled
        try loanManager.isAutomationEnabled() returns (bool enabled) {
            console.log("  1. LoanManager Automation Enabled:", enabled ? "YES" : "NO");
            if (!enabled) {
                console.log("     >>> PROBLEM: Automation is disabled <<<");
            }
        } catch {
            console.log("  1. Could not check automation status");
        }
        
        // 2. Check authorized automation contract
        try loanManager.authorizedAutomationContract() returns (address authorized) {
            console.log("  2. Authorized Automation Contract:", authorized);
            if (authorized != address(adapter)) {
                console.log("     >>> PROBLEM: Wrong automation contract authorized <<<");
                console.log("     Expected:", address(adapter));
                console.log("     Current:", authorized);
            }
        } catch {
            console.log("  2. Could not get authorized contract");
        }
        
        // 3. Check adapter automation enabled
        try adapter.isAutomationEnabled() returns (bool adapterEnabled) {
            console.log("  3. Adapter Automation Enabled:", adapterEnabled ? "YES" : "NO");
            if (!adapterEnabled) {
                console.log("     >>> PROBLEM: Adapter automation is disabled <<<");
            }
        } catch {
            console.log("  3. Could not check adapter automation");
        }
        
        // 4. Check position tracking
        try adapter.isPositionTracked(positionId) returns (bool tracked) {
            console.log("  4. Position Tracked in Adapter:", tracked ? "YES" : "NO");
            if (!tracked) {
                console.log("     >>> PROBLEM: Position not tracked for automation <<<");
            }
        } catch {
            console.log("  4. Could not check position tracking");
        }
        
        // 5. Check position risk status
        try adapter.isPositionAtRisk(positionId) returns (bool isAtRisk, uint256 riskLevel) {
            console.log("  5. Position At Risk:", isAtRisk ? "YES" : "NO");
            console.log("     Risk Level:", riskLevel);
            
            try keeper.minRiskThreshold() returns (uint256 minThreshold) {
                console.log("     Min Risk Threshold:", minThreshold);
                if (isAtRisk && riskLevel >= minThreshold) {
                    console.log("     >>> POSITION SHOULD BE LIQUIDATABLE <<<");
                } else if (isAtRisk && riskLevel < minThreshold) {
                    console.log("     >>> PROBLEM: Risk level below threshold <<<");
                } else {
                    console.log("     Position not at risk according to adapter");
                }
            } catch {
                console.log("     Could not get min threshold");
            }
        } catch {
            console.log("  5. Could not check position risk");
        }
        
        // 6. Check keeper registration
        try keeper.registeredManagers(address(adapter)) returns (bool registered) {
            console.log("  6. Adapter Registered in Keeper:", registered ? "YES" : "NO");
            if (!registered) {
                console.log("     >>> PROBLEM: Adapter not registered in keeper <<<");
            }
        } catch {
            console.log("  6. Could not check keeper registration");
        }
        
        // 7. Check emergency pause
        try keeper.emergencyPause() returns (bool paused) {
            console.log("  7. Keeper Emergency Pause:", paused ? "YES" : "NO");
            if (paused) {
                console.log("     >>> PROBLEM: Keeper is paused <<<");
            }
        } catch {
            console.log("  7. Could not check emergency pause");
        }
    }
    
    function _testCheckUpkeepManually(uint256 positionId) internal {
        console.log("MANUAL CHECKUPKEEP TEST:");
        
        // Generate check data
        bytes memory checkData = keeper.generateOptimizedCheckData(
            address(adapter), // loanManager (adapter acts as loan manager interface)
            positionId,       // start from our position
            10               // small batch size
        );
        
        console.log("  Generated CheckData length:", checkData.length);
        
        try keeper.checkUpkeep(checkData) returns (bool upkeepNeeded, bytes memory performData) {
            console.log("  CheckUpkeep Result:");
            console.log("    Upkeep Needed:", upkeepNeeded ? "YES" : "NO");
            console.log("    PerformData Length:", performData.length);
            
            if (upkeepNeeded) {
                console.log("  >>> SUCCESS: Automation should work! <<<");
                
                // Decode perform data to see what positions would be liquidated
                _decodePerformData(performData);
            } else {
                console.log("  >>> PROBLEM: CheckUpkeep returns false <<<");
            }
        } catch Error(string memory reason) {
            console.log("  CheckUpkeep FAILED:", reason);
        } catch {
            console.log("  CheckUpkeep FAILED with unknown error");
        }
    }
    
    function _decodePerformData(bytes memory performData) internal pure {
        if (performData.length > 0) {
            (
                address loanManager,
                uint256[] memory positions,
                uint256[] memory riskLevels,
                uint256 timestamp
            ) = abi.decode(performData, (address, uint256[], uint256[], uint256));
            
            console.log("    Decoded PerformData:");
            console.log("      LoanManager:", loanManager);
            console.log("      Positions Count:", positions.length);
            if (positions.length > 0) {
                console.log("      First Position ID:", positions[0]);
                console.log("      First Risk Level:", riskLevels[0]);
            }
            console.log("      Timestamp:", timestamp);
        } else {
            console.log("    PerformData is empty");
        }
    }
    
    function _fixConfigurationAndTest(uint256 positionId) internal {
        vm.startBroadcast();
        
        console.log("FIXING CONFIGURATION ISSUES:");
        
        // 1. Ensure automation is enabled
        try loanManager.setAutomationEnabled(true) {
            console.log("  1. Enabled LoanManager automation");
        } catch {
            console.log("  1. Could not enable LoanManager automation");
        }
        
        // 2. Set correct automation contract
        try loanManager.setAutomationContract(address(adapter)) {
            console.log("  2. Set correct automation contract");
        } catch {
            console.log("  2. Could not set automation contract");
        }
        
        // 3. Enable adapter automation
        try adapter.setAutomationEnabled(true) {
            console.log("  3. Enabled adapter automation");
        } catch {
            console.log("  3. Could not enable adapter automation");
        }
        
        // 4. Add position to tracking
        try adapter.addPositionToTracking(positionId) {
            console.log("  4. Added position to tracking");
        } catch {
            console.log("  4. Could not add position to tracking (maybe already tracked)");
        }
        
        // 5. Register adapter in keeper
        try keeper.registerLoanManager(address(adapter), 100) {
            console.log("  5. Registered adapter in keeper");
        } catch {
            console.log("  5. Could not register adapter (maybe already registered)");
        }
        
        // 6. Set sensitive risk threshold
        try keeper.setMinRiskThreshold(85) {
            console.log("  6. Set keeper min risk threshold to 85");
        } catch {
            console.log("  6. Could not set keeper threshold");
        }
        
        // 7. Set adapter thresholds
        try adapter.setRiskThresholds(100, 95, 90) {
            console.log("  7. Set adapter risk thresholds (100/95/90)");
        } catch {
            console.log("  7. Could not set adapter thresholds");
        }
        
        vm.stopBroadcast();
        
        console.log("");
        console.log("TESTING AFTER FIXES:");
        
        // Test position risk again
        try adapter.isPositionAtRisk(positionId) returns (bool isAtRisk, uint256 riskLevel) {
            console.log("  Position At Risk:", isAtRisk ? "YES" : "NO");
            console.log("  Risk Level:", riskLevel);
        } catch {
            console.log("  Could not check position risk after fixes");
        }
        
        // Test checkUpkeep again
        bytes memory checkData = keeper.generateOptimizedCheckData(
            address(adapter),
            positionId,
            10
        );
        
        try keeper.checkUpkeep(checkData) returns (bool upkeepNeeded, bytes memory performData) {
            console.log("  CheckUpkeep After Fixes:");
            console.log("    Upkeep Needed:", upkeepNeeded ? "YES" : "NO");
            console.log("    PerformData Length:", performData.length);
            
            if (upkeepNeeded) {
                console.log("  >>> FIXED: Automation should work now! <<<");
            } else {
                console.log("  >>> STILL BROKEN: More investigation needed <<<");
            }
        } catch Error(string memory reason) {
            console.log("  CheckUpkeep still failed:", reason);
        }
    }
} 