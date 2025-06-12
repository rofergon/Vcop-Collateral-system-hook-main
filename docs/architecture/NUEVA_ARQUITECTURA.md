# 🏗️ NEW MODULAR ARCHITECTURE FOR COLLATERALIZED LOANS

## 📋 EXECUTIVE SUMMARY

The new architecture transforms the protocol from a monolithic VCOP-centric system to a modular platform that supports **any token as collateral OR as a loan asset**, including external tokens that the protocol cannot mint/burn.

## 🎯 ACHIEVED OBJECTIVES

### ✅ Total Flexibility
- **Any ERC20** can be collateral
- **Any ERC20** can be a loan token
- Support for tokens with/without minting control
- Unified interface for all asset types

### ✅ Vault System
- For external tokens (ETH, WBTC, etc.)
- Liquidity provided by LPs
- Interest for liquidity providers
- Dynamic interest rate calculation

### ✅ Hybrid Oracles
- Chainlink for reliable prices
- Uniswap v4 as fallback
- Manual prices for testing
- Support for multiple token pairs

### ✅ Risk Management
- Collateralization ratios per asset
- Automatic liquidations
- Exposure limits per token
- Bonuses for liquidators

## 🏛️ ARCHITECTURE COMPONENTS

### 1. CORE INTERFACES

#### `IAssetHandler`
```solidity
// Unified interface for handling different asset types
enum AssetType {
    MINTABLE_BURNABLE,  // VCOP and similar tokens
    VAULT_BASED,        // ETH, WBTC, external tokens
    REBASING            // Tokens with rebase mechanisms
}
```

#### `ILoanManager`
```solidity
// Loan management with any asset combination
struct LoanTerms {
    address collateralAsset;  // Any token as collateral
    address loanAsset;        // Any token as loan
    uint256 collateralAmount;
    uint256 loanAmount;
    uint256 maxLoanToValue;
    uint256 interestRate;
    uint256 duration;
}
```

#### `IGenericOracle`
```solidity
// Flexible oracle system
enum PriceFeedType {
    CHAINLINK,    // Chainlink feeds
    UNISWAP_V4,   // Uniswap v4 pools
    MANUAL,       // Manual prices
    HYBRID        // Combined sources
}
```

### 2. ASSET HANDLERS

#### `MintableBurnableHandler`
- **Purpose**: Handles tokens that the protocol can mint/burn
- **Use cases**: VCOP, protocol's own tokens
- **Operation**: 
  - Mints tokens directly to lender
  - Burns tokens from lender upon repayment
  - "Infinite" liquidity (limited by safety parameters)

#### `VaultBasedHandler`
- **Purpose**: Handles external tokens requiring vaults
- **Use cases**: ETH, WBTC, USDC, DAI, etc.
- **Operation**:
  - Liquidity providers deposit tokens
  - Utilization-based interest system
  - Lenders receive tokens from vault
  - Repayments go back to vault

### 3. LOAN MANAGER

#### `GenericLoanManager`
- **Total flexibility**: Any token as collateral + any token as loan
- **Position management**: Create, modify, liquidate positions
- **Risk calculations**: LTV, collateralization ratios, limits
- **Handler integration**: Delegates operations to specific handlers

### 4. MOCK TOKENS FOR TESTING

```solidity
// MockETH.sol - 18 decimals
// MockWBTC.sol - 8 decimals  
// MockUSDC.sol - 6 decimals
```

## 🔄 OPERATIONAL FLOW

### Scenario 1: VCOP Loan with ETH as Collateral
```
1. User deposits ETH as collateral
2. VaultBasedHandler verifies VCOP liquidity available
3. MintableBurnableHandler mints VCOP to user
4. Position created with ETH collateral + VCOP loan
```

### Scenario 2: ETH Loan with WBTC as Collateral
```
1. User deposits WBTC as collateral
2. VaultBasedHandler verifies ETH liquidity available
3. VaultBasedHandler transfers ETH from vault to user
4. Position created with WBTC collateral + ETH loan
```

### Scenario 3: USDC Loan with VCOP as Collateral
```
1. User deposits VCOP as collateral
2. VaultBasedHandler verifies USDC liquidity available
3. VaultBasedHandler transfers USDC from vault to user
4. Position created with VCOP collateral + USDC loan
```

## 📊 COMPARISON: BEFORE vs AFTER

| Aspect | Current System | New Architecture |
|---------|---------------|-------------------|
| **Loan tokens** | Only VCOP | Any ERC20 |
| **Collateral** | Only USDC | Any ERC20 |
| **Token control** | Absolute (mint/burn) | Flexible (mint/burn + vaults) |
| **Liquidity** | Unlimited (minting) | Vaults + LPs + minting |
| **Oracles** | Only VCOP/COP | Multiple pairs |
| **Flexibility** | Low | Very high |
| **Scalability** | Limited | Excellent |

