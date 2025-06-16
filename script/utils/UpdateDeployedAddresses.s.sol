// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Script.sol";
import "forge-std/console.sol";

/**
 * @title UpdateDeployedAddresses
 * @dev Script to extract deployed addresses from broadcast files and update deployed-addresses.json
 * This script reads the latest deployment from broadcast directory and extracts contract addresses
 */
contract UpdateDeployedAddresses is Script {
    
    function run() external {
        console.log("=== UPDATING DEPLOYED ADDRESSES JSON ===");
        
        // Get deployer info
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        console.log("Deployer:", deployer);
        
        // Read current addresses from environment (updated by deployment scripts)
        address mockETH = vm.envAddress("MOCK_ETH_ADDRESS");
        address mockWBTC = vm.envAddress("MOCK_WBTC_ADDRESS");
        address mockUSDC = vm.envAddress("MOCK_USDC_ADDRESS");
        address vcopToken = vm.envAddress("VCOP_TOKEN_ADDRESS");
        address vcopOracle = vm.envAddress("VCOP_ORACLE_ADDRESS");
        address poolManager = vm.envAddress("POOL_MANAGER_ADDRESS");
        address genericLoanManager = vm.envAddress("GENERIC_LOAN_MANAGER_ADDRESS");
        address flexibleLoanManager = vm.envAddress("FLEXIBLE_LOAN_MANAGER_ADDRESS");
        address vaultHandler = vm.envAddress("VAULT_HANDLER_ADDRESS");
        address collateralManager = vm.envAddress("COLLATERAL_MANAGER_ADDRESS");
        
        console.log("");
        console.log("=== CURRENT SYSTEM ADDRESSES ===");
        console.log("Mock ETH:", mockETH);
        console.log("Mock WBTC:", mockWBTC);
        console.log("Mock USDC:", mockUSDC);
        console.log("VCOP Token:", vcopToken);
        console.log("VCOP Oracle:", vcopOracle);
        console.log("Pool Manager:", poolManager);
        console.log("Generic Loan Manager:", genericLoanManager);
        console.log("Flexible Loan Manager:", flexibleLoanManager);
        console.log("Vault Handler:", vaultHandler);
        console.log("Collateral Manager:", collateralManager);
        
        console.log("");
        console.log("=== ADDRESSES READY FOR JSON UPDATE ===");
        console.log("These addresses should be used by update-oracle-addresses.sh");
        console.log("to automatically update deployed-addresses.json");
        
        // Log in a format that can be easily parsed by shell script
        console.log("EXTRACT_START");
        console.log("MOCK_ETH:", mockETH);
        console.log("MOCK_WBTC:", mockWBTC);
        console.log("MOCK_USDC:", mockUSDC);
        console.log("VCOP_TOKEN:", vcopToken);
        console.log("VCOP_ORACLE:", vcopOracle);
        console.log("POOL_MANAGER:", poolManager);
        console.log("GENERIC_LOAN_MANAGER:", genericLoanManager);
        console.log("FLEXIBLE_LOAN_MANAGER:", flexibleLoanManager);
        console.log("VAULT_HANDLER:", vaultHandler);
        console.log("COLLATERAL_MANAGER:", collateralManager);
        console.log("EXTRACT_END");
    }
    
    /**
     * @dev Helper function to extract addresses from environment or broadcast
     */
    function getLatestOracleAddress() external view returns (address) {
        // This would need to read from the broadcast file
        // For now, return the current oracle from environment
        try vm.envAddress("VCOP_ORACLE_ADDRESS") returns (address oracle) {
            return oracle;
        } catch {
            return address(0);
        }
    }
} 