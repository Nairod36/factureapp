// Service Node.js pour interagir avec les smart contracts
// Nécessite : npm install ethers dotenv

const { ethers } = require('ethers');
require('dotenv').config();

const RPC_URL = process.env.RPC_URL || 'https://rpc.ankr.com/eth';
const PRIVATE_KEY = process.env.PRIVATE_KEY;
const CONTRACT_ADDRESS = process.env.CONTRACT_ADDRESS;

// ABI du contrat Invoice (à adapter selon votre contrat)
const INVOICE_ABI = [
  "function creerFacture(address client, uint256 montant) external returns (uint256)",
  "function payerFacture(uint256 id) external",
  "function estPayee(uint256 id) external view returns (bool)",
  "function factures(uint256) external view returns (address marchand, address client, uint256 montant, bool payee)",
  "event FactureCreee(uint256 id, address marchand, address client, uint256 montant)",
  "event FacturePayee(uint256 id, address client)"
];

// Provider pour lire la blockchain
const provider = new ethers.JsonRpcProvider(RPC_URL);

// Wallet pour envoyer des transactions (optionnel)
const wallet = PRIVATE_KEY ? new ethers.Wallet(PRIVATE_KEY, provider) : null;

// Instance du contrat (lecture seule)
const contract = new ethers.Contract(CONTRACT_ADDRESS, INVOICE_ABI, provider);

// Instance du contrat avec wallet (pour écriture)
const contractWithSigner = wallet ? contract.connect(wallet) : null;

/**
 * Créer une facture sur le smart contract
 */
async function createInvoiceOnChain(clientAddress, amount) {
  if (!contractWithSigner) {
    throw new Error('Wallet non configuré pour les transactions');
  }
  try {
    const tx = await contractWithSigner.creerFacture(clientAddress, amount);
    const receipt = await tx.wait();
    
    // Récupérer l'ID de la facture depuis les events
    const event = receipt.logs.find(log => log.fragment?.name === 'FactureCreee');
    const invoiceId = event ? event.args[0] : null;
    
    return {
      success: true,
      txHash: tx.hash,
      invoiceId: invoiceId?.toString(),
      gasUsed: receipt.gasUsed.toString()
    };
  } catch (err) {
    console.error('Erreur création facture on-chain:', err);
    throw err;
  }
}

/**
 * Vérifier le statut de paiement d'une facture
 */
async function getInvoiceStatus(invoiceId) {
  try {
    const isPaid = await contract.estPayee(invoiceId);
    const invoiceData = await contract.factures(invoiceId);
    
    return {
      id: invoiceId,
      isPaid,
      merchant: invoiceData[0],
      client: invoiceData[1],
      amount: invoiceData[2].toString(),
      paid: invoiceData[3]
    };
  } catch (err) {
    console.error('Erreur lecture facture:', err);
    throw err;
  }
}

/**
 * Écouter les événements de paiement
 */
function listenToPaymentEvents(callback) {
  contract.on('FacturePayee', (id, client, event) => {
    callback({
      type: 'payment',
      invoiceId: id.toString(),
      client,
      txHash: event.transactionHash
    });
  });
}

module.exports = {
  createInvoiceOnChain,
  getInvoiceStatus,
  listenToPaymentEvents,
  provider,
  contract
};
