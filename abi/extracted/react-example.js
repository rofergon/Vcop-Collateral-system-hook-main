// react-example.js
// Ejemplo de configuración para React/Next.js con hooks personalizados

import { useState, useEffect, useCallback } from 'react';
import { ethers } from 'ethers';
import frontendConfig from './frontend-config.json';

// Hook personalizado para cargar ABIs
export function useContractABI(contractName) {
  const [contract, setContract] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    async function loadContract() {
      try {
        setLoading(true);
        setError(null);

        const config = frontendConfig.contracts[contractName];
        if (!config) {
          throw new Error(`Contract ${contractName} not found`);
        }

        // En un proyecto real, estos archivos estarían en la carpeta public
        const abiResponse = await fetch(`/abi/extracted/${config.abi}`);
        if (!abiResponse.ok) {
          throw new Error(`Failed to load ABI for ${contractName}`);
        }
        
        const abi = await abiResponse.json();
        
        setContract({
          address: config.address,
          abi: abi,
          name: contractName
        });
      } catch (err) {
        setError(err.message);
      } finally {
        setLoading(false);
      }
    }

    loadContract();
  }, [contractName]);

  return { contract, loading, error };
}

// Hook para Web3 Provider
export function useWeb3Provider() {
  const [provider, setProvider] = useState(null);
  const [signer, setSigner] = useState(null);
  const [account, setAccount] = useState(null);
  const [chainId, setChainId] = useState(null);

  const connectWallet = useCallback(async () => {
    try {
      if (!window.ethereum) {
        throw new Error('MetaMask not installed');
      }

      const provider = new ethers.providers.Web3Provider(window.ethereum);
      const network = await provider.getNetwork();
      
      // Verificar que estamos en Base Sepolia
      if (network.chainId !== 84532) {
        throw new Error('Please connect to Base Sepolia testnet');
      }

      await window.ethereum.request({ method: 'eth_requestAccounts' });
      const signer = provider.getSigner();
      const account = await signer.getAddress();

      setProvider(provider);
      setSigner(signer);
      setAccount(account);
      setChainId(network.chainId);

    } catch (error) {
      console.error('Error connecting wallet:', error);
      throw error;
    }
  }, []);

  return {
    provider,
    signer,
    account,
    chainId,
    connectWallet,
    isConnected: !!account
  };
}

// Hook específico para VCOP Token
export function useVCOPToken() {
  const { contract: vcopConfig, loading, error } = useContractABI('VCOPCollateralized');
  const { provider, signer } = useWeb3Provider();
  const [contract, setContract] = useState(null);

  useEffect(() => {
    if (vcopConfig && provider) {
      const vcopContract = new ethers.Contract(
        vcopConfig.address,
        vcopConfig.abi,
        signer || provider
      );
      setContract(vcopContract);
    }
  }, [vcopConfig, provider, signer]);

  const getBalance = useCallback(async (address) => {
    if (!contract) return null;
    try {
      const balance = await contract.balanceOf(address);
      return ethers.utils.formatUnits(balance, 6); // VCOP tiene 6 decimales
    } catch (error) {
      console.error('Error getting VCOP balance:', error);
      return null;
    }
  }, [contract]);

  const getTokenInfo = useCallback(async () => {
    if (!contract) return null;
    try {
      const [name, symbol, decimals, totalSupply] = await Promise.all([
        contract.name(),
        contract.symbol(),
        contract.decimals(),
        contract.totalSupply()
      ]);

      return {
        name,
        symbol,
        decimals,
        totalSupply: ethers.utils.formatUnits(totalSupply, decimals),
        address: vcopConfig.address
      };
    } catch (error) {
      console.error('Error getting token info:', error);
      return null;
    }
  }, [contract, vcopConfig]);

  const transfer = useCallback(async (to, amount) => {
    if (!contract || !signer) {
      throw new Error('Wallet not connected');
    }
    try {
      const tx = await contract.transfer(to, ethers.utils.parseUnits(amount, 6));
      return await tx.wait();
    } catch (error) {
      console.error('Error transferring VCOP:', error);
      throw error;
    }
  }, [contract, signer]);

  return {
    contract,
    loading,
    error,
    getBalance,
    getTokenInfo,
    transfer
  };
}

// Hook para Loan Manager
export function useLoanManager() {
  const { contract: loanConfig, loading, error } = useContractABI('FlexibleLoanManager');
  const { provider, signer } = useWeb3Provider();
  const [contract, setContract] = useState(null);

  useEffect(() => {
    if (loanConfig && provider) {
      const loanContract = new ethers.Contract(
        loanConfig.address,
        loanConfig.abi,
        signer || provider
      );
      setContract(loanContract);
    }
  }, [loanConfig, provider, signer]);

  const getUserPositions = useCallback(async (userAddress) => {
    if (!contract) return [];
    try {
      const positions = await contract.getUserPositions(userAddress);
      return positions;
    } catch (error) {
      console.error('Error getting user positions:', error);
      return [];
    }
  }, [contract]);

  const getPosition = useCallback(async (positionId) => {
    if (!contract) return null;
    try {
      const position = await contract.getPosition(positionId);
      return position;
    } catch (error) {
      console.error('Error getting position:', error);
      return null;
    }
  }, [contract]);

  const createLoan = useCallback(async (loanTerms) => {
    if (!contract || !signer) {
      throw new Error('Wallet not connected');
    }
    try {
      const tx = await contract.createLoan(loanTerms);
      return await tx.wait();
    } catch (error) {
      console.error('Error creating loan:', error);
      throw error;
    }
  }, [contract, signer]);

  return {
    contract,
    loading,
    error,
    getUserPositions,
    getPosition,
    createLoan
  };
}

