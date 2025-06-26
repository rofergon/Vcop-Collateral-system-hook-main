/**
 * @fileoverview hook_createposition.ts
 * @description Hook de React para crear posiciones de préstamo usando wagmi v2 + viem v2
 * @version 2025 - Compatible con wagmi v2.x y viem v2.x
 * 
 * Replica la funcionalidad de CreateTestPosition.s.sol para el frontend
 */

import { useState, useCallback, useEffect } from 'react'
import { 
  useAccount, 
  useReadContract, 
  useWriteContract,
  useWaitForTransactionReceipt,
  useBalance,
  useChainId,
  type Address,
  type Hash
} from 'wagmi'
import { 
  formatUnits, 
  parseUnits,
  type Abi
} from 'viem'

// ===================================
// 🔧 TIPOS Y INTERFACES
// ===================================

export interface LoanTerms {
  collateralAsset: Address
  loanAsset: Address  
  collateralAmount: bigint
  loanAmount: bigint
  maxLoanToValue: bigint    // 6 decimals (800000 = 80%)
  interestRate: bigint      // 6 decimals (80000 = 8% APR)
  duration: bigint          // 0 = perpetual loan
}

export interface LoanPosition {
  borrower: Address
  collateralAsset: Address
  loanAsset: Address
  collateralAmount: bigint
  loanAmount: bigint
  interestRate: bigint
  createdAt: bigint
  lastInterestUpdate: bigint
  isActive: boolean
}

export interface ContractAddresses {
  flexibleLoanManager: Address
  mockETH: Address
  mockUSDC: Address
  mockWBTC: Address
}

export interface CreatePositionState {
  isLoading: boolean
  error: string | null
  success: boolean
  positionId: bigint | null
  txHash: Hash | null
  step: 'idle' | 'checking' | 'approving' | 'creating' | 'verifying' | 'completed'
}

export interface UseCreatePositionProps {
  addresses: ContractAddresses
  autoVerifyBalances?: boolean
  minETHBalance?: bigint
  minUSDCBalance?: bigint
}

// ===================================
// 📋 ABIs NECESARIOS
// ===================================

// ABI para ERC20 (approve, balanceOf)
const ERC20_ABI = [
  {
    name: 'approve',
    type: 'function',
    stateMutability: 'nonpayable',
    inputs: [
      { name: 'spender', type: 'address' },
      { name: 'amount', type: 'uint256' }
    ],
    outputs: [{ name: '', type: 'bool' }]
  },
  {
    name: 'balanceOf', 
    type: 'function',
    stateMutability: 'view',
    inputs: [{ name: 'account', type: 'address' }],
    outputs: [{ name: '', type: 'uint256' }]
  },
  {
    name: 'allowance',
    type: 'function', 
    stateMutability: 'view',
    inputs: [
      { name: 'owner', type: 'address' },
      { name: 'spender', type: 'address' }
    ],
    outputs: [{ name: '', type: 'uint256' }]
  }
] as const

// ABI para ILoanManager (funciones principales)
const LOAN_MANAGER_ABI = [
  {
    name: 'createLoan',
    type: 'function',
    stateMutability: 'nonpayable',
    inputs: [{
      name: 'terms',
      type: 'tuple',
      components: [
        { name: 'collateralAsset', type: 'address' },
        { name: 'loanAsset', type: 'address' },
        { name: 'collateralAmount', type: 'uint256' },
        { name: 'loanAmount', type: 'uint256' },
        { name: 'maxLoanToValue', type: 'uint256' },
        { name: 'interestRate', type: 'uint256' },
        { name: 'duration', type: 'uint256' }
      ]
    }],
    outputs: [{ name: 'positionId', type: 'uint256' }]
  },
  {
    name: 'getPosition',
    type: 'function',
    stateMutability: 'view',
    inputs: [{ name: 'positionId', type: 'uint256' }],
    outputs: [{
      name: 'position',
      type: 'tuple', 
      components: [
        { name: 'borrower', type: 'address' },
        { name: 'collateralAsset', type: 'address' },
        { name: 'loanAsset', type: 'address' },
        { name: 'collateralAmount', type: 'uint256' },
        { name: 'loanAmount', type: 'uint256' },
        { name: 'interestRate', type: 'uint256' },
        { name: 'createdAt', type: 'uint256' },
        { name: 'lastInterestUpdate', type: 'uint256' },
        { name: 'isActive', type: 'bool' }
      ]
    }]
  },
  {
    name: 'getCollateralizationRatio',
    type: 'function',
    stateMutability: 'view',
    inputs: [{ name: 'positionId', type: 'uint256' }],
    outputs: [{ name: 'ratio', type: 'uint256' }]
  },
  {
    name: 'canLiquidate',
    type: 'function',
    stateMutability: 'view', 
    inputs: [{ name: 'positionId', type: 'uint256' }],
    outputs: [{ name: 'canLiquidate', type: 'bool' }]
  }
] as const

