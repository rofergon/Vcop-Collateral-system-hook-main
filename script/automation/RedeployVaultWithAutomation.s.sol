// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script, console} from "forge-std/Script.sol";
import {VaultBasedHandler} from "../../src/core/VaultBasedHandler.sol";
import {FlexibleLoanManager} from "../../src/core/FlexibleLoanManager.sol";
import {IAssetHandler} from "../../src/interfaces/IAssetHandler.sol";
import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

/**
 * @title RedeployVaultWithAutomation
 * @notice Redespliega VaultBasedHandler con funciones de automation
 */
contract RedeployVaultWithAutomation is Script {
    
    // Direcciones del sistema (desde .env)
    address constant OLD_VAULT_HANDLER = 0xDE9d27ed1945A64F79c497134CEf511d6C20d9Ee;
    address constant FLEXIBLE_LOAN_MANAGER = 0x9cAF99FDfAFdc412aAE2914cDB368E1806449B24;
    address constant AUTOMATION_KEEPER = 0x15C7298Dd649DcDc17D281cB0dAE84E945573c93;
    address constant MOCK_ETH = 0xff40519308154839EF5772CccE6012ccDEf5b32a;
    address constant MOCK_USDC = 0xabA8AFd2C637c27d09A893fe048A74f94D74108B;
    
    function run() external {
        console.log("=== REDEPLOYING VAULT WITH AUTOMATION ===");
        console.log("");
        
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        console.log("Deployer:", deployer);
        console.log("Old VaultBasedHandler:", OLD_VAULT_HANDLER);
        console.log("FlexibleLoanManager:", FLEXIBLE_LOAN_MANAGER);
        console.log("");
        
        vm.startBroadcast(deployerPrivateKey);
        
        // STEP 1: Deploy new VaultBasedHandler
        console.log("STEP 1: Deploying new VaultBasedHandler...");
        VaultBasedHandler newVault = new VaultBasedHandler();
        console.log("New VaultBasedHandler deployed at:", address(newVault));
        
        // STEP 2: Configure assets in new vault (copy from old one)
        console.log("");
        console.log("STEP 2: Configuring assets...");
        
        // Configure ETH asset
        newVault.configureAsset(
            MOCK_ETH,
            1500000,    // 150% collateral ratio
            1200000,    // 120% liquidation ratio
            1000 * 1e18, // 1000 ETH max loan
            80000       // 8% interest rate
        );
        console.log("ETH asset configured");
        
        // Configure USDC asset  
        newVault.configureAsset(
            MOCK_USDC,
            1100000,    // 110% collateral ratio
            1050000,    // 105% liquidation ratio
            1000000 * 1e6, // 1M USDC max loan
            50000       // 5% interest rate
        );
        console.log("USDC asset configured");
        
        // STEP 3: Authorize automation keeper
        console.log("");
        console.log("STEP 3: Authorizing automation keeper...");
        newVault.authorizeAutomationContract(AUTOMATION_KEEPER);
        console.log("Automation keeper authorized");
        
        // STEP 4: Transfer funds from old vault
        console.log("");
        console.log("STEP 4: Checking old vault balances...");
        uint256 oldEthBalance = IERC20(MOCK_ETH).balanceOf(OLD_VAULT_HANDLER);
        uint256 oldUsdcBalance = IERC20(MOCK_USDC).balanceOf(OLD_VAULT_HANDLER);
        
        console.log("Old vault ETH balance:", oldEthBalance / 1e18);
        console.log("Old vault USDC balance:", oldUsdcBalance / 1e6);
        
        // NOTE: We can't transfer funds automatically from old vault
        // Need to do it manually or through old vault owner
        console.log("NOTE: Manual fund transfer needed from old vault");
        
        // STEP 5: Update FlexibleLoanManager to use new vault
        console.log("");
        console.log("STEP 5: Updating FlexibleLoanManager...");
        FlexibleLoanManager loanManager = FlexibleLoanManager(FLEXIBLE_LOAN_MANAGER);
        loanManager.setAssetHandler(IAssetHandler.AssetType.VAULT_BASED, address(newVault));
        console.log("FlexibleLoanManager updated to use new vault");
        
        // STEP 6: Verify automation functions
        console.log("");
        console.log("STEP 6: Verifying automation functions...");
        
        bool isAuthorized = newVault.authorizedAutomationContracts(AUTOMATION_KEEPER);
        console.log("Automation keeper authorized:", isAuthorized);
        
        (uint256 available, uint256 liquidations, uint256 recovered, bool canLiquidate) = 
            newVault.getAutomationLiquidityStatus(MOCK_USDC);
        console.log("Available for automation:", available / 1e6, "USDC");
        console.log("Can liquidate:", canLiquidate);
        
        console.log("");
        console.log("DEPLOYMENT COMPLETE!");
        console.log("===================");
        console.log("New VaultBasedHandler:", address(newVault));
        console.log("Automation functions: AVAILABLE");
        console.log("Authorization status: COMPLETE");
        console.log("");
        console.log("NEXT STEPS:");
        console.log("1. Add liquidity to new vault");
        console.log("2. Test Chainlink automation");
        console.log("3. Monitor liquidation performance");
        console.log("");
        console.log("COMMANDS TO ADD LIQUIDITY:");
        console.log("vault.provideLiquidity(USDC, amount, provider)");
        console.log("vault.provideLiquidity(ETH, amount, provider)");
        
        vm.stopBroadcast();
    }
} 