# VCOP Protocol

A collateralized stablecoin backed by USDC with autonomous liquidation protection powered by **Chainlink Automation**.

## 🤖 Chainlink Automation Integration

VCOP features an advanced **automated liquidation system** that protects the protocol from bad debt 24/7. The system uses Chainlink Automation v2.25.0 with dual automation strategies:

- **🔧 Custom Logic Automation**: On-demand position scanning triggered by Chainlink when `checkUpkeep()` returns true
- **⚡ Log Trigger Automation**: Instant response to price change events from the DynamicPriceRegistry
- **🔄 Scalable Architecture**: Smart batch processing with O(1) position tracking and automatic cleanup
- **💰 Vault-Funded**: Uses protocol's own liquidity for liquidations (no external tokens needed)

### How It Actually Works
- **Custom Logic**: Chainlink calls `checkUpkeep()` → if liquidations needed → calls `performUpkeep()` 
- **Log Trigger**: Price change event → immediate `checkLog()` → urgent liquidations via `performUpkeep()`
- **Risk Assessment**: Positions with ratio ≤ 105% = Critical, ≤ 110% = Immediate, ≤ 120% = High priority
- **Batch Processing**: Handles up to 100 positions per upkeep with gas-safe early termination
- **Position Tracking**: O(1) add/remove operations with automatic cleanup of closed positions