// ===================================
// 🎯 HOOK PRINCIPAL
// ===================================

export function useCreatePosition({
  addresses,
  autoVerifyBalances = true,
  minETHBalance = parseUnits('5', 18),      // 5 ETH mínimo
  minUSDCBalance = parseUnits('5000', 6)    // 5,000 USDC mínimo
}: UseCreatePositionProps) {
  
  // ===================================
  // 📊 ESTADO DEL HOOK
  // ===================================
  
  const [state, setState] = useState<CreatePositionState>({
    isLoading: false,
    error: null,
    success: false,
    positionId: null,
    txHash: null,
    step: 'idle'
  })

  // ===================================
  // 🔗 HOOKS DE WAGMI
  // ===================================
  
  const { address, isConnected } = useAccount()
  const chainId = useChainId()
  
  // Balances de tokens
  const { data: ethBalance } = useBalance({
    address,
    token: addresses.mockETH,
    query: { enabled: !!address && autoVerifyBalances }
  })
  
  const { data: usdcBalance } = useBalance({
    address, 
    token: addresses.mockUSDC,
    query: { enabled: !!address && autoVerifyBalances }
  })

  // Allowance de ETH para el LoanManager
  const { data: ethAllowance, refetch: refetchAllowance } = useReadContract({
    address: addresses.mockETH,
    abi: ERC20_ABI,
    functionName: 'allowance',
    args: address && addresses.flexibleLoanManager ? [address, addresses.flexibleLoanManager] : undefined,
    query: { enabled: !!address }
  })

  // Write contracts
  const { 
    writeContract: approve,
    data: approveHash,
    isPending: isApprovePending,
    error: approveError
  } = useWriteContract()

  const {
    writeContract: createLoan,
    data: createLoanHash, 
    isPending: isCreateLoanPending,
    error: createLoanError
  } = useWriteContract()

  // Wait for transactions
  const { isLoading: isApproveConfirming } = useWaitForTransactionReceipt({
    hash: approveHash,
    query: { enabled: !!approveHash }
  })

  const { 
    isLoading: isCreateLoanConfirming,
    isSuccess: isCreateLoanSuccess 
  } = useWaitForTransactionReceipt({
    hash: createLoanHash,
    query: { enabled: !!createLoanHash }
  })

  // ===================================
  // 🧮 FUNCIONES UTILITARIAS
  // ===================================

  const updateState = useCallback((updates: Partial<CreatePositionState>) => {
    setState(prev => ({ ...prev, ...updates }))
  }, [])

  const resetState = useCallback(() => {
    setState({
      isLoading: false,
      error: null,
      success: false,
      positionId: null,
      txHash: null,
      step: 'idle'
    })
  }, [])

  // Verificar balances de tokens
  const checkBalances = useCallback(() => {
    if (!autoVerifyBalances || !ethBalance || !usdcBalance) return { valid: true, message: '' }

    const ethAmount = ethBalance.value
    const usdcAmount = usdcBalance.value

    if (ethAmount < minETHBalance) {
      return {
        valid: false,
        message: `Insufficient ETH balance. Need at least ${formatUnits(minETHBalance, 18)} ETH, have ${formatUnits(ethAmount, 18)} ETH`
      }
    }

    if (usdcAmount < minUSDCBalance) {
      return {
        valid: false,
        message: `Insufficient USDC balance. Need at least ${formatUnits(minUSDCBalance, 6)} USDC, have ${formatUnits(usdcAmount, 6)} USDC`  
      }
    }

    return { valid: true, message: 'Balances sufficient' }
  }, [ethBalance, usdcBalance, minETHBalance, minUSDCBalance, autoVerifyBalances])

  // ===================================
  // 🎯 FUNCIÓN PRINCIPAL: CREAR POSICIÓN
  // ===================================

  const createPosition = useCallback(async (loanTerms?: Partial<LoanTerms>) => {
    if (!isConnected || !address) {
      updateState({ error: 'Wallet not connected' })
      return
    }

    try {
      updateState({ 
        isLoading: true, 
        error: null, 
        step: 'checking',
        success: false,
        positionId: null,
        txHash: null
      })

      // Step 1: Verificar balances
      const balanceCheck = checkBalances()
      if (!balanceCheck.valid) {
        updateState({ 
          error: balanceCheck.message,
          isLoading: false,
          step: 'idle'
        })
        return
      }

      // Step 2: Preparar términos del préstamo (valores por defecto)
      const defaultTerms: LoanTerms = {
        collateralAsset: addresses.mockETH,
        loanAsset: addresses.mockUSDC,
        collateralAmount: parseUnits('2', 18),        // 2 ETH
        loanAmount: parseUnits('2000', 6),            // 2,000 USDC  
        maxLoanToValue: 800000n,                      // 80% LTV (6 decimals)
        interestRate: 80000n,                         // 8% APR (6 decimals)
        duration: 0n                                  // Perpetual loan
      }

      const finalTerms = { ...defaultTerms, ...loanTerms }

      // Step 3: Verificar y aprobar collateral si es necesario
      const currentAllowance = ethAllowance || 0n
      if (currentAllowance < finalTerms.collateralAmount) {
        updateState({ step: 'approving' })
        
        await approve({
          address: addresses.mockETH,
          abi: ERC20_ABI,
          functionName: 'approve',
          args: [addresses.flexibleLoanManager, finalTerms.collateralAmount]
        })

        // Esperar confirmación de approve
        updateState({ step: 'approving' })
        // El useWaitForTransactionReceipt manejará la confirmación
      }

    } catch (error) {
      console.error('Error in createPosition:', error)
      updateState({
        error: error instanceof Error ? error.message : 'Unknown error occurred',
        isLoading: false,
        step: 'idle'
      })
    }
  }, [
    isConnected, 
    address, 
    addresses, 
    checkBalances, 
    ethAllowance,
    approve,
    updateState
  ])

  // ===================================
  // 🔄 EFECTOS PARA MANEJAR TRANSACCIONES
  // ===================================

  // Efecto para manejar confirmación de approve
  useEffect(() => {
    if (approveHash && !isApproveConfirming && state.step === 'approving') {
      // Approve confirmado, proceder a crear loan
      updateState({ step: 'creating' })
      refetchAllowance() // Actualizar allowance

      // Crear el préstamo
      const defaultTerms: LoanTerms = {
        collateralAsset: addresses.mockETH,
        loanAsset: addresses.mockUSDC,
        collateralAmount: parseUnits('2', 18),
        loanAmount: parseUnits('2000', 6),
        maxLoanToValue: 800000n,
        interestRate: 80000n,
        duration: 0n
      }

      createLoan({
        address: addresses.flexibleLoanManager,
        abi: LOAN_MANAGER_ABI,
        functionName: 'createLoan',
        args: [defaultTerms]
      })
    }
  }, [approveHash, isApproveConfirming, state.step, createLoan, addresses, refetchAllowance, updateState])

  // Efecto para manejar confirmación de createLoan 
  useEffect(() => {
    if (createLoanHash && isCreateLoanSuccess && state.step === 'creating') {
      updateState({ 
        step: 'completed',
        success: true,
        isLoading: false,
        txHash: createLoanHash
      })
    }
  }, [createLoanHash, isCreateLoanSuccess, state.step, updateState])

  // Efecto para manejar errores
  useEffect(() => {
    if (approveError) {
      updateState({
        error: `Approve failed: ${approveError.message}`,
        isLoading: false,
        step: 'idle'
      })
    }
  }, [approveError, updateState])

  useEffect(() => {
    if (createLoanError) {
      updateState({
        error: `Create loan failed: ${createLoanError.message}`,
        isLoading: false,
        step: 'idle'
      })
    }
  }, [createLoanError, updateState])

  // ===================================
  // 📊 DATOS CALCULADOS
  // ===================================

  const balanceInfo = {
    eth: ethBalance ? {
      value: ethBalance.value,
      formatted: formatUnits(ethBalance.value, 18),
      sufficient: ethBalance.value >= minETHBalance
    } : null,
    usdc: usdcBalance ? {
      value: usdcBalance.value,
      formatted: formatUnits(usdcBalance.value, 6),
      sufficient: usdcBalance.value >= minUSDCBalance
    } : null
  }

  const allowanceInfo = {
    current: ethAllowance || 0n,
    formatted: ethAllowance ? formatUnits(ethAllowance, 18) : '0',
    needsApproval: (ethAllowance || 0n) < parseUnits('2', 18)
  }

  // ===================================
  // 🎯 RETORNO DEL HOOK
  // ===================================

  return {
    // Estado principal
    ...state,
    
    // Funciones principales
    createPosition,
    resetState,
    
    // Información de balances
    balanceInfo,
    allowanceInfo,
    
    // Estados de transacciones
    isApprovePending: isApprovePending || isApproveConfirming,
    isCreateLoanPending: isCreateLoanPending || isCreateLoanConfirming,
    
    // Hashes de transacciones
    approveHash,
    createLoanHash,
    
    // Información de wallet
    isConnected,
    address,
    chainId,
    
    // Funciones utilitarias
    checkBalances: () => checkBalances(),
    
    // Constantes útiles
    defaultLoanTerms: {
      collateralAsset: addresses.mockETH,
      loanAsset: addresses.mockUSDC,
      collateralAmount: parseUnits('2', 18),
      loanAmount: parseUnits('2000', 6),
      maxLoanToValue: 800000n,
      interestRate: 80000n,
      duration: 0n
    } as LoanTerms
  }
}

