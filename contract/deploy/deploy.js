// Script de déploiement du contrat Invoice
// Nécessite : npm install ethers

const { ethers } = require('ethers');
const fs = require('fs');
const path = require('path');
require('dotenv').config();

const RPC_URL = process.env.RPC_URL || 'https://rpc.ankr.com/eth_sepolia'; // Testnet par défaut
const PRIVATE_KEY = process.env.PRIVATE_KEY;
const USDC_ADDRESS = process.env.USDC_ADDRESS || '0xA0b86a33E6417d69e83e5B5F4E4B4b0e'; // Adresse USDC sur le réseau

function loadContractArtifacts() {
  try {
    const artifactsPath = path.join(__dirname, '..', 'artifacts.json');
    if (!fs.existsSync(artifactsPath)) {
      throw new Error('Artifacts non trouvés. Exécutez "npm run compile" d\'abord.');
    }
    const artifacts = JSON.parse(fs.readFileSync(artifactsPath, 'utf8'));
    return {
      abi: artifacts.abi,
      bytecode: artifacts.bytecode
    };
  } catch (error) {
    console.error('❌ Erreur lors du chargement des artifacts:', error.message);
    process.exit(1);
  }
}

async function deployInvoiceContract() {
  try {
    console.log('🚀 Déploiement du contrat Invoice...');
    
    // Charger les artifacts du contrat
    const { abi, bytecode } = loadContractArtifacts();
    console.log('📁 Artifacts chargés avec succès');
    
    // Connexion au réseau
    const provider = new ethers.JsonRpcProvider(RPC_URL);
    const wallet = new ethers.Wallet(PRIVATE_KEY, provider);
    
    console.log(`📍 Réseau: ${RPC_URL}`);
    console.log(`👛 Wallet: ${wallet.address}`);
    
    // Vérifier le solde
    const balance = await provider.getBalance(wallet.address);
    console.log(`💰 Solde: ${ethers.formatEther(balance)} ETH`);
    
    if (balance === 0n) {
      throw new Error('⚠️ Solde insuffisant pour déployer');
    }
    
    // Créer la factory du contrat
    const contractFactory = new ethers.ContractFactory(abi, bytecode, wallet);
    
    // Déployer avec l'adresse USDC
    console.log(`📄 Déploiement avec USDC: ${USDC_ADDRESS}`);
    const contract = await contractFactory.deploy(USDC_ADDRESS);
    
    console.log(`⏳ Transaction hash: ${contract.deploymentTransaction().hash}`);
    
    // Attendre la confirmation
    await contract.waitForDeployment();
    
    console.log(`✅ Contrat déployé à l'adresse: ${await contract.getAddress()}`);
    console.log(`🔗 Ajoutez cette ligne à votre .env:`);
    console.log(`CONTRACT_ADDRESS=${await contract.getAddress()}`);
    
    return await contract.getAddress();
    
  } catch (error) {
    console.error('❌ Erreur de déploiement:', error);
    process.exit(1);
  }
}

// Exécuter le déploiement si le script est appelé directement
if (require.main === module) {
  deployInvoiceContract();
}

module.exports = { deployInvoiceContract };
