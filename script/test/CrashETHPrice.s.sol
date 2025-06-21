// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script, console} from "forge-std/Script.sol";
import {MockVCOPOracle} from "../../src/VcopCollateral/MockVCOPOracle.sol";

contract CrashETHPrice is Script {
    
    address constant MOCK_ORACLE = 0x8C59715a208FDe0445d7046a6B4612796810C846;
    address constant MOCK_ETH = 0x5e2e783F84EF0b6D58115DF458F7F04e593011B7;
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        
        console.log("=== CRASHING ETH PRICE FOR LIQUIDATION TEST ===");
        
        MockVCOPOracle oracle = MockVCOPOracle(MOCK_ORACLE);
        
        // Crash ETH price from $2,500 to $1,000
        uint256 newPrice = 1000 * 1e6; // $1,000
        oracle.setEthPrice(newPrice);
        
        console.log("ETH price crashed to:", newPrice);
        console.log("Positions should now be liquidable!");
        console.log("Chainlink Automation will detect and liquidate automatically");
        
        vm.stopBroadcast();
    }
} 