// ===================================
// 🎨 HOOK PARA LEER POSICIÓN CREADA
// ===================================

export function useReadPosition(
  positionId: bigint | null,
  loanManagerAddress: Address
) {
  // Leer detalles de la posición
  const { data: position, refetch: refetchPosition } = useReadContract({
    address: loanManagerAddress,
    abi: LOAN_MANAGER_ABI,
    functionName: 'getPosition',
    args: positionId ? [positionId] : undefined,
    query: { enabled: !!positionId }
  })

  // Leer ratio de collateralización
  const { data: collateralizationRatio } = useReadContract({
    address: loanManagerAddress,
    abi: LOAN_MANAGER_ABI,
    functionName: 'getCollateralizationRatio',
    args: positionId ? [positionId] : undefined,
    query: { enabled: !!positionId }
  })

  // Verificar si puede ser liquidada
  const { data: canLiquidate } = useReadContract({
    address: loanManagerAddress,
    abi: LOAN_MANAGER_ABI,
    functionName: 'canLiquidate',
    args: positionId ? [positionId] : undefined,
    query: { enabled: !!positionId }
  })

  const positionInfo = position ? {
    ...position,
    collateralizationRatio,
    canLiquidate,
    formattedRatio: collateralizationRatio ? `${Number(collateralizationRatio) / 10000}%` : undefined,
    healthStatus: collateralizationRatio 
      ? collateralizationRatio >= 1200000n ? 'HEALTHY' 
      : collateralizationRatio >= 1100000n ? 'AT_RISK'
      : 'LIQUIDATABLE'
      : undefined
  } : null

  return {
    position: positionInfo,
    refetchPosition,
    isLoading: positionId ? false : true // Simplificado para el ejemplo
  }
}

