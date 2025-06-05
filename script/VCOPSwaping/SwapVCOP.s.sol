// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import {IPoolManager} from "v4-core/src/interfaces/IPoolManager.sol";
import {PoolKey} from "v4-core/src/types/PoolKey.sol";
import {PoolSwapTest} from "v4-core/src/test/PoolSwapTest.sol";
import {TickMath} from "v4-core/src/libraries/TickMath.sol";
import {CurrencyLibrary, Currency} from "v4-core/src/types/Currency.sol";
import {IHooks} from "v4-core/src/interfaces/IHooks.sol";
import {IERC20} from "openzeppelin-contracts/token/ERC20/IERC20.sol";
import "./VCOPSwapConfig.sol";

contract SwapVCOPScript is Script {
    // slippage tolerance
    uint160 public constant MIN_PRICE_LIMIT = TickMath.MIN_SQRT_PRICE + 1;
    uint160 public constant MAX_PRICE_LIMIT = TickMath.MAX_SQRT_PRICE - 1;

    // VCOP Token address - ACTUALIZADO
    address public constant VCOP_ADDRESS = 0x9Fcf266213854A7797A8a63183E180FeaD27fFc3;
    // USDC Token address - ACTUALIZADO
    address public constant USDC_ADDRESS = 0xa255BDcDa0673Fe52e26dB4c5016434a7f54C2E8;
    // VCOP Collateral Hook - ACTUALIZADO
    address public constant HOOK_ADDRESS = 0x8e8bF46E3dF822aA10dE530C022037F4FC3144c0;
    // Price Calculator - ACTUALIZADO
    address public constant PRICE_CALCULATOR_ADDRESS = 0x09E23D6828a2e23B0C77C2c7Ba91182b5A28Ad47;
    // Oracle - ACTUALIZADO
    address public constant ORACLE_ADDRESS = 0x41a2c54F5510303b5eBDf43d47dC9a7812ea0886;
    
    // Base Sepolia deployed contracts
    address public constant POOL_MANAGER = 0x05E73354cFDd6745C338b50BcFDfA3Aa6fA03408;
    address public constant UNIVERSAL_ROUTER = 0x492E6456D9528771018DeB9E87ef7750EF184104;
    address public constant POSITION_MANAGER = 0x4B2C77d209D3405F41a037Ec6c77F7F5b8e2ca80;
    address public constant POOL_SWAP_TEST = 0x8B5bcC363ddE2614281aD875bad385E0A785D3B9;
    address public constant PERMIT2 = 0x000000000022D473030F116dDEE9F6B43aC78BA3;

    // Pool configuration
    uint24 public constant LP_FEE = 3000; // 0.30%
    int24 public constant TICK_SPACING = 60;

    function run() external {
        // Cargar configuración desde VCOPSwapConfig
        VCOPSwapConfig config = new VCOPSwapConfig();
        bool comprarVCOP = config.COMPRAR_VCOP();
        uint256 cantidad = config.CANTIDAD();
        uint16 slippageMax = config.SLIPPAGE_MAX();
        
        // Obtener la dirección del deployer
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployerAddress = vm.addr(deployerPrivateKey);
        
        console.log("Modo:", comprarVCOP ? "Comprar VCOP con USDC" : "Vender VCOP por USDC");
        console.log("Cantidad:", cantidad / 10**6, "tokens");
        console.log("Direccion del deployer:", deployerAddress);
        console.log("VCOP Address:", VCOP_ADDRESS);
        console.log("USDC Address:", USDC_ADDRESS);
        console.log("Hook Address:", HOOK_ADDRESS);
        
        // Create pool key
        // VCOP es token0 y USDC es token1 según el log de despliegue
        PoolKey memory pool = PoolKey({
            currency0: Currency.wrap(VCOP_ADDRESS),
            currency1: Currency.wrap(USDC_ADDRESS),
            fee: LP_FEE,
            tickSpacing: TICK_SPACING,
            hooks: IHooks(HOOK_ADDRESS)
        });

        IERC20 vcopToken = IERC20(VCOP_ADDRESS);
        IERC20 usdcToken = IERC20(USDC_ADDRESS);
        
        // Mostrar balances iniciales
        uint256 vcopBalanceInicial = vcopToken.balanceOf(deployerAddress);
        uint256 usdcBalanceInicial = usdcToken.balanceOf(deployerAddress);
        console.log("Balance VCOP inicial:", vcopBalanceInicial / 10**6);
        console.log("Balance USDC inicial:", usdcBalanceInicial / 10**6);

        vm.startBroadcast(deployerPrivateKey);
        
        // Definir dirección del swap:
        // - Si compramos VCOP: USDC (token1) a VCOP (token0) -> zeroForOne = false
        // - Si vendemos VCOP: VCOP (token0) a USDC (token1) -> zeroForOne = true
        bool zeroForOne = !comprarVCOP;
        
        console.log("ZeroForOne:", zeroForOne, "(true = vender VCOP por USDC, false = comprar VCOP con USDC)");
        
        // Aprobar tokens según dirección
        if (comprarVCOP) {
            usdcToken.approve(POOL_SWAP_TEST, type(uint256).max);
        } else {
            vcopToken.approve(POOL_SWAP_TEST, type(uint256).max);
        }
        
        // amountSpecified negativo para entrada exacta
        IPoolManager.SwapParams memory params = IPoolManager.SwapParams({
            zeroForOne: zeroForOne,
            amountSpecified: -int256(cantidad),
            sqrtPriceLimitX96: zeroForOne ? MIN_PRICE_LIMIT : MAX_PRICE_LIMIT
        });

        // Configure test settings
        PoolSwapTest.TestSettings memory testSettings =
            PoolSwapTest.TestSettings({takeClaims: false, settleUsingBurn: false});

        // Execute the swap
        bytes memory hookData = new bytes(0);
        PoolSwapTest(POOL_SWAP_TEST).swap(pool, params, testSettings, hookData);
        
        vm.stopBroadcast();

        // Log balances after swap
        uint256 vcopBalance = vcopToken.balanceOf(deployerAddress);
        uint256 usdcBalance = usdcToken.balanceOf(deployerAddress);
        
        console.log("VCOP Balance final:", vcopBalance / 10**6);
        console.log("USDC Balance final:", usdcBalance / 10**6);
        
        // Calcular cambios evitando underflow
        if (vcopBalance > vcopBalanceInicial) {
            console.log("Cambio en VCOP:", (vcopBalance - vcopBalanceInicial) / 10**6);
        } else {
            console.log("Cambio en VCOP: -", (vcopBalanceInicial - vcopBalance) / 10**6);
        }
        
        if (usdcBalance > usdcBalanceInicial) {
            console.log("Cambio en USDC:", (usdcBalance - usdcBalanceInicial) / 10**6);
        } else {
            console.log("Cambio en USDC: -", (usdcBalanceInicial - usdcBalance) / 10**6);
        }
    }
} 