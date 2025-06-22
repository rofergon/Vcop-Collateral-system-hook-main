// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script, console} from "forge-std/Script.sol";

/**
 * @title IdentifyContract
 * @notice Identifica qué tipo de contrato está en la dirección VAULT_HANDLER
 */
contract IdentifyContract is Script {
    
    // Direcciones del sistema (desde deployed-addresses-mock.json)
    address constant VAULT_HANDLER = 0x72A1329B406C09F9dA9962d58EF9FE636b2E0380;
    address constant FLEXIBLE_LOAN_MANAGER = 0x1eE9bc6Eb8184b284D8efCCbB243F722834038e8;
    address constant MOCK_ETH = 0xdF84E1Bbf2111c8E5c78Ed7Ff3182CCdaeD9B108;
    address constant MOCK_USDC = 0xdA751521e60d094dC3A577D592ed59328a38dA93;
    
    function run() external view {
        console.log("=== IDENTIFYING CONTRACT TYPE ===");
        console.log("");
        
        console.log("Contract address:", VAULT_HANDLER);
        console.log("");
        
        // Test common asset handler functions
        console.log("TESTING ASSET HANDLER FUNCTIONS:");
        console.log("================================");
        _testFunction("isAssetSupported(address)", MOCK_ETH);
        _testFunction("getAssetConfig(address)", MOCK_ETH);
        _testFunction("getAvailableLiquidity(address)", MOCK_ETH);
        _testFunction("getAssetType(address)", MOCK_ETH);
        
        console.log("");
        console.log("TESTING VAULT FUNCTIONS:");
        console.log("========================");
        _testFunction("getVaultStats(address)", MOCK_ETH);
        _testFunction("baseInterestRate()", address(0));
        _testFunction("utilizationMultiplier()", address(0));
        
        console.log("");
        console.log("TESTING FLEXIBLE ASSET HANDLER FUNCTIONS:");
        console.log("=========================================");
        _testFunction("supportedAssets(uint256)", address(0));
        _testFunction("assetConfigs(address)", MOCK_ETH);
        
        console.log("");
        console.log("TESTING OWNERSHIP:");
        console.log("=================");
        _testFunction("owner()", address(0));
        
        console.log("");
        console.log("CHECKING FLEXIBLE LOAN MANAGER:");
        console.log("===============================");
        _checkLoanManager();
    }
    
    function _testFunction(string memory signature, address param) internal view {
        console.log("Testing:", signature);
        
        bytes memory calldata_;
        if (param != address(0)) {
            if (keccak256(bytes(signature)) == keccak256("supportedAssets(uint256)")) {
                calldata_ = abi.encodeWithSignature(signature, uint256(0));
            } else {
                calldata_ = abi.encodeWithSignature(signature, param);
            }
        } else {
            calldata_ = abi.encodeWithSignature(signature);
        }
        
        (bool success, bytes memory data) = VAULT_HANDLER.staticcall(calldata_);
        
        if (success && data.length > 0) {
            console.log("SUCCESS - Function exists, data length:", data.length);
            
            // Try to decode common return types
            if (data.length == 32) {
                // Could be uint256, address, or bool
                if (keccak256(bytes(signature)) == keccak256("owner()")) {
                    address addr = abi.decode(data, (address));
                    console.log("  Result (address):", addr);
                } else if (keccak256(bytes(signature)) == keccak256("baseInterestRate()") || 
                          keccak256(bytes(signature)) == keccak256("utilizationMultiplier()")) {
                    uint256 value = abi.decode(data, (uint256));
                    console.log("  Result (uint256):", value);
                } else if (keccak256(bytes(signature)) == keccak256("isAssetSupported(address)")) {
                    bool value = abi.decode(data, (bool));
                    console.log("  Result (bool):", value);
                }
            } else {
                console.log("  Complex return data");
            }
        } else {
            console.log("FAILED - Function not found or reverted");
        }
    }
    
    function _checkLoanManager() internal view {
        console.log("Checking FlexibleLoanManager asset handlers...");
        
        // Check asset handlers mapping
        (bool success1, bytes memory data1) = FLEXIBLE_LOAN_MANAGER.staticcall(
            abi.encodeWithSignature("assetHandlers(uint8)", uint8(0)) // MINTABLE_BURNABLE
        );
        
        if (success1 && data1.length >= 32) {
            address handler0 = abi.decode(data1, (address));
            console.log("AssetType.MINTABLE_BURNABLE handler:", handler0);
        }
        
        (bool success2, bytes memory data2) = FLEXIBLE_LOAN_MANAGER.staticcall(
            abi.encodeWithSignature("assetHandlers(uint8)", uint8(1)) // VAULT_BASED
        );
        
        if (success2 && data2.length >= 32) {
            address handler1 = abi.decode(data2, (address));
            console.log("AssetType.VAULT_BASED handler:", handler1);
            
            if (handler1 == VAULT_HANDLER) {
                console.log("MATCH: This is the VAULT_BASED handler in LoanManager");
            } else {
                console.log("MISMATCH: Different address in LoanManager");
                console.log("Expected:", VAULT_HANDLER);
                console.log("Actual:", handler1);
            }
        }
        
        (bool success3, bytes memory data3) = FLEXIBLE_LOAN_MANAGER.staticcall(
            abi.encodeWithSignature("assetHandlers(uint8)", uint8(2)) // REBASING
        );
        
        if (success3 && data3.length >= 32) {
            address handler2 = abi.decode(data3, (address));
            console.log("AssetType.REBASING handler:", handler2);
        }
    }
} 