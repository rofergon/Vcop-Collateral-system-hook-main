// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC20} from "v4-core/lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

/**
 * @title MockWBTC
 * @notice Mock Wrapped Bitcoin token for testing the vault-based lending system
 */
contract MockWBTC is ERC20 {
    
    constructor() ERC20("Mock Wrapped Bitcoin", "mockWBTC") {
        // Mint initial supply to deployer for testing
        _mint(msg.sender, 21000 * 10**8); // 21K BTC (max supply)
    }
    
    /**
     * @dev Mints tokens to any address (for testing only)
     */
    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
    
    /**
     * @dev Returns 8 decimals (standard for WBTC)
     */
    function decimals() public pure override returns (uint8) {
        return 8;
    }
} 