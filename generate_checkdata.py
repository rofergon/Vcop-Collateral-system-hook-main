#!/usr/bin/env python3
"""
Generate correct checkData for Chainlink Automation
"""

# Your deployed addresses
loan_adapter = "0xAdc01a79f9120010a1dc7EAEdAAaEbfde128881F"
start_index = 0
batch_size = 25

def address_to_hex32(addr):
    """Convert address to 32-byte hex (64 chars)"""
    # Remove 0x prefix and pad to 64 chars
    clean_addr = addr.replace("0x", "").lower()
    return clean_addr.zfill(64)

def uint256_to_hex32(value):
    """Convert uint256 to 32-byte hex (64 chars)"""
    return f"{value:064x}"

def generate_checkdata():
    print("=== GENERATING CORRECT CHECKDATA ===")
    print(f"LoanAdapter: {loan_adapter}")
    print(f"StartIndex: {start_index}")
    print(f"BatchSize: {batch_size}")
    print()
    
    # Convert each parameter to 32-byte hex
    addr_hex = address_to_hex32(loan_adapter)
    start_hex = uint256_to_hex32(start_index)
    batch_hex = uint256_to_hex32(batch_size)
    
    print("32-byte components:")
    print(f"Address:    {addr_hex}")
    print(f"StartIndex: {start_hex}")
    print(f"BatchSize:  {batch_hex}")
    print()
    
    # Concatenate all parts
    checkdata = "0x" + addr_hex + start_hex + batch_hex
    
    print("=== FINAL CHECKDATA ===")
    print(checkdata)
    print()
    print(f"Length: {len(checkdata)} characters")
    print(f"Length without 0x: {len(checkdata) - 2} characters")
    print(f"Is even length: {(len(checkdata) - 2) % 2 == 0}")
    print()
    
    # Alternative: empty checkData
    print("=== ALTERNATIVE: EMPTY CHECKDATA ===")
    print("0x")
    print("(Some upkeeps work with empty checkData)")
    print()
    
    # Alternative: just address
    addr_only = "0x" + addr_hex
    print("=== ALTERNATIVE: ADDRESS ONLY ===")
    print(addr_only)
    print(f"Length: {len(addr_only)} characters")
    print(f"Is even length: {(len(addr_only) - 2) % 2 == 0}")

if __name__ == "__main__":
    generate_checkdata() 