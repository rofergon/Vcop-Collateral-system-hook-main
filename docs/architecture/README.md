# 🏗️ PROTOCOL ARCHITECTURE

This section contains all documentation related to the design and architecture of the VCOP Collateral protocol.

## 📁 CONTENT

### 📄 [NEW_ARCHITECTURE.md](./NUEVA_ARQUITECTURA.md)
**Complete protocol redesign for maximum flexibility**

**Includes:**
- ✅ Analysis of current vs proposed system
- ✅ Modular multi-token architecture
- ✅ Unified interfaces (IAssetHandler, ILoanManager, IGenericOracle)
- ✅ Component and flow diagrams
- ✅ 5-phase implementation plan
- ✅ Comparisons with Aave/Compound

### 📄 [MAXIMUM_FLEXIBILITY.md](./FLEXIBILIDAD_MAXIMA.md)
**Ultra-flexible system without hardcoded restrictions**

**Includes:**
- ✅ FlexibleLoanManager and FlexibleAssetHandler contracts
- ✅ Removal of ratio limits
- ✅ Frontend handles all risk management UX
- ✅ Extreme use cases (90%+ LTV allowed)
- ✅ Comparison: restrictive vs flexible system

### 📄 [CHAINLINK_AUTOMATION.md](./CHAINLINK_AUTOMATION.md)
**Advanced Chainlink Automation System v2.25.0**

**Includes:**
- ✅ Dual trigger system (Custom Logic + Log Automation)
- ✅ FlexibleLoanManager native integration
- ✅ Real-time price monitoring with DynamicPriceRegistry
- ✅ Multi-tier risk assessment (4 urgency levels)
- ✅ Volatility detection and temporary mode
- ✅ Gas optimization with intelligent batching
- ✅ Position tracking and performance metrics
- ✅ Emergency controls and backup procedures

## 🎯 NEW ARCHITECTURE OBJECTIVES

### **1. UNIVERSALITY**
- Any ERC20 as collateral or loan asset
- Support for mintable tokens (VCOP) and vault-based (ETH, WBTC)
- Integration with multiple oracles

### **2. FLEXIBILITY**
- Zero hardcoded limits in contracts
- Frontend controls entire user experience
- Users can assume any risk level

### **3. SCALABILITY**
- Easy to add new assets
- Modular asset handlers
- Architecture prepared for future expansions

### **4. COMPETITIVENESS**
- Overcomes Aave/Compound limitations
- Attracts professional traders and institutions
- Clear market differentiation

## 🔧 MAIN COMPONENTS

```
┌────────────────────────────────────────────────────────────┐
│                        ARCHITECTURE                        │
├────────────────────────────────────────────────────────────┤
│                                                            │
│  ┌─────────────────┐    ┌─────────────────┐                │
│  │ FlexibleLoan    │    │ RiskCalculator  │                │
│  │ Manager         │    │                 │                │
│  │                 │    │ • 15+ metrics   │                │
│  │ • Zero limits   │    │ • Real time     │                │
│  │ • Ultra flexible│    │ • Predictive    │                │
│  └─────────────────┘    └─────────────────┘                │
│                                                            │
│  ┌─────────────────┐    ┌─────────────────┐                │
│  │ FlexibleAsset   │    │ GenericOracle   │                │
│  │ Handler         │    │                 │                │
│  │                 │    │ • Chainlink     │                │
│  │ • Universal     │    │ • Uniswap v4    │                │
│  │ • Mintable +    │    │ • Manual feeds  │                │
│  │   Vault based   │    │ • Hybrid        │                │
│  └─────────────────┘    └─────────────────┘                │
│                                                            │
│  ┌─────────────────┐    ┌─────────────────┐                │
│  │ Chainlink       │    │ Automation      │                │
│  │ Automation      │    │ Log Triggers    │                │
│  │                 │    │                 │                │
│  │ • Custom Logic  │    │ • Price events  │                │
│  │ • Auto batching │    │ • Volatility    │                │
│  │ • Risk priority │    │ • Immediate     │                │
│  └─────────────────┘    └─────────────────┘                │
│                                                            │
└────────────────────────────────────────────────────────────┘
```

## 📊 COMPETITIVE ADVANTAGES

| Feature | Aave/Compound | VCOP New |
|---|---|---|
| **Supported tokens** | Fixed list | Any ERC20 |
| **LTV limits** | 80% typical | No limits |
| **Asset handlers** | Hardcoded | Modular |
| **Oracles** | Chainlink | Multi-oracle |
| **Flexibility** | Low | Maximum |
| **UX** | Standard | Customizable |

## 🚀 MIGRATION

### **Phase 1: Core Infrastructure**
- Deploy interfaces and base contracts
- Configure oracles and handlers

### **Phase 2: Asset Integration** 
- Configure ETH, WBTC, USDC, VCOP
- Extensive testing

### **Phase 3: Hook Integration**
- Integrate with Uniswap v4 hook
- PSM and stabilization

### **Phase 4: Advanced Features**
- Complete RiskCalculator
- Advanced metrics

### **Phase 5: Production**
- Gradual user migration
- Experience-differentiated interfaces

## 🔗 RELATED LINKS

- 📊 [Risk Management](../risk-management/) - Calculations and metrics
- 🚀 [Deployment](../deployment/) - Practical implementation
- 📚 [Main Documentation](../README.md) - General index 