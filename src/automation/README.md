# Sistema de Automatización con Chainlink Automation

Este directorio contiene todos los contratos necesarios para implementar un sistema de monitoreo automatizado de posiciones colateralizadas usando Chainlink Automation.

## 📁 Estructura del Directorio

```
src/automation/
├── interfaces/
│   ├── ILoanAutomation.sol          # Interface para loan managers
│   └── IAutomationRegistry.sol      # Interface para registro de managers
├── core/
│   ├── LoanAutomationKeeper.sol     # Contrato principal de Chainlink Automation
│   ├── AutomationRegistry.sol       # Registro de loan managers
│   └── LoanManagerAutomationAdapter.sol # Adapter para loan managers existentes
├── utils/
│   └── RiskCalculator.sol           # Calculadora de riesgo
└── README.md                        # Este archivo
```

## 🔧 Componentes del Sistema

### 1. **LoanAutomationKeeper** (Contrato Principal)
- Implementa `AutomationCompatibleInterface` de Chainlink
- Ejecuta `checkUpkeep` off-chain para detectar posiciones en riesgo
- Ejecuta `performUpkeep` on-chain para liquidar posiciones
- Soporta escaneo por lotes para manejar múltiples posiciones eficientemente

### 2. **AutomationRegistry** 
- Registra y gestiona múltiples loan managers
- Configura parámetros de batch size y umbrales de riesgo
- Autoriza contratos de automation

### 3. **LoanManagerAutomationAdapter**
- Adapta loan managers existentes para trabajar con automation
- Implementa `ILoanAutomation` interface
- Rastrea posiciones activas para escaneo eficiente
- Gestiona cooldowns de liquidación

### 4. **RiskCalculator**
- Calcula niveles de riesgo para posiciones
- Determina health factors y umbrales de liquidación
- Soporta evaluación batch de múltiples posiciones

## 🚀 Flujo de Operación

### Fase 1: Setup Inicial

1. **Deploy contracts:**
   ```solidity
   // 1. Deploy RiskCalculator
   RiskCalculator riskCalculator = new RiskCalculator(oracleAddress);
   
   // 2. Deploy AutomationRegistry
   AutomationRegistry registry = new AutomationRegistry();
   
   // 3. Deploy LoanAutomationKeeper
   LoanAutomationKeeper keeper = new LoanAutomationKeeper(address(registry));
   
   // 4. Deploy adapters for each loan manager
   LoanManagerAutomationAdapter adapter = new LoanManagerAutomationAdapter(
       loanManagerAddress,
       address(riskCalculator)
   );
   ```

2. **Configure Registry:**
   ```solidity
   // Register loan managers
   registry.registerLoanManager(
       address(adapter),
       "GenericLoanManager",
       50,  // batch size
       80   // risk threshold
   );
   
   // Authorize automation contract
   registry.setAutomationContractAuthorization(address(keeper), true);
   ```

3. **Configure Adapters:**
   ```solidity
   // Set automation contract
   adapter.setAutomationContract(address(keeper));
   
   // Initialize position tracking for existing positions
   uint256[] memory existingPositions = getExistingPositions();
   adapter.initializePositionTracking(existingPositions);
   ```

### Fase 2: Registro en Chainlink Automation

