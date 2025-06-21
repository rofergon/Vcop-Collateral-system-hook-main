// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";

interface IFlexibleLoanManager {
    struct LoanPosition {
        address borrower;
        address collateralAsset;
        address loanAsset;
        uint256 collateralAmount;
        uint256 loanAmount;
        uint256 interestRate;
        uint256 createdAt;
        uint256 lastInterestUpdate;
        bool isActive;
    }
    
    function getPosition(uint256 positionId) external view returns (LoanPosition memory);
    function getCollateralizationRatio(uint256 positionId) external view returns (uint256);
    function canLiquidate(uint256 positionId) external view returns (bool);
    function getTotalDebt(uint256 positionId) external view returns (uint256);
    function getAccruedInterest(uint256 positionId) external view returns (uint256);
    function oracle() external view returns (address);
    function priceRegistry() external view returns (address);
}

interface IMockOracle {
    function getCurrentMarketPrices() external view returns (uint256, uint256, uint256, uint256);
    function getPrice(address asset, address quote) external view returns (uint256);
}

interface IAssetHandler {
    function isAssetSupported(address asset) external view returns (bool);
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
}

interface ILoanAdapter {
    function getTotalActivePositions() external view returns (uint256);
    function isAutomationEnabled() external view returns (bool);
    function loanManager() external view returns (address);
}