**🤖 [chainlink automation deployment directory→](https://github.com/rofergon/Vcop-Collateral-system-hook-main/tree/main/src/automation)**

Chainlink upkeep ID  https://automation.chain.link/fuji/89357913212392754032676463092533081794653514582216481438918372876400233416330 Avalanche

## System Overview

VCOP is a collateralized stablecoin that maintains its target peg of 1 COP through:

- **Peg Stability Module (PSM)** operating via Uniswap v4 hook
- **Automated liquidation protection** via Chainlink Automation
- **Real-time price monitoring** and stabilization
- **Collateral-backed minting** with USDC reserves

### Core Components
- `VCOPCollateralized.sol`: Collateralized stablecoin token (6 decimals)
- `VCOPOracle.sol`: Price oracle for VCOP/COP and USD/COP rates
- `VCOPCollateralHook.sol`: Uniswap v4 hook implementing PSM
- `VCOPPriceCalculator.sol`: Price calculation utilities
- `LoanAutomationKeeperOptimized.sol`: Chainlink automation keeper
- `PriceChangeLogTrigger.sol`: Price change event automation

## System Architecture

```
┌──────────────────────── CHAINLINK AUTOMATION ─────────────────────────┐
│                                                                       │
│  ┌──────────────────────┐            ┌─────────────────────────────┐  │
│  │   Custom Logic       │            │      Log Trigger            │  │
│  │   (On-demand)        │            │      (Event-based)          │  │
│  │                      │            │                             │  │
│  │ LoanKeeperOptimized  │            │ PriceChangeLogTrigger       │  │
│  │ - checkUpkeep()      │            │ - DynamicPriceRegistry      │  │
│  │ - performUpkeep()    │            │ - Multi-tier urgency        │  │
│  │ - Batch processing   │            │ - checkLog() + performUpkeep│  │
│  └──────────┬───────────┘            └─────────────┬───────────────┘  │
│             │                                      │                  │
│             └─────────────┬────────────────────────┘                  │
└───────────────────────────┼───────────────────────────────────────────┘
                            │
                    ┌───────▼───────┐
                    │ Automation    │
                    │ Adapter       │
                    │ (O(1) tracking│
                    │ + Bridge)     │
                    └───────┬───────┘
                            │
┌───────────────────────────┼───── CORE LENDING SYSTEM ────────────────────┐
│                           │                                              │
│  ┌────────────────────────▼───┐    ┌─────────────────────────────────┐   │
│  │   FlexibleLoanManager      │    │     DynamicPriceRegistry        │   │
│  │                            │    │                                 │   │
│  │ • vaultFundedLiquidation() │◄───┤ • TokenPriceUpdated events      │   │
│  │ • O(1) position tracking   │    │ • Oracle integration            │   │
│  │ • Emergency coordination   │────┤ • Fallback pricing              │   │
│  └──────────┬─────────────────┘    └────────────────┬────────────────┘   │
│             │                                       │                    │
│             │                                       │                    │
│             │           ┌─────────────────────┐     │                    │
│             └──────────►│ VaultBasedHandler   │◄────┘                    │
│                         │ • Automation funding│                          │
│                         │ • automationRepay() │                          │
│                         │ • Emergency modes   │                          │
│                         └──────────┬──────────┘                          │
└────────────────────────────────────┼─────────────────────────────────────┘
                                     │
┌────────────────────────────────────┼───── UNISWAP V4 + PSM ─────────────┐
│                                    │                                    │
│                          ┌─────────▼─────────┐                          │
│                          │ VCOPCollateralHook│                          │
│                          │ (PSM + Hook)      │                          │
│                          │                   │                          │
│                          │ • Peg maintenance │                          │
│                          │ • Price monitoring│                          │
│                          │ • User PSM swaps  │                          │
│                          │ • Hook callbacks  │                          │
│                          └─────────┬─────────┘                          │
│                                    │                                    │
│  ┌─────────────────────────────────┼─────────────────────────────────┐  │
│  │             Uniswap v4 Pool     │                                 │  │
│  │                                 │                                 │  │
│  │  VCOP/USDC Liquidity            │                                 │  │
│  │  Price Discovery                │                                 │  │
│  │  Swap Execution                 │                                 │  │
│  └─────────────────────────────────┼─────────────────────────────────┘  │
└────────────────────────────────────┼────────────────────────────────────┘
                                     │
           ┌─────────────────────────┼─────────────────────────┐
           │                         │                         │
           ▼                         ▼                         ▼
┌─────────────────┐ ┌──────────────────┐ ┌─────────────────────────┐
│CollateralManager│ │ RewardDistributor│ │    Emergency Registry   │
│                 │ │                  │ │                         │
│• PSM reserves   │ │• VCOP minting    │ │• Centralized emergency  │
│• Vault funding  │ │• Multi-pool      │ │• Cross-handler coord    │
│• VCOP mint/burn │ │• Stake tracking  │ │• Dynamic thresholds     │
└─────────────────┘ └──────────────────┘ └─────────────────────────┘
           │                         │
           └─────────────┬───────────┘
                         │
                         ▼
               ┌─────────────────────┐
               │  VCOPCollateralized │
               │                     │
               │ • ERC-20 token      │
               │ • Mint/burn control │
               │ • 6 decimal places  │
               │ • Minter roles      │
               └─────────────────────┘
```

## Key System Features

### 🛡️ Automated Liquidation Protection
The system uses **Chainlink Automation** to monitor loan positions and execute liquidations when needed:

- **Custom Logic Automation**: Chainlink triggers `checkUpkeep()` when positions need checking
- **Log Trigger Automation**: Instant response to price change events (1-2 blocks)
- **Risk-Based Prioritization**: Sorts positions by risk level (100 = critical, 95 = immediate)
- **Vault-Funded Liquidations**: Protocol provides its own liquidity via `vaultFundedAutomatedLiquidation()`

### 🔄 Peg Stability Module (PSM)
The PSM maintains VCOP's peg through direct USDC ↔ VCOP swaps:

- **Automated Stabilization**: Triggers when price deviates from 1 COP target
- **User Direct Access**: Manual PSM swaps available anytime
- **Vault-Funded Operations**: Uses protocol reserves for efficiency
- **Uniswap v4 Integration**: Monitors pool activity via hooks

### ⚡ Uniswap v4 Hook Integration
The `VCOPCollateralHook` provides real-time pool monitoring:

- **Price Monitoring**: Tracks VCOP/USDC price in real-time
- **Swap Intervention**: Can stabilize before large swaps break peg
- **Liquidity Tracking**: Monitors pool liquidity changes
- **Event Triggers**: Feeds price data to Chainlink Log Trigger automation

## How It Works

### Core Process Flows

#### 🔄 Automated Liquidation Process
```
1. Chainlink calls checkUpkeep() → LoanAutomationKeeperOptimized checks positions
2. If liquidatable positions found → returns performData with position IDs
3. Chainlink calls performUpkeep() → executes vaultFundedAutomatedLiquidation()
4. LoanManagerAutomationAdapter removes liquidated positions from tracking
```

#### 💱 PSM Operations
```
1. User/System initiates USDC ↔ VCOP swap
2. VCOPCollateralHook manages the swap logic
3. VCOPCollateralManager handles reserves and minting
4. Price maintained at 1 VCOP = 1 COP target
```

#### 📊 Price Monitoring & Response
```
1. Uniswap v4 pool state changes trigger hook
2. VCOPOracle + PriceCalculator assess deviation
3. If outside bounds: Automated PSM stabilization
4. Log events trigger instant Chainlink response
```

### Key System Components

- **LoanAutomationKeeperOptimized**: Implements `checkUpkeep()` and `performUpkeep()` for Custom Logic automation
- **PriceChangeLogTrigger**: Implements `checkLog()` and `performUpkeep()` for Log Trigger automation  
- **LoanManagerAutomationAdapter**: Bridges automation to FlexibleLoanManager with O(1) position tracking
- **VCOPCollateralHook**: PSM operations + Uniswap v4 integration for price stability
- **FlexibleLoanManager**: Core lending logic with `vaultFundedAutomatedLiquidation()` function

## Requirements

- [Foundry](https://book.getfoundry.sh/getting-started/installation)
- Node.js and npm
- ETH on Base Sepolia for gas fees
- USDC on Base Sepolia for collateral

## Installation

```bash
# Clone the repository
git clone https://github.com/your-username/VCOPstablecoinUniswapv4.git
cd VCOPstablecoinUniswapv4

# Install dependencies
forge install
```

## Key Commands

### Mainnet Operations

```bash
# Check PSM status and reserves on mainnet
make check-psm-mainnet

# Check current prices from the oracle on mainnet
make check-prices-mainnet

# Swap VCOP for USDC on mainnet (default 100 VCOP)
make swap-vcop-to-usdc-mainnet [AMOUNT=X]

# Swap USDC for VCOP on mainnet (default 100 USDC)
make swap-usdc-to-vcop-mainnet [AMOUNT=X]

# Check rates from oracle on mainnet
make check-new-oracle-mainnet

# Run interactive mainnet command script
./script/MainnetCommands.sh
```

### PSM Operations (Testnet)

```bash
# Check PSM status and reserves
make check-psm

# Check current prices from the oracle
make check-prices

# Swap VCOP for USDC (default 100 VCOP)
make swap-vcop-to-usdc [AMOUNT=X]

# Swap USDC for VCOP (default 100 USDC)
make swap-usdc-to-vcop [AMOUNT=X]
```

### System Management

```bash
# Update oracle to fix conversion rate
make update-oracle

# Deploy entire system with fixed parity
make deploy-fixed-system

# Clean pending transactions
make clean-txs

# Test a swap with the newly deployed system
make test-new-system
```

### Loan System

```bash
# Test full loan cycle (create, add collateral, withdraw, repay)
make test-loans

# Test loan liquidation mechanism
make test-liquidation

# Test PSM functionality
make test-psm

# Create position with specific collateral amount (default 1000 USDC)
make create-position [COLLATERAL=X]
```

## Deployment Flow

### Testnet Deployment

You can deploy the system on Base Sepolia with:

```bash
forge script script/DeployFullSystemFixedParidad.s.sol:DeployFullSystemFixedParidad --rpc-url https://sepolia.base.org --broadcast --gas-price 3000000000 -vv
```

### Mainnet Deployment

The system is already deployed on Base mainnet. If you need to deploy a new instance, you can use:

```bash
# Deploy the system to Base mainnet
make deploy-mainnet

# Or use the deployment script directly
./script/DeployMainnet.sh
```

After deployment, you can verify contracts using:

```bash
./tools/verify-contracts.sh
```

The deployed contracts are documented in `docs/MAINNET_DEPLOYMENT_RECORD.md`.

## Security

This code is experimental and has not been audited. Use at your own risk. 
