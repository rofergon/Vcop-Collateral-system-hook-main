// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";

interface IMockOracle {
    function setEthPrice(uint256 price) external;
    function getCurrentMarketPrices() external view returns (uint256, uint256, uint256, uint256);
}

interface ILoanManager {
    function getCollateralizationRatio(uint256 positionId) external view returns (uint256);
    function canLiquidate(uint256 positionId) external view returns (bool);
}

interface ILoanAdapter {
    function addPositionToTracking(uint256 positionId) external;
    function getTotalActivePositions() external view returns (uint256);
}

contract CrashPrice is Script {
    
    function run() external {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(privateKey);
        
        // Load deployed addresses
        string memory json = vm.readFile("deployed-addresses-mock.json");
        address oracle = vm.parseJsonAddress(json, ".vcopCollateral.mockVcopOracle");
        address loanManager = vm.parseJsonAddress(json, ".coreLending.flexibleLoanManager");
        address loanAdapter = vm.parseJsonAddress(json, ".automation.loanAdapter");
        
        console.log("CRASHING ETH PRICE FOR LIQUIDATION TEST");
        console.log("Oracle:", oracle);
        console.log("LoanManager:", loanManager);
        console.log("LoanAdapter:", loanAdapter);
        console.log("");
        
        // Step 1: Register position 1 in adapter
        console.log("Step 1: Registering position 1 in LoanAdapter...");
        try ILoanAdapter(loanAdapter).addPositionToTracking(1) {
            console.log("Position registered");
        } catch {
            console.log("Position already registered or error");
        }
        
        // Step 2: Check current state
        console.log("");
        console.log("Step 2: Current state...");
        uint256 totalPositions = ILoanAdapter(loanAdapter).getTotalActivePositions();
        console.log("Total tracked positions:", totalPositions);
        
        // Step 3: Crash ETH price
        console.log("");
        console.log("Step 3: Crashing ETH price...");
        console.log("Before crash - ETH price and position status:");
        
        (uint256 ethPrice,,,) = IMockOracle(oracle).getCurrentMarketPrices();
        console.log("Current ETH price:", ethPrice);
        
        uint256 ratio = ILoanManager(loanManager).getCollateralizationRatio(1);
        bool canLiquidate = ILoanManager(loanManager).canLiquidate(1);
        console.log("Position 1 ratio:", ratio);
        console.log("Position 1 can liquidate:", canLiquidate);
        
        // Crash to $1000 (with 8 decimals = 100000000000)
        console.log("");
        console.log("CRASHING ETH TO $1,000...");
        IMockOracle(oracle).setEthPrice(100000000000);
        
        // Step 4: Verify liquidation conditions
        console.log("");
        console.log("Step 4: After crash verification...");
        (uint256 newEthPrice,,,) = IMockOracle(oracle).getCurrentMarketPrices();
        console.log("New ETH price:", newEthPrice);
        
        uint256 newRatio = ILoanManager(loanManager).getCollateralizationRatio(1);
        bool newCanLiquidate = ILoanManager(loanManager).canLiquidate(1);
        console.log("Position 1 new ratio:", newRatio);
        console.log("Position 1 now liquidable:", newCanLiquidate);
        
        console.log("");
        if (newCanLiquidate) {
            console.log("SUCCESS! Position is now liquidable!");
            console.log("Chainlink automation should detect this and execute liquidation.");
        } else {
            console.log("Position still not liquidable. May need lower price.");
        }
        
        vm.stopBroadcast();
    }
} 