1. **Crear Upkeep en Chainlink:**
   - Visita [Chainlink Automation App](https://automation.chain.link/)
   - Selecciona "Custom Logic" trigger
   - Dirección del contrato: `address(keeper)`
   - Gas limit: 2,000,000
   - Funding: Cantidad apropiada de LINK

2. **Configurar checkData:**
   ```solidity
   // Para cada loan manager, crea un upkeep separado
   bytes memory checkData = keeper.generateCheckData(
       address(adapter),  // loan manager adapter
       0,                // start index
       50                // batch size
   );
   ```

### Fase 3: Monitoreo Automatizado

El sistema ejecutará automáticamente:

1. **checkUpkeep** (off-chain):
   - Escanea posiciones en el rango especificado
   - Calcula niveles de riesgo usando RiskCalculator
   - Identifica posiciones que requieren liquidación
   - Retorna datos para performUpkeep

2. **performUpkeep** (on-chain):
   - Verifica autorización y estado del sistema
   - Ejecuta liquidaciones para posiciones identificadas
   - Actualiza estadísticas y tracking

## 📊 Patrones de Escaneo

### Escaneo por Lotes (Recomendado)
```solidity
// Configurar múltiples upkeeps para diferentes rangos
// Upkeep 1: posiciones 0-49
// Upkeep 2: posiciones 50-99
// Upkeep 3: posiciones 100-149
// etc.

bytes memory checkData1 = abi.encode(managerAddress, 0, 50);
bytes memory checkData2 = abi.encode(managerAddress, 50, 50);
bytes memory checkData3 = abi.encode(managerAddress, 100, 50);
```

### Escaneo Rotativo
```solidity
// Un solo upkeep que rota por todas las posiciones
// El registry rastrea lastCheckedIndex automáticamente
```

## 🔒 Seguridad

### Forwarder (Opcional)
```solidity
// Configurar forwarder para seguridad adicional
keeper.setForwarderAddress(forwarderAddress);

// En performUpkeep, solo el forwarder puede ejecutar
require(msg.sender == forwarderAddress, "Unauthorized");
```

### Cooldowns de Liquidación
```solidity
// Prevenir múltiples intentos de liquidación
adapter.setLiquidationCooldown(300); // 5 minutos
```

### Pausa de Emergencia
```solidity
// Pausar automation en caso de emergencia
keeper.setEmergencyPause(true);
```

## 📈 Monitoreo y Estadísticas

### Estadísticas del Keeper
```solidity
(uint256 totalLiquidations, uint256 totalUpkeeps, uint256 lastExecution) = 
    keeper.getAutomationStats();
```

### Estadísticas del Registry
```solidity
(uint256 totalRegistered, uint256 totalActive, uint256 totalPositions) = 
    registry.getRegistryStats();
```

### Estadísticas de Tracking
```solidity
(uint256 tracked, uint256 atRisk, uint256 liquidatable) = 
    adapter.getTrackingStats();
```

## ⚠️ Consideraciones Importantes

### Límites de Gas
- `checkUpkeep`: Sin límite (off-chain)
- `performUpkeep`: 2,000,000 gas (configurable)
- Batch size debe ajustarse según complejidad de liquidaciones

### Costos de Automation
- Chainlink cobra por cada `performUpkeep` ejecutado
- Optimizar batch size para balance costo/eficiencia
- Considerar umbrales de riesgo para evitar liquidaciones innecesarias

### Integración con Loan Managers
- Los adapters requieren integración manual con cada loan manager
- Necesario actualizar tracking cuando se crean/cierran posiciones
- Sincronización periódica recomendada

## 🛠️ Extensiones Futuras

### Log Triggers
Para eventos específicos (cambios de precio drásticos):
```solidity
// Implementar ILogAutomation para triggers basados en eventos
contract PriceChangeAutomation is ILogAutomation {
    function checkLog(Log calldata log, bytes memory) external returns (bool, bytes memory) {
        // Detectar cambios de precio significativos
        // Triggear liquidaciones inmediatas
    }
}
```

### Multi-Chain Support
- Deploy en múltiples chains
- Centralizar monitoring dashboard
- Cross-chain liquidation coordination

### Advanced Risk Models
- Machine learning para predicción de riesgo
- Análisis de volatilidad en tiempo real
- Optimización dinámica de umbrales

## 📝 Scripts de Deployment

Ver `/script/` directory para scripts de deployment específicos.

## 🧪 Testing

Ver `/test/automation/` directory para tests comprehensivos.

---

**⚡ Este sistema está diseñado para ser modular, escalable y seguro, permitiendo monitoreo automatizado 24/7 de posiciones colateralizadas sin intervención manual.** 