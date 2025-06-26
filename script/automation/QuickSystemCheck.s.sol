// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script, console} from "forge-std/Script.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";

/**
 * @title QuickSystemCheck
 * @notice Simple system check to verify deployment
 */
contract QuickSystemCheck is Script {
    
    function run() external {
        console.log("QUICK SYSTEM CHECK");
        console.log("==================");
        
        // Read addresses from deployed-addresses-mock.json
        string memory json = vm.readFile("deployed-addresses-mock.json");
        
        address flexibleLoanManager = vm.parseJsonAddress(json, ".coreLending.flexibleLoanManager");
        address vaultBasedHandler = vm.parseJsonAddress(json, ".coreLending.vaultBasedHandler");  
        address automationKeeper = vm.parseJsonAddress(json, ".automation.automationKeeper");
        address mockUSDC = vm.parseJsonAddress(json, ".tokens.mockUSDC");
        
        console.log("FlexibleLoanManager:", flexibleLoanManager);
        console.log("VaultBasedHandler:", vaultBasedHandler);
        console.log("AutomationKeeper:", automationKeeper);
        console.log("MockUSDC:", mockUSDC);
        
        // Basic checks
        require(flexibleLoanManager != address(0), "FlexibleLoanManager not deployed");
        require(vaultBasedHandler != address(0), "VaultBasedHandler not deployed");
        require(automationKeeper != address(0), "AutomationKeeper not deployed");
        require(mockUSDC != address(0), "MockUSDC not deployed");
        
        // Check USDC balance in vault
        IERC20 usdcToken = IERC20(mockUSDC);
        uint256 vaultBalance = usdcToken.balanceOf(vaultBasedHandler);
        console.log("Vault USDC balance:", vaultBalance / 1e6, "USDC");
        
        // Check that contracts have code
        uint256 loanManagerSize;
        uint256 vaultSize;
        uint256 keeperSize;
        
        assembly {
            loanManagerSize := extcodesize(flexibleLoanManager)
            vaultSize := extcodesize(vaultBasedHandler)
            keeperSize := extcodesize(automationKeeper)
        }
        
        console.log("Contract code sizes:");
        console.log("- LoanManager:", loanManagerSize, "bytes");
        console.log("- VaultHandler:", vaultSize, "bytes");
        console.log("- AutomationKeeper:", keeperSize, "bytes");
        
        require(loanManagerSize > 0, "LoanManager has no code");
        require(vaultSize > 0, "VaultHandler has no code");
        require(keeperSize > 0, "AutomationKeeper has no code");
        
        console.log("");
        console.log("SUCCESS: All core components deployed and verified!");
        console.log("System ready for automation testing");
        
        if (vaultBalance >= 50000 * 1e6) {
            console.log("Vault has sufficient liquidity for liquidations");
        } else {
            console.log("WARNING: Vault may need more liquidity");
        }
    }
} 