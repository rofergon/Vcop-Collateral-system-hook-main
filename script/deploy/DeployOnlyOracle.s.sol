// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {console2 as console} from "forge-std/console2.sol";
import {VCOPOracle} from "../../src/VcopCollateral/VCOPOracle.sol";

/**
 * @title DeployOnlyOracle
 * @notice Deploys ONLY the VCOPOracle with Chainlink integration using existing addresses from .env
 */
contract DeployOnlyOracle is Script {
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        // Load existing addresses from .env
        address poolManager = vm.envAddress("POOL_MANAGER_ADDRESS");
        address vcopToken = vm.envAddress("VCOP_TOKEN_ADDRESS");
        address mockUSDC = vm.envAddress("MOCK_USDC_ADDRESS");
        address hookAddress = vm.envAddress("VCOP_HOOK_ADDRESS");
        
        vm.startBroadcast(deployerPrivateKey);
        
        console.log("=== DEPLOYING VCOP ORACLE WITH CHAINLINK ===");
        console.log("Deployer:", vm.addr(deployerPrivateKey));
        console.log("Pool Manager:", poolManager);
        console.log("VCOP Token:", vcopToken);
        console.log("Mock USDC:", mockUSDC);
        console.log("Hook Address:", hookAddress);
        console.log("");
        
        // Deploy VCOPOracle with correct constructor parameters
        console.log("Deploying VCOPOracle...");
        
        VCOPOracle oracle = new VCOPOracle(
            4000000,          // initialUsdToCopRate (4000 COP per USD, 6 decimals)
            poolManager,      // _poolManager
            vcopToken,        // _vcopAddress
            mockUSDC,         // _usdcAddress
            3000,             // _fee (0.3%)
            60,               // _tickSpacing
            hookAddress       // _hookAddress
        );
        
        console.log("VCOPOracle deployed at:", address(oracle));
        
        // Test basic deployment
        console.log("\nTesting basic deployment...");
        console.log("Chainlink enabled:", oracle.chainlinkEnabled());
        console.log("Owner:", oracle.owner());
        
        // Test Chainlink constants
        console.log("\nChainlink feed addresses:");
        console.log("BTC/USD Feed:", oracle.BTC_USD_FEED());
        console.log("ETH/USD Feed:", oracle.ETH_USD_FEED());
        
        vm.stopBroadcast();
        
        console.log("\n=== DEPLOYMENT COMPLETED ===");
        console.log("New VCOPOracle address:", address(oracle));
        console.log("");
        console.log("IMPORTANT: Update your .env file:");
        console.log("VCOP_ORACLE_ADDRESS=", address(oracle));
        console.log("");
        console.log("Next steps:");
        console.log("1. Update .env with new VCOP_ORACLE_ADDRESS");
        console.log("2. Run: make configure-chainlink-oracle");
        console.log("3. Run: make test-chainlink-oracle");
        console.log("");
        console.log("Manual update command:");
        console.log("sed -i 's/VCOP_ORACLE_ADDRESS=.*/VCOP_ORACLE_ADDRESS=", address(oracle), "/' .env");
    }
} 