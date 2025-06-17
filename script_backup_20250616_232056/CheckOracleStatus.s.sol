// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {console2 as console} from "forge-std/console2.sol";
import {VCOPOracle} from "../src/VcopCollateral/VCOPOracle.sol";
import {GenericLoanManager} from "../src/core/GenericLoanManager.sol";
import {IGenericOracle} from "../src/interfaces/IGenericOracle.sol";

/**
 * @title CheckOracleStatus
 * @notice Simple script to check oracle status and diagnose communication problems
 */
contract CheckOracleStatus is Script {
    
    // Contract addresses from deployed system
    address constant ORACLE_ADDRESS = 0x73C9a11F981cb9B24c2E0589F398A13BE7f9687A;
    address constant GENERIC_LOAN_MANAGER = 0xc7506620C4Cb576686285099306318186Ff6CC25;
    
    // Mock token addresses on Base Sepolia
    address constant MOCK_ETH = 0xca09D6c5f9f5646A20b5EF71986EED5f8A86add0;
    address constant MOCK_USDC = 0xAdc9649EF0468d6C73B56Dc96fF6bb527B8251A0;
    address constant MOCK_WBTC = 0x6C2AAf9cFb130d516401Ee769074F02fae6ACb91;
    
    function run() external view {
        console.log("=== ORACLE STATUS CHECK ===");
        console.log("");
        
        VCOPOracle oracle = VCOPOracle(ORACLE_ADDRESS);
        GenericLoanManager loanManager = GenericLoanManager(GENERIC_LOAN_MANAGER);
        
        // Step 1: Basic connectivity
        _checkBasicConnectivity(oracle, loanManager);
        
        // Step 2: Check price feeds
        _checkPriceFeeds(oracle);
        
        // Step 3: Test specific token pairs
        _testTokenPairs(oracle);
        
        // Step 4: Check Chainlink feeds
        _checkChainlinkFeeds(oracle);
        
        // Step 5: Provide solutions
        _provideSolutions();
    }
    
    function _checkBasicConnectivity(VCOPOracle oracle, GenericLoanManager loanManager) internal view {
        console.log("1. BASIC CONNECTIVITY CHECK");
        console.log("===========================");
        
        try oracle.owner() returns (address owner) {
            console.log("Oracle accessible: YES");
            console.log("Oracle owner:", owner);
        } catch {
            console.log("Oracle accessible: NO - CRITICAL ERROR");
            return;
        }
        
        try loanManager.oracle() returns (IGenericOracle oracleContract) {
            address oracleAddr = address(oracleContract);
            console.log("LoanManager oracle:", oracleAddr);
            if (oracleAddr == ORACLE_ADDRESS) {
                console.log("Oracle addresses match: YES");
            } else {
                console.log("Oracle addresses match: NO - PROBLEM!");
                console.log("Expected:", ORACLE_ADDRESS);
                console.log("Actual  :", oracleAddr);
            }
        } catch {
            console.log("Cannot get oracle from LoanManager");
        }
        
        console.log("");
    }
    
    function _checkPriceFeeds(VCOPOracle oracle) internal view {
        console.log("2. PRICE FEED CONFIGURATION");
        console.log("============================");
        
        try oracle.mockETH() returns (address mockETH) {
            console.log("Mock ETH set:", mockETH);
        } catch {
            console.log("Mock ETH: NOT SET - PROBLEM!");
        }
        
        try oracle.mockWBTC() returns (address mockWBTC) {
            console.log("Mock WBTC set:", mockWBTC);
        } catch {
            console.log("Mock WBTC: NOT SET - PROBLEM!");
        }
        
        try oracle.mockUSDC() returns (address mockUSDC) {
            console.log("Mock USDC set:", mockUSDC);
        } catch {
            console.log("Mock USDC: NOT SET - PROBLEM!");
        }
        
        console.log("");
    }
    
    function _testTokenPairs(VCOPOracle oracle) internal view {
        console.log("3. TOKEN PAIR PRICE TESTS");
        console.log("==========================");
        
        // Test ETH/USDC
        console.log("Testing ETH/USDC...");
        try oracle.getPrice(MOCK_ETH, MOCK_USDC) returns (uint256 price) {
            console.log("ETH/USDC price:", price);
            if (price == 0) {
                console.log("WARNING: Price is zero");
            }
        } catch Error(string memory reason) {
            console.log("ETH/USDC failed:", reason);
        } catch {
            console.log("ETH/USDC failed: Unknown error");
        }
        
        // Test WBTC/USDC
        console.log("Testing WBTC/USDC...");
        try oracle.getPrice(MOCK_WBTC, MOCK_USDC) returns (uint256 price) {
            console.log("WBTC/USDC price:", price);
            if (price == 0) {
                console.log("WARNING: Price is zero");
            }
        } catch Error(string memory reason) {
            console.log("WBTC/USDC failed:", reason);
        } catch {
            console.log("WBTC/USDC failed: Unknown error");
        }
        
        // Test USDC/ETH (reverse)
        console.log("Testing USDC/ETH...");
        try oracle.getPrice(MOCK_USDC, MOCK_ETH) returns (uint256 price) {
            console.log("USDC/ETH price:", price);
            if (price == 0) {
                console.log("WARNING: Price is zero");
            }
        } catch Error(string memory reason) {
            console.log("USDC/ETH failed:", reason);
        } catch {
            console.log("USDC/ETH failed: Unknown error");
        }
        
        console.log("");
    }
    
    function _checkChainlinkFeeds(VCOPOracle oracle) internal view {
        console.log("4. CHAINLINK FEEDS CHECK");
        console.log("========================");
        
        try oracle.chainlinkEnabled() returns (bool enabled) {
            console.log("Chainlink enabled:", enabled);
            
            if (enabled) {
                console.log("Testing BTC feed...");
                try oracle.getBtcPriceFromChainlink() returns (uint256 btcPrice) {
                    console.log("BTC/USD price:", btcPrice);
                } catch {
                    console.log("BTC feed failed");
                }
                
                console.log("Testing ETH feed...");
                try oracle.getEthPriceFromChainlink() returns (uint256 ethPrice) {
                    console.log("ETH/USD price:", ethPrice);
                } catch {
                    console.log("ETH feed failed");
                }
            }
        } catch {
            console.log("Cannot check Chainlink status");
        }
        
        console.log("");
    }
    
    function _provideSolutions() internal view {
        console.log("5. SOLUTIONS TO TRY");
        console.log("===================");
        console.log("");
        
        console.log("IMMEDIATE FIXES:");
        console.log("");
        
        console.log("A) Set mock tokens in oracle:");
        console.log("cast send", ORACLE_ADDRESS);
        console.log("  'setMockTokens(address,address,address)'");
        console.log("  ", MOCK_ETH, MOCK_WBTC, MOCK_USDC);
        console.log("  --rpc-url $RPC_URL --private-key $PRIVATE_KEY");
        console.log("");
        
        console.log("B) Set manual prices (if Chainlink fails):");
        console.log("# ETH/USDC = $2500");
        console.log("cast send", ORACLE_ADDRESS);
        console.log("  'updatePrice(address,address,uint256)'");
        console.log("  ", MOCK_ETH, MOCK_USDC, "2500000000");
        console.log("  --rpc-url $RPC_URL --private-key $PRIVATE_KEY");
        console.log("");
        
        console.log("# WBTC/USDC = $70000");
        console.log("cast send", ORACLE_ADDRESS);
        console.log("  'updatePrice(address,address,uint256)'");
        console.log("  ", MOCK_WBTC, MOCK_USDC, "70000000000");
        console.log("  --rpc-url $RPC_URL --private-key $PRIVATE_KEY");
        console.log("");
        
        console.log("C) Test individual price calls:");
        console.log("cast call", ORACLE_ADDRESS);
        console.log("  'getPrice(address,address)' ", MOCK_ETH, MOCK_USDC);
        console.log("  --rpc-url $RPC_URL");
        console.log("");
        
        console.log("D) Use GenericLoanManager (has hardcoded prices):");
        console.log("   The current GenericLoanManager includes hardcoded prices");
        console.log("   as a fallback when oracle fails");
        console.log("");
        
        console.log("E) Check if the problem is in asset handlers:");
        console.log("   Run: make test-liquidation-permit2");
        console.log("   to see if the issue is in oracle or handlers");
        console.log("");
        
        console.log("QUICK DIAGNOSTIC COMMANDS:");
        console.log("make check-oracle-status    # Run this script");
        console.log("make test-liquidation-permit2  # Test liquidation");
        console.log("make check-chainlink-prices    # Check Chainlink feeds");
    }
} 