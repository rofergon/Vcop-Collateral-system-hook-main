# 🚀 VCOP Chainlink Automation Guide

## Quick Start

### For Production (Base Sepolia with real Chainlink)
```bash
# Complete stack deployment
make deploy-full-stack
```

### For Testing (Mock Oracle with Chainlink)
```bash
# Complete test deployment with mock oracle + official Chainlink
make deploy-full-stack-mock
```

## Step-by-Step Commands

### 1. Core System Deployment
```bash
# Deploy with real Oracle
make deploy-complete

# OR deploy with Mock Oracle for testing
make deploy-complete-mock
```

### 2. Chainlink Automation Setup

#### Complete Automation (Recommended)
```bash
# This handles everything automatically
make deploy-automation-complete
```

#### Manual Step-by-Step
```bash
# Step 1: Deploy automation contracts
make deploy-automation

# Step 2: Setup Chainlink environment
make setup-chainlink-automation

# Step 3: Register with Chainlink (requires 5+ LINK tokens)
make register-chainlink-upkeep

# Step 4: Update .env with Forwarder address
make update-forwarder-env

# Step 5: Configure Forwarder security
make configure-forwarder
```

## Prerequisites

### For Production Deployment
- Base Sepolia RPC URL in `.env`
- Private key with ETH for gas
- **5+ LINK tokens** (get from [Chainlink Faucet](https://faucets.chain.link/))

### For Testing (Mock Oracle)
- Base Sepolia RPC URL in `.env`
- Private key with ETH for gas
- **5+ LINK tokens** (same as production - uses official Chainlink)

## Chainlink Official Addresses (Base Sepolia)

- **Registry:** `0x91D4a4C3D448c7f3CB477332B1c7D420a5810aC3`
- **Registrar:** `0xf28D56F3A707E25B71Ce529a21AF388751E1CF2A`
- **LINK Token:** `0xE4aB69C077896252FAFBD49EFD26B5D171A32410`

## Monitoring

- **Chainlink Automation Dashboard:** https://automation.chain.link/
- Check status: `make check-chainlink-status`
- Test automation: `make test-automation-flow`

## Troubleshooting

### Common Issues

1. **"Insufficient LINK balance"**
   - Get LINK from: https://faucets.chain.link/
   - Select Base Sepolia network

2. **"Forwarder address not set"**
   - Run: `make update-forwarder-env`
   - Manually add to `.env`: `CHAINLINK_FORWARDER_ADDRESS=0x...`

3. **"Manager not registered"**
   - Ensure core system is deployed first
   - Check: `make check-status`

### Debug Commands
```bash
# Check all addresses
make check-addresses

# Check automation status
make check-automation-status

# Check Chainlink status
make check-chainlink-status

# Test oracle
make test-oracle
```

## Environment Variables

Required in `.env`:
```bash
# Network
RPC_URL=https://sepolia.base.org
CHAIN_ID=84532

# Wallet
PRIVATE_KEY=0x...

# Chainlink (added after registration)
CHAINLINK_FORWARDER_ADDRESS=0x...
```

## Architecture

### Production vs Mock
**Both systems now use the official Chainlink Automation infrastructure!**

- **Production**: Real Chainlink Oracle + Official Chainlink Automation
- **Mock**: Mock Oracle + Official Chainlink Automation (for testing price scenarios)

### Key Benefits
- **Unified Experience**: Same automation behavior in testing and production
- **Real Testing**: Test with actual Chainlink infrastructure
- **Simplified Maintenance**: One automation system to maintain

## Security Features

Your automation system includes:
- **Forwarder Restriction**: Only Chainlink can execute automation
- **Emergency Pause**: Owner can pause automation
- **Gas Optimization**: Batch processing for efficiency
- **Priority System**: Handle critical positions first 