contract DiagnoseSystem is Script {
    
    function run() external {
        console.log("COMPLETE SYSTEM DIAGNOSIS");
        console.log("========================");
        console.log("");
        
        // Load deployed addresses
        string memory json = vm.readFile("deployed-addresses-mock.json");
        
        address flexibleLoanManager = vm.parseJsonAddress(json, ".coreLending.flexibleLoanManager");
        address mockOracle = vm.parseJsonAddress(json, ".vcopCollateral.mockVcopOracle");
        address mockETH = vm.parseJsonAddress(json, ".tokens.mockETH");
        address mockUSDC = vm.parseJsonAddress(json, ".tokens.mockUSDC");
        address loanAdapter = vm.parseJsonAddress(json, ".automation.loanAdapter");
        address vaultHandler = vm.parseJsonAddress(json, ".coreLending.vaultBasedHandler");
        
        console.log("Contract addresses:");
        console.log("  FlexibleLoanManager:", flexibleLoanManager);
        console.log("  MockOracle:", mockOracle);
        console.log("  LoanAdapter:", loanAdapter);
        console.log("  VaultHandler:", vaultHandler);
        console.log("  MockETH:", mockETH);
        console.log("  MockUSDC:", mockUSDC);
        console.log("");
        
        // DIAGNOSIS 1: Oracle connectivity
        console.log("=== ORACLE DIAGNOSIS ===");
        _diagnoseOracle(flexibleLoanManager, mockOracle, mockETH, mockUSDC);
        console.log("");
        
        // DIAGNOSIS 2: Asset Handlers
        console.log("=== ASSET HANDLER DIAGNOSIS ===");
        _diagnoseAssetHandlers(vaultHandler, mockETH, mockUSDC);
        console.log("");
        
        // DIAGNOSIS 3: Position Management
        console.log("=== POSITION MANAGEMENT DIAGNOSIS ===");
        _diagnosePositions(flexibleLoanManager);
        console.log("");
        
        // DIAGNOSIS 4: Token Configuration
        console.log("=== TOKEN CONFIGURATION DIAGNOSIS ===");
        _diagnoseTokens(mockETH, mockUSDC);
        console.log("");
        
        // DIAGNOSIS 5: Automation System
        console.log("=== AUTOMATION SYSTEM DIAGNOSIS ===");
        _diagnoseAutomation(loanAdapter, flexibleLoanManager);
        console.log("");
        
        // DIAGNOSIS 6: Value Calculation Test
        console.log("=== VALUE CALCULATION TEST ===");
        _testValueCalculation(mockOracle, mockETH, mockUSDC);
        
        console.log("");
        console.log("DIAGNOSIS COMPLETE");
        console.log("See results above to identify issues");
    }
    
    function _diagnoseOracle(address loanManager, address oracle, address mockETH, address mockUSDC) internal {
        IFlexibleLoanManager manager = IFlexibleLoanManager(loanManager);
        
        console.log("Oracle configuration:");
        console.log("  Oracle in LoanManager:", manager.oracle());
        console.log("  Expected Oracle:", oracle);
        console.log("  Oracle matches:", manager.oracle() == oracle);
        console.log("  PriceRegistry:", manager.priceRegistry());
        console.log("");
        
        console.log("Oracle price testing:");
        try IMockOracle(oracle).getCurrentMarketPrices() returns (uint256 eth, uint256 btc, uint256 usdc, uint256 cop) {
            console.log("  ETH price:", eth);
            console.log("  BTC price:", btc);
            console.log("  USDC price:", usdc);
            console.log("  COP price:", cop);
        } catch {
            console.log("  ERROR: getCurrentMarketPrices failed");
        }
        
        try IMockOracle(oracle).getPrice(mockETH, address(0)) returns (uint256 ethPrice) {
            console.log("  ETH getPrice:", ethPrice);
        } catch {
            console.log("  ERROR: ETH getPrice failed");
        }
        
        try IMockOracle(oracle).getPrice(mockUSDC, address(0)) returns (uint256 usdcPrice) {
            console.log("  USDC getPrice:", usdcPrice);
        } catch {
            console.log("  ERROR: USDC getPrice failed");
        }
    }
    
    function _diagnoseAssetHandlers(address vaultHandler, address mockETH, address mockUSDC) internal {
        console.log("Asset handler testing:");
        
        try IAssetHandler(vaultHandler).isAssetSupported(mockETH) returns (bool supported) {
            console.log("  ETH supported in VaultHandler:", supported);
        } catch {
            console.log("  ERROR: Cannot check ETH support in VaultHandler");
        }
        
        try IAssetHandler(vaultHandler).isAssetSupported(mockUSDC) returns (bool supported) {
            console.log("  USDC supported in VaultHandler:", supported);
        } catch {
            console.log("  ERROR: Cannot check USDC support in VaultHandler");
        }
    }
    
    function _diagnosePositions(address loanManager) internal {
        IFlexibleLoanManager manager = IFlexibleLoanManager(loanManager);
        
        console.log("Position testing (IDs 1-5):");
        for (uint256 i = 1; i <= 5; i++) {
            try manager.getPosition(i) returns (IFlexibleLoanManager.LoanPosition memory position) {
                console.log("  Position", i, ":");
                console.log("    Borrower:", position.borrower);
                console.log("    Is Active:", position.isActive);
                console.log("    Collateral Amount:", position.collateralAmount);
                console.log("    Loan Amount:", position.loanAmount);
                
                if (position.isActive) {
                    try manager.getCollateralizationRatio(i) returns (uint256 ratio) {
                        if (ratio == type(uint256).max) {
                            console.log("    Ratio: MAX (no debt or error)");
                        } else {
                            console.log("    Ratio:", ratio);
                        }
                    } catch {
                        console.log("    Ratio: ERROR");
                    }
                    
                    try manager.canLiquidate(i) returns (bool canLiq) {
                        console.log("    Can Liquidate:", canLiq);
                    } catch {
                        console.log("    Can Liquidate: ERROR");
                    }
                    
                    try manager.getTotalDebt(i) returns (uint256 debt) {
                        console.log("    Total Debt:", debt);
                    } catch {
                        console.log("    Total Debt: ERROR");
                    }
                }
            } catch {
                console.log("  Position", i, ": NOT FOUND OR ERROR");
            }
        }
    }
    
    function _diagnoseTokens(address mockETH, address mockUSDC) internal {
        console.log("Token configuration:");
        
        try IERC20(mockETH).symbol() returns (string memory symbol) {
            console.log("  ETH symbol:", symbol);
        } catch {
            console.log("  ETH symbol: ERROR");
        }
        
        try IERC20(mockETH).decimals() returns (uint8 decimals) {
            console.log("  ETH decimals:", decimals);
        } catch {
            console.log("  ETH decimals: ERROR");
        }
        
        try IERC20(mockUSDC).symbol() returns (string memory symbol) {
            console.log("  USDC symbol:", symbol);
        } catch {
            console.log("  USDC symbol: ERROR");
        }
        
        try IERC20(mockUSDC).decimals() returns (uint8 decimals) {
            console.log("  USDC decimals:", decimals);
        } catch {
            console.log("  USDC decimals: ERROR");
        }
    }
    
    function _diagnoseAutomation(address adapter, address loanManager) internal {
        console.log("Automation system:");
        
        try ILoanAdapter(adapter).loanManager() returns (address configuredManager) {
            console.log("  Adapter LoanManager:", configuredManager);
            console.log("  Expected LoanManager:", loanManager);
            console.log("  Manager matches:", configuredManager == loanManager);
        } catch {
            console.log("  ERROR: Cannot get adapter's loan manager");
        }
        
        try ILoanAdapter(adapter).isAutomationEnabled() returns (bool enabled) {
            console.log("  Automation enabled:", enabled);
        } catch {
            console.log("  ERROR: Cannot check automation status");
        }
        
        try ILoanAdapter(adapter).getTotalActivePositions() returns (uint256 total) {
            console.log("  Total tracked positions:", total);
        } catch {
            console.log("  ERROR: Cannot get total positions");
        }
    }
    
    function _testValueCalculation(address oracle, address mockETH, address mockUSDC) internal {
        console.log("Manual value calculation test:");
        
        uint256 ethAmount = 1 ether; // 1 ETH
        uint256 usdcAmount = 1000 * 1e6; // 1000 USDC
        
        try IMockOracle(oracle).getPrice(mockETH, address(0)) returns (uint256 ethPrice) {
            uint256 ethValue = (ethAmount * ethPrice) / 1e18; // ETH has 18 decimals
            console.log("  1 ETH value:", ethValue);
            console.log("  ETH price used:", ethPrice);
        } catch {
            console.log("  ERROR: Cannot calculate ETH value");
        }
        
        try IMockOracle(oracle).getPrice(mockUSDC, address(0)) returns (uint256 usdcPrice) {
            uint256 usdcValue = (usdcAmount * usdcPrice) / 1e6; // USDC has 6 decimals
            console.log("  1000 USDC value:", usdcValue);
            console.log("  USDC price used:", usdcPrice);
        } catch {
            console.log("  ERROR: Cannot calculate USDC value");
        }
    }
} 