// Hook para Oracle de precios
export function usePriceOracle() {
  const { contract: oracleConfig, loading, error } = useContractABI('MockVCOPOracle');
  const { provider } = useWeb3Provider();
  const [contract, setContract] = useState(null);
  const [prices, setPrices] = useState(null);

  useEffect(() => {
    if (oracleConfig && provider) {
      const oracleContract = new ethers.Contract(
        oracleConfig.address,
        oracleConfig.abi,
        provider
      );
      setContract(oracleContract);
    }
  }, [oracleConfig, provider]);

  const getCurrentPrices = useCallback(async () => {
    if (!contract) return null;
    try {
      const [usdToCop, vcopToCop] = await Promise.all([
        contract.getUsdToCopRateView(),
        contract.getVcopToCopRateView()
      ]);

      const priceData = {
        usdToCop: ethers.utils.formatUnits(usdToCop, 6),
        vcopToCop: ethers.utils.formatUnits(vcopToCop, 6),
        lastUpdated: new Date().toISOString()
      };

      setPrices(priceData);
      return priceData;
    } catch (error) {
      console.error('Error getting prices:', error);
      return null;
    }
  }, [contract]);

  // Actualizar precios automáticamente cada 30 segundos
  useEffect(() => {
    if (contract) {
      getCurrentPrices();
      const interval = setInterval(getCurrentPrices, 30000);
      return () => clearInterval(interval);
    }
  }, [contract, getCurrentPrices]);

  return {
    contract,
    loading,
    error,
    prices,
    getCurrentPrices
  };
}

// Componente de ejemplo de uso
export function VCOPDashboard() {
  const { account, connectWallet, isConnected } = useWeb3Provider();
  const { getBalance, getTokenInfo } = useVCOPToken();
  const { prices } = usePriceOracle();
  const { getUserPositions } = useLoanManager();

  const [vcopBalance, setVcopBalance] = useState(null);
  const [tokenInfo, setTokenInfo] = useState(null);
  const [userPositions, setUserPositions] = useState([]);

  useEffect(() => {
    if (isConnected && account) {
      loadUserData();
    }
  }, [isConnected, account]);

  const loadUserData = async () => {
    try {
      const [balance, info, positions] = await Promise.all([
        getBalance(account),
        getTokenInfo(),
        getUserPositions(account)
      ]);

      setVcopBalance(balance);
      setTokenInfo(info);
      setUserPositions(positions);
    } catch (error) {
      console.error('Error loading user data:', error);
    }
  };

  if (!isConnected) {
    return (
      <div className="dashboard">
        <h2>VCOP Dashboard</h2>
        <button onClick={connectWallet}>
          Conectar Wallet
        </button>
      </div>
    );
  }

  return (
    <div className="dashboard">
      <h2>VCOP Dashboard</h2>
      <div className="user-info">
        <p><strong>Account:</strong> {account}</p>
        <p><strong>VCOP Balance:</strong> {vcopBalance || 'Loading...'}</p>
      </div>

      {tokenInfo && (
        <div className="token-info">
          <h3>Token Information</h3>
          <p><strong>Name:</strong> {tokenInfo.name}</p>
          <p><strong>Symbol:</strong> {tokenInfo.symbol}</p>
          <p><strong>Total Supply:</strong> {tokenInfo.totalSupply}</p>
        </div>
      )}

      {prices && (
        <div className="price-info">
          <h3>Current Prices</h3>
          <p><strong>USD/COP:</strong> {prices.usdToCop}</p>
          <p><strong>VCOP/COP:</strong> {prices.vcopToCop}</p>
          <small>Last updated: {prices.lastUpdated}</small>
        </div>
      )}

      <div className="positions">
        <h3>Your Loan Positions</h3>
        {userPositions.length > 0 ? (
          <ul>
            {userPositions.map((positionId, index) => (
              <li key={index}>Position ID: {positionId.toString()}</li>
            ))}
          </ul>
        ) : (
          <p>No positions found</p>
        )}
      </div>

      <button onClick={loadUserData}>
        Refresh Data
      </button>
    </div>
  );
}

// Configuración para Next.js (next.config.js)
/*
const nextConfig = {
  async headers() {
    return [
      {
        source: '/abi/:path*',
        headers: [
          {
            key: 'Access-Control-Allow-Origin',
            value: '*',
          },
        ],
      },
    ];
  },
};

module.exports = nextConfig;
*/ 