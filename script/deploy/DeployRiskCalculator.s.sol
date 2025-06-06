// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {RiskCalculator} from "../../src/core/RiskCalculator.sol";

/**
 * @title DeployRiskCalculator
 * @notice Deploy RiskCalculator contract using existing core system
 */
contract DeployRiskCalculator is Script {
    
    // Deployed addresses from core system (Base Sepolia)
    address constant ORACLE_ADDRESS = address(0); // Mock oracle - we'll use zero address for now
    address constant GENERIC_LOAN_MANAGER = 0x374A7b5353F2E1E002Af4DD02138183776037Ea2;
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        vm.startBroadcast(deployerPrivateKey);
        
        console.log("Deploying RiskCalculator...");
        console.log("Oracle address:", ORACLE_ADDRESS);
        console.log("Loan Manager:", GENERIC_LOAN_MANAGER);
        
        // Deploy RiskCalculator
        RiskCalculator riskCalculator = new RiskCalculator(
            ORACLE_ADDRESS,
            GENERIC_LOAN_MANAGER
        );
        
        console.log("RiskCalculator deployed at:", address(riskCalculator));
        
        vm.stopBroadcast();
        
        // Save address to file
        string memory addressFile = string.concat(
            '{"riskCalculator":"',
            vm.toString(address(riskCalculator)),
            '"}'
        );
        
        vm.writeFile("risk-calculator-address.json", addressFile);
        console.log("Address saved to risk-calculator-address.json");
    }
} 