## 🛠️ IMPLEMENTATION PLAN

### Phase 1: Core Interfaces and Contracts
- [x] `IAssetHandler.sol`
- [x] `ILoanManager.sol` 
- [x] `IGenericOracle.sol`
- [x] Mock tokens (ETH, WBTC, USDC)

### Phase 2: Asset Handlers (In development)
- [ ] `MintableBurnableHandler.sol`
- [ ] `VaultBasedHandler.sol`
- [ ] `GenericLoanManager.sol`

### Phase 3: Oracle System
- [ ] `GenericOracle.sol`
- [ ] `ChainlinkPriceFeed.sol`
- [ ] `UniswapV4PriceFeed.sol`
- [ ] `ManualPriceFeed.sol`

### Phase 4: Hook Integration
- [ ] `GenericCollateralHook.sol` (adaptation of current hook)
- [ ] Integration with Uniswap v4

### Phase 5: Migration and Testing
- [ ] Migration scripts
- [ ] Comprehensive tests
- [ ] Deployment scripts

## 🔧 MIGRATION FROM CURRENT SYSTEM

### Migration Steps:

1. **Deploy new contracts**
   ```bash
   # Deploy asset handlers
   forge script script/deploy/DeployAssetHandlers.s.sol
   
   # Deploy loan manager
   forge script script/deploy/DeployLoanManager.s.sol
   
   # Deploy oracle system
   forge script script/deploy/DeployOracle.s.sol
   ```

2. **Configure assets**
   ```solidity
   // Configure VCOP as mintable/burnable
   mintableBurnableHandler.configureAsset(
       vcopAddress,
       1500000, // 150% collateral ratio
       1200000, // 120% liquidation ratio
       10000000 * 1e6, // 10M VCOP max
       50000 // 5% interest rate
   );
   
   // Configure ETH as vault-based
   vaultBasedHandler.configureAsset(
       mockETHAddress,
       1300000, // 130% collateral ratio
       1100000, // 110% liquidation ratio
       1000 * 1e18, // 1000 ETH max
       80000 // 8% interest rate
   );
   ```

3. **Migrate existing positions**
   ```solidity
   // Script to migrate positions from previous system
   // to new GenericLoanManager
   ```

4. **Update frontend**
   ```javascript
   // New functions to interact with multiple tokens
   // UI for selecting collateral and loan asset
   // Dashboards for vault LPs
   ```

## 💡 NEW USE CASES

### For Users:
- **Flexible lending**: "I want to borrow USDC using my ETH as collateral"
- **Diversification**: "I have WBTC and want to get VCOP"
- **Arbitrage**: "I want to take advantage of price differences between tokens"

### For Liquidity Providers:
- **Yield farming**: "I deposit ETH in the vault and earn interest"
- **Risk management**: "I distribute liquidity across multiple assets"

### For the Protocol:
- **Scalability**: Support new tokens without code changes
- **Competitiveness**: Rival Aave, Compound
- **Innovation**: New financial products

## 🔐 SECURITY CONSIDERATIONS

### Risk Management:
- **Asset limits**: Maximum exposure per token
- **Dynamic ratios**: Automatic adjustment based on volatility
- **Circuit breakers**: Pause operations in extreme cases
- **Timelock**: Critical changes with delay

### Oracle Security:
- **Multiple sources**: Reduce single oracle risk
- **Price validation**: Detect anomalous prices
- **Heartbeat monitoring**: Verify data freshness

### Smart Contract Security:
- **Reentrancy guards**: Protection against attacks
- **Access control**: Granular permissions
- **Upgradability**: Secure upgrade system
- **Audit**: Security audits

## 📈 BENEFITS OF NEW ARCHITECTURE

### Technical:
- **Modularity**: Independent and testable components
- **Extensibility**: Easy to add new asset types
- **Maintainability**: Cleaner and organized code
- **Testability**: Improved unit and integration testing

### Business:
- **Market expansion**: Capture more users and liquidity
- **Revenue diversification**: Income from multiple assets
- **Competitive advantage**: Features others don't have
- **Future-proof**: Architecture ready for new tokens

### For Users:
- **More options**: Total asset flexibility
- **Better rates**: Competition between vaults
- **Improved UX**: Unified and intuitive interface
- **Lower risk**: Collateral diversification

## 🚀 NEXT STEPS

1. **Complete implementation** of asset handlers
2. **Develop robust** oracle system
3. **Integrate with Uniswap v4** updated hook
4. **Exhaustive testing** on testnet
5. **Security audit** before mainnet
6. **Gradual deployment** with initial limits
7. **Monitoring and optimization** post-deployment

---

This new architecture represents a qualitative leap towards a truly universal and competitive lending protocol. 🌟 