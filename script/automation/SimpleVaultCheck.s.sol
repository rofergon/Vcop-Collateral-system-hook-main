// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script, console} from "forge-std/Script.sol";
import {VaultBasedHandler} from "../../src/core/VaultBasedHandler.sol";
import {FlexibleLoanManager} from "../../src/core/FlexibleLoanManager.sol";
import {IAssetHandler} from "../../src/interfaces/IAssetHandler.sol";
import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

/**
 * @title SimpleVaultCheck
 * @notice Script simple para revisar fondos del VaultBasedHandler
 */
contract SimpleVaultCheck is Script {
    
    function run() external view {
        console.log("=== SIMPLE VAULT FUNDS CHECK ===");
        console.log("");
        
        // Cargar direcciones desde el archivo JSON
        (
            address flexibleLoanManager,
            address vaultHandler,
            address automationKeeper,
            address mockETH,
            address mockUSDC
        ) = loadAddresses();
        
        FlexibleLoanManager loanManager = FlexibleLoanManager(flexibleLoanManager);
        
        console.log("VaultBasedHandler address:", vaultHandler);
        console.log("FlexibleLoanManager address:", flexibleLoanManager);
        
        console.log("");
        console.log("STEP 1: TOKEN BALANCES IN VAULT");
        console.log("==============================");
        _checkTokenBalances(vaultHandler, mockETH, mockUSDC);
        
        console.log("");
        console.log("STEP 2: VAULT LIQUIDITY STATUS");
        console.log("==============================");
        _checkVaultLiquidity(vaultHandler, mockUSDC);
        
        console.log("");
        console.log("STEP 3: AUTOMATION AUTHORIZATION");
        console.log("================================");
        _checkAutomationAuth(vaultHandler, automationKeeper);
        
        console.log("");
        console.log("STEP 4: LIQUIDATION REQUIREMENTS");
        console.log("================================");
        _checkLiquidationNeeds(loanManager, vaultHandler, mockUSDC);
        
        console.log("");
        console.log("STEP 5: FINAL VERDICT");
        console.log("=====================");
        _provideFinalVerdict(vaultHandler, automationKeeper, mockUSDC);
    }
    
    /**
     * @notice Carga las direcciones dinámicamente desde el archivo JSON
     */
    function loadAddresses() internal view returns (
        address flexibleLoanManager,
        address vaultHandler,
        address automationKeeper,
        address mockETH,
        address mockUSDC
    ) {
        console.log("Loading addresses from deployed-addresses-mock.json...");
        
        string memory json = vm.readFile("deployed-addresses-mock.json");
        
        // Cargar direcciones principales
        flexibleLoanManager = vm.parseJsonAddress(json, ".coreLending.flexibleLoanManager");
        vaultHandler = vm.parseJsonAddress(json, ".coreLending.vaultBasedHandler");
        mockETH = vm.parseJsonAddress(json, ".tokens.mockETH");
        mockUSDC = vm.parseJsonAddress(json, ".tokens.mockUSDC");
        
        // Para AutomationKeeper, intentamos desde el archivo JSON, si no existe usamos la dirección por defecto
        try vm.parseJsonAddress(json, ".automation.automationKeeper") returns (address keeper) {
            automationKeeper = keeper;
        } catch {
            // Si no está en el JSON, usar la dirección conocida (temporal)
            automationKeeper = 0x15C7298Dd649DcDc17D281cB0dAE84E945573c93;
        }
        
        // Validar que las direcciones no sean cero
        require(flexibleLoanManager != address(0), "FlexibleLoanManager address is zero");
        require(vaultHandler != address(0), "VaultBasedHandler address is zero");
        require(automationKeeper != address(0), "AutomationKeeper address is zero");
        require(mockETH != address(0), "MockETH address is zero");
        require(mockUSDC != address(0), "MockUSDC address is zero");
        
        console.log("Address loading completed successfully!");
        console.log("");
    }
    
    function _checkTokenBalances(address vaultHandler, address mockETH, address mockUSDC) internal view {
        uint256 ethBalance = IERC20(mockETH).balanceOf(vaultHandler);
        uint256 usdcBalance = IERC20(mockUSDC).balanceOf(vaultHandler);
        
        console.log("Token balances in VaultBasedHandler:");
        console.log("- ETH:", ethBalance / 1e18);
        console.log("- USDC:", usdcBalance / 1e6);
        
        if (ethBalance == 0 && usdcBalance == 0) {
            console.log("CRITICAL: Vault is completely empty!");
        } else if (usdcBalance == 0) {
            console.log("PROBLEM: No USDC for liquidations!");
        } else if (usdcBalance < 1000 * 1e6) {
            console.log("WARNING: Low USDC balance (<1000)");
        } else {
            console.log("OK: USDC available for liquidations");
        }
    }
    
    function _checkVaultLiquidity(address vaultHandler, address mockUSDC) internal view {
        // Check USDC liquidity
        (bool success1, bytes memory data1) = vaultHandler.staticcall(
            abi.encodeWithSignature("getAvailableLiquidity(address)", mockUSDC)
        );
        
        if (success1 && data1.length >= 32) {
            uint256 availableUsdc = abi.decode(data1, (uint256));
            console.log("Available USDC liquidity:", availableUsdc / 1e6);
            
            if (availableUsdc == 0) {
                console.log("CRITICAL: No available USDC liquidity!");
            }
        } else {
            console.log("Could not check USDC liquidity");
        }
        
        // Check vault stats for USDC
        (bool success2, bytes memory data2) = vaultHandler.staticcall(
            abi.encodeWithSignature("getVaultStats(address)", mockUSDC)
        );
        
        if (success2 && data2.length >= 160) {
            (uint256 totalLiquidity, uint256 totalBorrowed, , uint256 utilization, ) = 
                abi.decode(data2, (uint256, uint256, uint256, uint256, uint256));
                
            console.log("USDC Vault Stats:");
            console.log("- Total liquidity:", totalLiquidity / 1e6);
            console.log("- Total borrowed:", totalBorrowed / 1e6);
            console.log("- Utilization:", utilization / 10000, "%");
            
            if (utilization > 900000) { // >90%
                console.log("WARNING: High utilization (>90%)");
            }
        }
        
        // Check automation liquidity
        (bool success3, bytes memory data3) = vaultHandler.staticcall(
            abi.encodeWithSignature("getAutomationLiquidityStatus(address)", mockUSDC)
        );
        
        if (success3 && data3.length >= 128) {
            (uint256 availableForAutomation, uint256 totalLiquidations, , bool canLiquidate) = 
                abi.decode(data3, (uint256, uint256, uint256, bool));
                
            console.log("Automation Status:");
            console.log("- Available for automation:", availableForAutomation / 1e6, "USDC");
            console.log("- Total liquidations done:", totalLiquidations);
            console.log("- Can liquidate:", canLiquidate);
            
            if (!canLiquidate) {
                console.log("PROBLEM: Automation cannot liquidate!");
            }
        }
    }
    
    function _checkAutomationAuth(address vaultHandler, address automationKeeper) internal view {
        (bool success, bytes memory data) = vaultHandler.staticcall(
            abi.encodeWithSignature("authorizedAutomationContracts(address)", automationKeeper)
        );
        
        if (success && data.length >= 32) {
            bool isAuthorized = abi.decode(data, (bool));
            console.log("Automation keeper authorized in vault:", isAuthorized);
            
            if (!isAuthorized) {
                console.log("CRITICAL: Automation keeper NOT authorized!");
                console.log("SOLUTION: Run vault.authorizeAutomationContract(", automationKeeper, ")");
            }
        } else {
            console.log("Could not check automation authorization");
        }
    }
    
    function _checkLiquidationNeeds(FlexibleLoanManager loanManager, address vaultHandler, address mockUSDC) internal view {
        console.log("Checking liquidation requirements...");
        
        // Check position 1 debt
        try loanManager.getTotalDebt(1) returns (uint256 totalDebt) {
            console.log("Position 1 debt:", totalDebt / 1e6, "USDC");
            
            uint256 vaultUsdc = IERC20(mockUSDC).balanceOf(vaultHandler);
            console.log("Vault USDC balance:", vaultUsdc / 1e6);
            
            if (vaultUsdc >= totalDebt) {
                console.log("SUCCESS: Sufficient USDC for liquidation");
            } else {
                console.log("CRITICAL: Insufficient USDC!");
                console.log("- Need:", totalDebt / 1e6, "USDC");
                console.log("- Have:", vaultUsdc / 1e6, "USDC");
                console.log("- Missing:", (totalDebt - vaultUsdc) / 1e6, "USDC");
            }
        } catch {
            console.log("Could not get position 1 debt");
        }
        
        // Check if position can be liquidated
        try loanManager.canLiquidate(1) returns (bool canLiquidate) {
            console.log("Position 1 can be liquidated:", canLiquidate);
            
            if (!canLiquidate) {
                console.log("ISSUE: Position cannot be liquidated by LoanManager");
            }
        } catch {
            console.log("Could not check if position 1 can be liquidated");
        }
    }
    
    function _provideFinalVerdict(address vaultHandler, address automationKeeper, address mockUSDC) internal view {
        console.log("FINAL DIAGNOSIS:");
        console.log("");
        
        uint256 vaultUsdc = IERC20(mockUSDC).balanceOf(vaultHandler);
        
        // Check authorization
        (bool authSuccess, bytes memory authData) = vaultHandler.staticcall(
            abi.encodeWithSignature("authorizedAutomationContracts(address)", automationKeeper)
        );
        bool isAuthorized = false;
        if (authSuccess && authData.length >= 32) {
            isAuthorized = abi.decode(authData, (bool));
        }
        
        console.log("VERDICT:");
        if (vaultUsdc == 0) {
            console.log("CRITICAL: NO USDC IN VAULT!");
            console.log("   Solution: Add USDC liquidity to vault");
            console.log("   Command: vault.provideLiquidity(USDC, amount, provider)");
        } else if (!isAuthorized) {
            console.log("CRITICAL: AUTOMATION NOT AUTHORIZED!");
            console.log("   Solution: Authorize automation keeper");
            console.log("   Command: vault.authorizeAutomationContract(keeper)");
        } else {
            console.log("PARTIAL: Vault has funds and authorization");
            console.log("   Check: Gas limits, cooldowns, or other issues");
        }
        
        console.log("");
        console.log("NEXT STEPS:");
        console.log("1. If no USDC: Add liquidity to vault");
        console.log("2. If not authorized: Authorize automation keeper");
        console.log("3. If both OK: Check gas limits and cooldowns");
        console.log("4. Test manual liquidation");
    }
} 