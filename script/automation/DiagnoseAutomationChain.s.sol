// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script, console} from "forge-std/Script.sol";
import {IERC20} from "v4-core/lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {VaultBasedHandler} from "../../src/core/VaultBasedHandler.sol";
import {FlexibleLoanManager} from "../../src/core/FlexibleLoanManager.sol";
import {LoanManagerAutomationAdapter} from "../../src/automation/core/LoanManagerAutomationAdapter.sol";
import {LoanAutomationKeeperOptimized} from "../../src/automation/core/LoanAutomationKeeperOptimized.sol";

/**
 * @title DiagnoseAutomationChain
 * @notice Diagnostica completamente la cadena de autorizaciones de automatización
 */
contract DiagnoseAutomationChain is Script {
    
    // Contract addresses
    address public flexibleLoanManager;
    address public vaultBasedHandler; 
    address public automationAdapter;
    address public automationKeeper;
    address public mockUSDC;
    address public mockETH;
    
    function run() external {
        console.log("=== DIAGNOSING COMPLETE AUTOMATION CHAIN ===");
        console.log("");
        
        loadAddresses();
        
        console.log("STEP 1: Contract Addresses");
        printAddresses();
        
        console.log("STEP 2: Authorization Chain Analysis");
        analyzeAuthorizationChain();
        
        console.log("STEP 3: Liquidity Status");
        analyzeLiquidityStatus();
        
        console.log("STEP 4: Final Diagnosis");
        provideFinalDiagnosis();
    }
    
    function loadAddresses() internal {
        string memory json = vm.readFile("deployed-addresses-mock.json");
        
        flexibleLoanManager = vm.parseJsonAddress(json, ".coreLending.flexibleLoanManager");
        vaultBasedHandler = vm.parseJsonAddress(json, ".coreLending.vaultBasedHandler");
        automationAdapter = vm.parseJsonAddress(json, ".automation.loanAdapter");
        automationKeeper = vm.parseJsonAddress(json, ".automation.automationKeeper");
        mockUSDC = vm.parseJsonAddress(json, ".tokens.mockUSDC");
        mockETH = vm.parseJsonAddress(json, ".tokens.mockETH");
    }
    
    function printAddresses() internal view {
        console.log("FlexibleLoanManager:", flexibleLoanManager);
        console.log("VaultBasedHandler:", vaultBasedHandler);
        console.log("AutomationAdapter:", automationAdapter);
        console.log("AutomationKeeper:", automationKeeper);
        console.log("MockUSDC:", mockUSDC);
        console.log("MockETH:", mockETH);
        console.log("");
    }
    
    function analyzeAuthorizationChain() internal view {
        console.log("=== AUTHORIZATION CHAIN ANALYSIS ===");
        console.log("");
        
        // 1. FlexibleLoanManager -> VaultBasedHandler authorization
        console.log("1. FLEXIBLELOANMANAGER -> VAULTBASEDHANDLER");
        VaultBasedHandler vault = VaultBasedHandler(vaultBasedHandler);
        bool lmAuthorizedInVault = vault.authorizedAutomationContracts(flexibleLoanManager);
        console.log("   FlexibleLoanManager authorized in VaultBasedHandler:", lmAuthorizedInVault);
        if (!lmAuthorizedInVault) {
            console.log("   [X] PROBLEM: FlexibleLoanManager NOT authorized in VaultBasedHandler");
            console.log("   [!] SOLUTION: vault.authorizeAutomationContract(flexibleLoanManager)");
        }
        console.log("");
        
        // 2. AutomationKeeper -> FlexibleLoanManager authorization
        console.log("2. AUTOMATIONKEEPER -> FLEXIBLELOANMANAGER");
        FlexibleLoanManager loanManager = FlexibleLoanManager(flexibleLoanManager);
        address authorizedInLM = loanManager.authorizedAutomationContract();
        bool keeperAuthorizedInLM = (authorizedInLM == automationKeeper);
        console.log("   Current authorized contract in LoanManager:", authorizedInLM);
        console.log("   AutomationKeeper is authorized:", keeperAuthorizedInLM);
        if (!keeperAuthorizedInLM) {
            console.log("   [X] PROBLEM: AutomationKeeper NOT authorized in FlexibleLoanManager");
            console.log("   [!] SOLUTION: loanManager.setAutomationContract(automationKeeper)");
        }
        console.log("");
        
        // 3. AutomationKeeper -> AutomationAdapter authorization
        console.log("3. AUTOMATIONKEEPER -> AUTOMATIONADAPTER");
        LoanManagerAutomationAdapter adapter = LoanManagerAutomationAdapter(automationAdapter);
        address authorizedInAdapter = adapter.authorizedAutomationContract();
        bool keeperAuthorizedInAdapter = (authorizedInAdapter == automationKeeper);
        console.log("   Current authorized contract in Adapter:", authorizedInAdapter);
        console.log("   AutomationKeeper is authorized:", keeperAuthorizedInAdapter);
        if (!keeperAuthorizedInAdapter) {
            console.log("   [X] PROBLEM: AutomationKeeper NOT authorized in AutomationAdapter");
            console.log("   [!] SOLUTION: adapter.setAutomationContract(automationKeeper)");
        }
        console.log("");
        
        // 4. Check if AutomationKeeper is registered in itself
        console.log("4. AUTOMATIONKEEPER REGISTRATION");
        LoanAutomationKeeperOptimized keeper = LoanAutomationKeeperOptimized(automationKeeper);
        bool adapterRegistered = keeper.registeredManagers(automationAdapter);
        console.log("   AutomationAdapter registered in Keeper:", adapterRegistered);
        if (!adapterRegistered) {
            console.log("   [X] PROBLEM: AutomationAdapter NOT registered in AutomationKeeper");
            console.log("   [!] SOLUTION: keeper.registerLoanManager(automationAdapter, priority)");
        }
        console.log("");
        
        // 5. Automation enabled flags
        console.log("5. AUTOMATION FLAGS");
        bool lmAutomationEnabled = loanManager.isAutomationEnabled();
        bool adapterAutomationEnabled = adapter.isAutomationEnabled();
        bool keeperEmergencyPause = keeper.emergencyPause();
        
        console.log("   LoanManager automation enabled:", lmAutomationEnabled);
        console.log("   Adapter automation enabled:", adapterAutomationEnabled);
        console.log("   Keeper emergency pause:", keeperEmergencyPause);
        
        if (!lmAutomationEnabled) {
            console.log("   [X] PROBLEM: LoanManager automation disabled");
            console.log("   [!] SOLUTION: loanManager.setAutomationEnabled(true)");
        }
        if (!adapterAutomationEnabled) {
            console.log("   [X] PROBLEM: Adapter automation disabled");
            console.log("   [!] SOLUTION: adapter.setAutomationEnabled(true)");
        }
        if (keeperEmergencyPause) {
            console.log("   [X] PROBLEM: Keeper is in emergency pause");
            console.log("   [!] SOLUTION: keeper.setEmergencyPause(false)");
        }
    }
    
    function analyzeLiquidityStatus() internal view {
        console.log("=== LIQUIDITY STATUS ANALYSIS ===");
        console.log("");
        
        VaultBasedHandler vault = VaultBasedHandler(vaultBasedHandler);
        
        // Check USDC liquidity
        uint256 vaultUSDCBalance = IERC20(mockUSDC).balanceOf(vaultBasedHandler);
        console.log("Vault USDC balance:", vaultUSDCBalance / 1e6, "USDC");
        
        try vault.getAutomationLiquidityStatus(mockUSDC) returns (
            uint256 available,
            uint256 totalLiquidations,
            uint256 totalRecovered,
            bool canLiquidate
        ) {
            console.log("Available for automation:", available / 1e6, "USDC");
            console.log("Total liquidations executed:", totalLiquidations);
            console.log("Total recovered:", totalRecovered / 1e6, "USDC");
            console.log("Can liquidate:", canLiquidate);
            
            if (!canLiquidate) {
                console.log("[X] PROBLEM: Vault cannot liquidate (insufficient funds)");
                console.log("[!] SOLUTION: Add USDC liquidity to vault");
            }
        } catch {
            console.log("[X] Error getting automation liquidity status");
        }
        
        console.log("");
    }
    
    function provideFinalDiagnosis() internal view {
        console.log("=== FINAL DIAGNOSIS ===");
        console.log("");
        
        // Count problems
        uint256 problems = 0;
        
        // Check critical authorizations
        VaultBasedHandler vault = VaultBasedHandler(vaultBasedHandler);
        FlexibleLoanManager loanManager = FlexibleLoanManager(flexibleLoanManager);
        LoanManagerAutomationAdapter adapter = LoanManagerAutomationAdapter(automationAdapter);
        LoanAutomationKeeperOptimized keeper = LoanAutomationKeeperOptimized(automationKeeper);
        
        bool lmAuthorizedInVault = vault.authorizedAutomationContracts(flexibleLoanManager);
        bool keeperAuthorizedInLM = (loanManager.authorizedAutomationContract() == automationKeeper);
        bool keeperAuthorizedInAdapter = (adapter.authorizedAutomationContract() == automationKeeper);
        bool adapterRegistered = keeper.registeredManagers(automationAdapter);
        
        // Check vault liquidity
        uint256 vaultBalance = IERC20(mockUSDC).balanceOf(vaultBasedHandler);
        bool hasLiquidity = vaultBalance > 1000 * 1e6; // At least 1000 USDC
        
        console.log("CRITICAL ISSUES:");
        console.log("================");
        
        if (!lmAuthorizedInVault) {
            problems++;
            console.log(problems, ". FlexibleLoanManager NOT authorized in VaultBasedHandler");
            console.log("    Command: vault.authorizeAutomationContract(", flexibleLoanManager, ")");
        }
        
        if (!keeperAuthorizedInLM) {
            problems++;
            console.log(problems, ". AutomationKeeper NOT authorized in FlexibleLoanManager");
            console.log("    Command: loanManager.setAutomationContract(", automationKeeper, ")");
        }
        
        if (!keeperAuthorizedInAdapter) {
            problems++;
            console.log(problems, ". AutomationKeeper NOT authorized in AutomationAdapter");
            console.log("    Command: adapter.setAutomationContract(", automationKeeper, ")");
        }
        
        if (!adapterRegistered) {
            problems++;
            console.log(problems, ". AutomationAdapter NOT registered in AutomationKeeper");
            console.log("    Command: keeper.registerLoanManager(", automationAdapter, ", 50)");
        }
        
        if (!hasLiquidity) {
            problems++;
            console.log(problems, ". Insufficient USDC liquidity in vault");
            console.log("    Command: vault.provideLiquidity(USDC, amount, provider)");
        }
        
        console.log("");
        
        if (problems == 0) {
            console.log("[OK] NO CRITICAL ISSUES FOUND");
            console.log("   The automation chain should be working properly");
            console.log("   Check gas limits, cooldowns, or position tracking issues");
        } else {
            console.log("[ERROR] FOUND", problems, "CRITICAL ISSUES");
            console.log("   Fix these issues and liquidations should start working");
        }
        
        console.log("");
        console.log("=== RECOMMENDED ACTIONS ===");
        console.log("1. Run the authorization fix scripts");
        console.log("2. Add sufficient USDC liquidity to vault");
        console.log("3. Test with a single position liquidation");
        console.log("4. Monitor automation execution");
    }
} 