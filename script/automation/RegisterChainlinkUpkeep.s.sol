// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";

// Interfaces oficiales de Chainlink para Base Sepolia
interface LinkTokenInterface {
    function approve(address spender, uint256 amount) external returns (bool);
    function transfer(address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

interface AutomationRegistrarInterface {
    struct RegistrationParams {
        string name;
        bytes encryptedEmail;
        address upkeepContract;
        uint32 gasLimit;
        address adminAddress;
        uint8 triggerType;
        bytes checkData;
        bytes triggerConfig;
        bytes offchainConfig;
        uint96 amount;
    }
    
    function registerUpkeep(RegistrationParams calldata requestParams) external returns (uint256);
}

interface AutomationRegistryInterface {
    function getForwarder(uint256 upkeepId) external view returns (address);
}

/**
 * @title RegisterChainlinkUpkeep
 * @notice Script para registrar upkeep en el AutomationRegistry OFICIAL de Chainlink en Base Sepolia
 * @dev Usa las direcciones oficiales proporcionadas por el usuario
 */
contract RegisterChainlinkUpkeep is Script {
    
    // ✅ DIRECCIONES OFICIALES DE CHAINLINK PARA BASE SEPOLIA
    address constant CHAINLINK_REGISTRY = 0x91D4a4C3D448c7f3CB477332B1c7D420a5810aC3;
    address constant CHAINLINK_REGISTRAR = 0xf28D56F3A707E25B71Ce529a21AF388751E1CF2A;
    address constant LINK_TOKEN = 0xE4aB69C077896252FAFBD49EFD26B5D171A32410;
    
    // Chain ID de Base Sepolia
    uint256 constant BASE_SEPOLIA_CHAIN_ID = 84532;
    
    function run() external {
        // Verificar que estamos en Base Sepolia
        require(block.chainid == BASE_SEPOLIA_CHAIN_ID, "Must run on Base Sepolia");
        
        // Leer direcciones desplegadas desde el archivo JSON
        address automationKeeper = vm.envAddress("AUTOMATION_KEEPER_ADDRESS");
        address flexibleLoanManager = vm.envAddress("FLEXIBLE_LOAN_MANAGER_ADDRESS");
        
        console.log("=== CHAINLINK UPKEEP REGISTRATION ON BASE SEPOLIA ===");
        console.log("Chain ID:", block.chainid);
        console.log("Chainlink Registry (Official):", CHAINLINK_REGISTRY);
        console.log("Chainlink Registrar (Official):", CHAINLINK_REGISTRAR);
        console.log("LINK Token (Official):", LINK_TOKEN);
        console.log("Your Automation Keeper:", automationKeeper);
        console.log("Flexible Loan Manager:", flexibleLoanManager);
        console.log("");
        
        vm.startBroadcast();
        
        // 1. Configurar interfaces de Chainlink
        LinkTokenInterface link = LinkTokenInterface(LINK_TOKEN);
        AutomationRegistrarInterface registrar = AutomationRegistrarInterface(CHAINLINK_REGISTRAR);
        AutomationRegistryInterface registry = AutomationRegistryInterface(CHAINLINK_REGISTRY);
        
        // 2. Verificar balance de LINK
        uint256 linkBalance = link.balanceOf(msg.sender);
        console.log("Your LINK balance:", linkBalance);
        require(linkBalance >= 5e18, "Need at least 5 LINK tokens");
        
        // 3. Preparar checkData para el Keeper
        bytes memory checkData = abi.encode(
            flexibleLoanManager, // loan manager address
            uint256(0),         // start index
            uint256(20)         // batch size
        );
        
        // 4. Aprobar LINK para el Registrar
        uint96 fundingAmount = 5e18; // 5 LINK
        bool approved = link.approve(CHAINLINK_REGISTRAR, fundingAmount);
        require(approved, "LINK approval failed");
                 console.log("LINK approved for Registrar");
        
        // 5. Preparar parámetros de registro
        AutomationRegistrarInterface.RegistrationParams memory params = AutomationRegistrarInterface.RegistrationParams({
            name: "VCOP Loan Liquidation Monitor",     // nombre descriptivo
            encryptedEmail: bytes(""),                 // email encriptado (opcional)
            upkeepContract: automationKeeper,          // tu contrato de automation
            gasLimit: 2000000,                         // límite de gas (2M)
            adminAddress: msg.sender,                  // admin (tu dirección)
            triggerType: 0,                           // 0 = custom logic trigger
            checkData: checkData,                     // datos para checkUpkeep
            triggerConfig: bytes(""),                 // configuración de trigger (vacío para tipo 0)
            offchainConfig: bytes(""),                // configuración off-chain (vacío)
            amount: fundingAmount                     // cantidad de LINK a depositar
        });
        
        // 6. Registrar el Upkeep
        console.log("Registering Upkeep with official Chainlink Registry...");
        uint256 upkeepId = registrar.registerUpkeep(params);
        require(upkeepId != 0, "Upkeep registration failed");
        
                 console.log("UPKEEP REGISTERED SUCCESSFULLY!");
        console.log("Upkeep ID:", upkeepId);
        
        // 7. Obtener dirección del Forwarder
        address forwarder = registry.getForwarder(upkeepId);
        console.log("Forwarder Address:", forwarder);
        
        vm.stopBroadcast();
        
        // 8. Mostrar información para configurar el LoanAutomationKeeperOptimized
        console.log("");
        console.log("=== NEXT STEPS ===");
        console.log("1. Update your LoanAutomationKeeperOptimized to accept calls from Forwarder:");
        console.log("   Forwarder Address:", forwarder);
        console.log("");
        console.log("2. Register your FlexibleLoanManager in your AutomationRegistry:");
        console.log("   Call: registerLoanManager(", flexibleLoanManager, ", 100)");
        console.log("");
        console.log("3. Monitor your upkeep at: https://automation.chain.link/");
        console.log("   Select Base Sepolia network and look for Upkeep ID:", upkeepId);
        console.log("");
        console.log("4. CheckData being used:");
        console.logBytes(checkData);
        console.log("");
        console.log("=== REGISTRATION COMPLETE ===");
    }
} 