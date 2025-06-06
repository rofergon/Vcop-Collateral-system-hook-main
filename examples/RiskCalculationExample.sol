// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title RiskCalculationExample
 * @notice Ejemplo práctico de cómo funcionan los cálculos de riesgo en tiempo real
 * @dev Simula escenarios reales con precios cambiantes
 */
contract RiskCalculationExample {
    
    // Simulated price feeds for demonstration
    mapping(address => uint256) public mockPrices;
    
    // Example position data
    struct ExamplePosition {
        address collateralAsset;
        address loanAsset;
        uint256 collateralAmount;
        uint256 loanAmount;
        uint256 collateralRatio;    // 150% = 1500000
        uint256 liquidationRatio;   // 120% = 1200000
        uint256 interestRate;       // 5% = 50000
        uint256 createdAt;
    }
    
    // Mock tokens addresses (for example)
    address public constant ETH = 0x1111111111111111111111111111111111111111;
    address public constant USDC = 0x2222222222222222222222222222222222222222;
    address public constant WBTC = 0x3333333333333333333333333333333333333333;
    address public constant VCOP = 0x4444444444444444444444444444444444444444;
    
    constructor() {
        // Initialize mock prices (6 decimals)
        mockPrices[ETH] = 2000000000;   // $2,000
        mockPrices[USDC] = 1000000;     // $1.00
        mockPrices[WBTC] = 30000000000; // $30,000
        mockPrices[VCOP] = 240000;      // $0.24 (240 COP @ 1000 COP/USD)
    }
    
    /**
     * @dev EJEMPLO 1: Posición ETH -> USDC
     */
    function exampleETHtoUSDC() external view returns (
        string memory scenario,
        uint256 collateralizationRatio,
        string memory riskLevel,
        uint256 healthFactor,
        uint256 maxWithdrawableETH,
        uint256 liquidationPriceETH
    ) {
        scenario = "10 ETH collateral, 8000 USDC loan";
        
        // Position details
        uint256 collateralAmountETH = 10 * 1e18;    // 10 ETH
        uint256 loanAmountUSDC = 8000 * 1e6;        // 8000 USDC
        uint256 liquidationThreshold = 1200000;     // 120%
        
        // Calculate values in USD (6 decimals)
        uint256 collateralValueUSD = (collateralAmountETH * mockPrices[ETH]) / 1e18;
        uint256 loanValueUSD = (loanAmountUSDC * mockPrices[USDC]) / 1e6;
        
        // Calculate ratios
        collateralizationRatio = (collateralValueUSD * 1000000) / loanValueUSD;
        healthFactor = (collateralizationRatio * 1000000) / liquidationThreshold;
        
        // Risk level determination
        if (collateralizationRatio >= 2000000) riskLevel = "HEALTHY";
        else if (collateralizationRatio >= 1500000) riskLevel = "WARNING";
        else if (collateralizationRatio >= 1200000) riskLevel = "DANGER";
        else if (collateralizationRatio >= 1100000) riskLevel = "CRITICAL";
        else riskLevel = "LIQUIDATABLE";
        
        // Max withdrawable ETH (maintaining 150% ratio)
        uint256 minCollateralForLoan = (loanValueUSD * 1500000) / 1000000; // 150% requirement
        uint256 excessCollateralUSD = collateralValueUSD > minCollateralForLoan ? 
            collateralValueUSD - minCollateralForLoan : 0;
        maxWithdrawableETH = (excessCollateralUSD * 1e18) / mockPrices[ETH];
        
        // Liquidation price (ETH price where ratio = 120%)
        liquidationPriceETH = (loanValueUSD * liquidationThreshold) / (collateralAmountETH * 1000000 / 1e18);
    }
    
    /**
     * @dev EJEMPLO 2: Simulación de cambio de precio
     */
    function simulatePriceChange(uint256 newETHPrice) external returns (
        string memory description,
        uint256 oldRatio,
        uint256 newRatio,
        string memory oldRiskLevel,
        string memory newRiskLevel,
        bool liquidationTriggered
    ) {
        description = "Simulating ETH price change impact";
        
        // Original position: 10 ETH, 8000 USDC loan
        uint256 collateralAmountETH = 10 * 1e18;
        uint256 loanAmountUSDC = 8000 * 1e6;
        uint256 liquidationThreshold = 1200000; // 120%
        
        // Calculate old ratio
        uint256 oldCollateralValueUSD = (collateralAmountETH * mockPrices[ETH]) / 1e18;
        uint256 loanValueUSD = (loanAmountUSDC * mockPrices[USDC]) / 1e6;
        oldRatio = (oldCollateralValueUSD * 1000000) / loanValueUSD;
        
        // Calculate new ratio with new price
        uint256 newCollateralValueUSD = (collateralAmountETH * newETHPrice) / 1e18;
        newRatio = (newCollateralValueUSD * 1000000) / loanValueUSD;
        
        // Determine risk levels
        oldRiskLevel = _getRiskLevelString(oldRatio);
        newRiskLevel = _getRiskLevelString(newRatio);
        
        // Check if liquidation triggered
        liquidationTriggered = newRatio < liquidationThreshold;
        
        // Update mock price for future calls
        mockPrices[ETH] = newETHPrice;
    }
    
    /**
     * @dev EJEMPLO 3: Análisis de cartera multi-asset
     */
    function portfolioRiskAnalysis() external view returns (
        string memory description,
        uint256 totalCollateralUSD,
        uint256 totalDebtUSD,
        uint256 portfolioHealthFactor,
        uint256 positionsAtRisk,
        string memory overallRiskLevel
    ) {
        description = "Multi-asset portfolio risk analysis";
        
        // Position 1: 10 ETH -> 8000 USDC
        uint256 eth_collateral_usd = (10 * 1e18 * mockPrices[ETH]) / 1e18;
        uint256 usdc_loan_usd = (8000 * 1e6 * mockPrices[USDC]) / 1e6;
        
        // Position 2: 1 WBTC -> 2000 VCOP  
        uint256 wbtc_collateral_usd = (1 * 1e8 * mockPrices[WBTC]) / 1e8;
        uint256 vcop_loan_usd = (2000 * 1e6 * mockPrices[VCOP]) / 1e6;
        
        // Position 3: 5000 USDC -> 1 ETH worth of VCOP
        uint256 usdc_collateral_usd = (5000 * 1e6 * mockPrices[USDC]) / 1e6;
        uint256 eth_worth_vcop = (mockPrices[ETH] * 1e6) / mockPrices[VCOP]; // VCOP amount worth 1 ETH
        uint256 vcop_loan_usd_2 = (eth_worth_vcop * mockPrices[VCOP]) / 1e6;
        
        // Portfolio totals
        totalCollateralUSD = eth_collateral_usd + wbtc_collateral_usd + usdc_collateral_usd;
        totalDebtUSD = usdc_loan_usd + vcop_loan_usd + vcop_loan_usd_2;
        
        // Portfolio health factor (weighted average)
        uint256 ratio1 = (eth_collateral_usd * 1000000) / usdc_loan_usd;
        uint256 ratio2 = (wbtc_collateral_usd * 1000000) / vcop_loan_usd;
        uint256 ratio3 = (usdc_collateral_usd * 1000000) / vcop_loan_usd_2;
        
        uint256 weightedHealthFactor = (
            (ratio1 * 1000000 / 1200000) * usdc_loan_usd +
            (ratio2 * 1000000 / 1200000) * vcop_loan_usd +
            (ratio3 * 1000000 / 1100000) * vcop_loan_usd_2  // Different threshold for USDC
        ) / totalDebtUSD;
        
        portfolioHealthFactor = weightedHealthFactor;
        
        // Count positions at risk
        positionsAtRisk = 0;
        if (ratio1 < 1500000) positionsAtRisk++; // Warning threshold
        if (ratio2 < 1500000) positionsAtRisk++;
        if (ratio3 < 1200000) positionsAtRisk++;  // Different threshold for stablecoin
        
        // Overall risk level
        if (portfolioHealthFactor >= 2000000) overallRiskLevel = "HEALTHY";
        else if (portfolioHealthFactor >= 1500000) overallRiskLevel = "WARNING";
        else if (portfolioHealthFactor >= 1200000) overallRiskLevel = "DANGER";
        else overallRiskLevel = "CRITICAL";
    }
    
    /**
     * @dev EJEMPLO 4: Proyección de riesgo futuro con intereses
     */
    function futureRiskProjection(uint256 daysInFuture) external view returns (
        string memory description,
        uint256 currentHealthFactor,
        uint256 futureHealthFactor,
        uint256 additionalInterest,
        uint256 daysToLiquidation
    ) {
        description = "30-day risk projection with interest accrual";
        
        // Position: 10 ETH, 8000 USDC loan, 5% annual interest
        uint256 collateralAmountETH = 10 * 1e18;
        uint256 loanAmountUSDC = 8000 * 1e6;
        uint256 interestRate = 50000; // 5% annual
        uint256 liquidationThreshold = 1200000; // 120%
        
        // Current state
        uint256 collateralValueUSD = (collateralAmountETH * mockPrices[ETH]) / 1e18;
        uint256 currentDebtUSD = (loanAmountUSDC * mockPrices[USDC]) / 1e6;
        uint256 currentRatio = (collateralValueUSD * 1000000) / currentDebtUSD;
        currentHealthFactor = (currentRatio * 1000000) / liquidationThreshold;
        
        // Future interest calculation
        uint256 timeInSeconds = daysInFuture * 24 * 3600;
        additionalInterest = (loanAmountUSDC * interestRate * timeInSeconds) / (365 * 24 * 3600 * 1000000);
        
        // Future debt
        uint256 futureDebtUSDC = loanAmountUSDC + additionalInterest;
        uint256 futureDebtUSD = (futureDebtUSDC * mockPrices[USDC]) / 1e6;
        uint256 futureRatio = (collateralValueUSD * 1000000) / futureDebtUSD;
        futureHealthFactor = (futureRatio * 1000000) / liquidationThreshold;
        
        // Calculate days to liquidation
        if (currentHealthFactor <= 1000000) {
            daysToLiquidation = 0; // Already liquidatable
        } else {
            // Simplified calculation - time for health factor to reach 1.0
            uint256 dailyInterestIncrease = (loanAmountUSDC * interestRate) / (365 * 1000000);
            uint256 currentDebtIncrease = currentDebtUSD - (loanAmountUSDC * mockPrices[USDC] / 1e6);
            
            // Days until debt grows enough to trigger liquidation
            uint256 debtAtLiquidation = (collateralValueUSD * 1000000) / liquidationThreshold;
            uint256 additionalDebtNeeded = debtAtLiquidation > currentDebtUSD ? 
                debtAtLiquidation - currentDebtUSD : 0;
                
            daysToLiquidation = additionalDebtNeeded > 0 ? additionalDebtNeeded / dailyInterestIncrease : type(uint256).max;
        }
    }
    
    /**
     * @dev EJEMPLO 5: Análisis de impacto de volatilidad
     */
    function volatilityImpactAnalysis() external view returns (
        string memory description,
        uint256 priceFor10PercentRisk,
        uint256 priceFor50PercentRisk,
        uint256 priceFor90PercentRisk,
        uint256 currentPrice,
        uint256 liquidationPrice
    ) {
        description = "ETH price levels for different liquidation risks";
        
        // Position: 10 ETH, 8000 USDC loan
        uint256 collateralAmountETH = 10 * 1e18;
        uint256 loanAmountUSDC = 8000 * 1e6;
        uint256 liquidationThreshold = 1200000; // 120%
        
        currentPrice = mockPrices[ETH];
        
        // Liquidation price (120% ratio)
        uint256 loanValueUSD = (loanAmountUSDC * mockPrices[USDC]) / 1e6;
        liquidationPrice = (loanValueUSD * liquidationThreshold) / (collateralAmountETH * 1000000 / 1e18);
        
        // Prices for different risk levels
        // 10% risk: 180% ratio
        priceFor10PercentRisk = (loanValueUSD * 1800000) / (collateralAmountETH * 1000000 / 1e18);
        
        // 50% risk: 140% ratio  
        priceFor50PercentRisk = (loanValueUSD * 1400000) / (collateralAmountETH * 1000000 / 1e18);
        
        // 90% risk: 125% ratio
        priceFor90PercentRisk = (loanValueUSD * 1250000) / (collateralAmountETH * 1000000 / 1e18);
    }
    
    // Helper function
    function _getRiskLevelString(uint256 ratio) internal pure returns (string memory) {
        if (ratio >= 2000000) return "HEALTHY";
        if (ratio >= 1500000) return "WARNING";
        if (ratio >= 1200000) return "DANGER";
        if (ratio >= 1100000) return "CRITICAL";
        return "LIQUIDATABLE";
    }
    
    /**
     * @dev Utility function to update mock prices (for testing)
     */
    function updateMockPrice(address asset, uint256 newPrice) external {
        mockPrices[asset] = newPrice;
    }
    
    /**
     * @dev Get current mock prices
     */
    function getAllPrices() external view returns (
        uint256 ethPrice,
        uint256 usdcPrice,
        uint256 wbtcPrice,
        uint256 vcopPrice
    ) {
        ethPrice = mockPrices[ETH];
        usdcPrice = mockPrices[USDC];
        wbtcPrice = mockPrices[WBTC];
        vcopPrice = mockPrices[VCOP];
    }
}