// ===================================
// 🎯 EJEMPLO DE USO
// ===================================

export const EXAMPLE_ADDRESSES: ContractAddresses = {
  flexibleLoanManager: '0xAdD8cA97DcbCf7373Da978bc7b61d6Ca31b54F8d',
  mockETH: '0xDe3fd80E2bcCc96f5FB43ac7481036Db9998f521',
  mockUSDC: '0x45BdA644DD25600b7d6DF4EC87E9710AD1DAE9d9',
  mockWBTC: '0x03f43Ce344D9988138b4807a7392A9feDea83AA1'
}

/*
// EJEMPLO DE USO EN COMPONENTE REACT:

import { useCreatePosition, EXAMPLE_ADDRESSES } from './hook_createposition'

export function CreatePositionComponent() {
  const {
    createPosition,
    isLoading,
    error,
    success,
    step,
    positionId,
    balanceInfo,
    allowanceInfo,
    isConnected
  } = useCreatePosition({
    addresses: EXAMPLE_ADDRESSES,
    autoVerifyBalances: true
  })

  if (!isConnected) {
    return <div>Please connect your wallet</div>
  }

  return (
    <div className="create-position">
      <h2>Create Loan Position</h2>
      
      {balanceInfo.eth && (
        <div>
          ETH Balance: {balanceInfo.eth.formatted} ETH
          {!balanceInfo.eth.sufficient && <span style={{color: 'red'}}> (Insufficient)</span>}
        </div>
      )}
      
      {balanceInfo.usdc && (
        <div>
          USDC Balance: {balanceInfo.usdc.formatted} USDC
          {!balanceInfo.usdc.sufficient && <span style={{color: 'red'}}> (Insufficient)</span>}
        </div>
      )}

      <div>Current Step: {step}</div>
      
      {error && <div style={{color: 'red'}}>{error}</div>}
      
      {success && positionId && (
        <div style={{color: 'green'}}>
          Position created successfully! Position ID: {positionId.toString()}
        </div>
      )}
      
      <button 
        onClick={() => createPosition()}
        disabled={isLoading}
      >
        {isLoading ? `${step}...` : 'Create Position'}
      </button>
    </div>
  )
}
*/ 