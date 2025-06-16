// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";
import {console2 as console} from "forge-std/console2.sol";
import {VCOPOracle} from "../../src/VcopCollateral/VCOPOracle.sol";
import {MockERC20} from "../../src/mocks/MockERC20.sol";

/**
 * @title DeployChainlinkOracle
 * @notice Deploys VCOPOracle with Chainlink integration on Base Sepolia
 */
contract DeployChainlinkOracle is Script {
    
    // Base Sepolia Chainlink Data Feeds
    address constant BTC_USD_FEED = 0x0FB99723Aee6f420beAD13e6bBB79b7E6F034298;
    address constant ETH_USD_FEED = 0x4aDC67696bA383F43DD60A9e78F2C97Fbbfc7cb1;
    
    // Pool Manager for Base Sepolia
    address constant POOL_MANAGER = 0x05E73354cFDd6745C338b50BcFDfA3Aa6fA03408;
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        vm.startBroadcast(deployerPrivateKey);
        
        console.log("Deploying Chainlink Oracle System on Base Sepolia...");
        console.log("Deployer:", vm.addr(deployerPrivateKey));
        
        // 1. Deploy Mock Tokens first (if needed)
        console.log("\nStep 1: Deploying Mock Tokens...");
        
        MockERC20 mockETH = new MockERC20("Mock Ethereum", "mETH", 18);
        MockERC20 mockWBTC = new MockERC20("Mock Wrapped Bitcoin", "mWBTC", 8);
        MockERC20 mockUSDC = new MockERC20("Mock USD Coin", "mUSDC", 6);
        MockERC20 mockVCOP = new MockERC20("Mock VCOP", "mVCOP", 18);
        
        console.log("Mock ETH deployed at:", address(mockETH));
        console.log("Mock WBTC deployed at:", address(mockWBTC));
        console.log("Mock USDC deployed at:", address(mockUSDC));
        console.log("Mock VCOP deployed at:", address(mockVCOP));
        
        // 2. Deploy VCOPOracle with Chainlink feeds
        console.log("\nStep 2: Deploying VCOPOracle with Chainlink...");
        
        // Constructor parameters in correct order:
        // (initialUsdToCopRate, poolManager, vcopAddress, usdcAddress, fee, tickSpacing, hookAddress)
        VCOPOracle oracle = new VCOPOracle(
            4000000,                              // initialUsdToCopRate (4000 COP per USD, 6 decimals)
            POOL_MANAGER,                         // poolManager
            address(mockVCOP),                    // vcopAddress  
            address(mockUSDC),                    // usdcAddress
            3000,                                 // fee (0.3%)
            60,                                   // tickSpacing
            address(0x1F2A7cF978520df3FF55D7A841eb2faadFA884c0) // hookAddress (from deployed-addresses.json)
        );
        
        console.log("VCOPOracle deployed at:", address(oracle));
        
        // 3. Configure mock tokens
        console.log("\nStep 3: Configuring mock tokens...");
        oracle.setMockTokens(address(mockETH), address(mockWBTC), address(mockUSDC));
        console.log("Mock tokens configured");
        
        // 4. Enable Chainlink by default
        console.log("\nStep 4: Enabling Chainlink feeds...");
        oracle.setChainlinkEnabled(true);
        console.log("Chainlink feeds enabled!");
        
        // 5. Mint some mock tokens to deployer for testing
        console.log("\nStep 5: Minting test tokens...");
        address deployer = vm.addr(deployerPrivateKey);
        
        mockETH.mint(deployer, 100 * 1e18);    // 100 ETH
        mockWBTC.mint(deployer, 10 * 1e8);     // 10 WBTC (8 decimals)
        mockUSDC.mint(deployer, 100000 * 1e6); // 100k USDC
        mockVCOP.mint(deployer, 1000000 * 1e18); // 1M VCOP
        
        console.log("Test tokens minted to deployer");
        
        // 6. Test initial oracle functionality
        console.log("\nStep 6: Testing initial oracle functionality...");
        
        try oracle.getBtcPriceFromChainlink() returns (uint256 btcPrice) {
            console.log("BTC/USD price from Chainlink:", btcPrice);
            if (btcPrice > 0) {
                console.log("BTC price feed working!");
            }
        } catch {
            console.log("BTC price feed not available");
        }
        
        try oracle.getEthPriceFromChainlink() returns (uint256 ethPrice) {
            console.log("ETH/USD price from Chainlink:", ethPrice);
            if (ethPrice > 0) {
                console.log("ETH price feed working!");
            }
        } catch {
            console.log("ETH price feed not available");
        }
        
        vm.stopBroadcast();
        
        // 7. Save deployment info
        console.log("\nDeployment Summary:");
        console.log("======================");
        console.log("Network: Base Sepolia");
        console.log("VCOPOracle:", address(oracle));
        console.log("Mock ETH:", address(mockETH));
        console.log("Mock WBTC:", address(mockWBTC));
        console.log("Mock USDC:", address(mockUSDC));
        console.log("Mock VCOP:", address(mockVCOP));
        console.log("BTC/USD Feed:", BTC_USD_FEED);
        console.log("ETH/USD Feed:", ETH_USD_FEED);
        console.log("Chainlink Enabled: true");
        console.log("");
        console.log("Next steps:");
        console.log("- Run 'make test-chainlink-oracle' to test functionality");
        console.log("- Check prices with 'make check-chainlink-prices'");
    }
} 