/*
EJEMPLOS DE USO DESDE FRONTEND:

// 1. Análisis básico de posición
const ethExample = await riskExample.exampleETHtoUSDC();
console.log(`Scenario: ${ethExample.scenario}`);
console.log(`Collateralization Ratio: ${ethExample.collateralizationRatio / 10000}%`);
console.log(`Risk Level: ${ethExample.riskLevel}`);
console.log(`Health Factor: ${ethExample.healthFactor / 1000000}`);

// 2. Simulación de cambio de precio
await riskExample.updateMockPrice(ETH_ADDRESS, 1800000000); // $1,800
const priceChangeResult = await riskExample.simulatePriceChange(1800000000);
console.log(`Old Ratio: ${priceChangeResult.oldRatio / 10000}%`);
console.log(`New Ratio: ${priceChangeResult.newRatio / 10000}%`);
console.log(`Liquidation Triggered: ${priceChangeResult.liquidationTriggered}`);

// 3. Análisis de cartera
const portfolio = await riskExample.portfolioRiskAnalysis();
console.log(`Total Collateral: $${portfolio.totalCollateralUSD / 1000000}`);
console.log(`Total Debt: $${portfolio.totalDebtUSD / 1000000}`);
console.log(`Portfolio Health: ${portfolio.portfolioHealthFactor / 1000000}`);

// 4. Proyección futura
const futureRisk = await riskExample.futureRiskProjection(30); // 30 days
console.log(`Current Health: ${futureRisk.currentHealthFactor / 1000000}`);
console.log(`Future Health: ${futureRisk.futureHealthFactor / 1000000}`);
console.log(`Days to Liquidation: ${futureRisk.daysToLiquidation}`);

// 5. Análisis de volatilidad
const volatility = await riskExample.volatilityImpactAnalysis();
console.log(`Current ETH Price: $${volatility.currentPrice / 1000000}`);
console.log(`Liquidation Price: $${volatility.liquidationPrice / 1000000}`);
console.log(`10% Risk Price: $${volatility.priceFor10PercentRisk / 1000000}`);
*/ 