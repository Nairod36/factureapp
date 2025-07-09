// Service Node.js pour interagir avec les smart contracts
// Nécessite : npm install ethers dotenv

const { ethers } = require('ethers');
require('dotenv').config();

const RPC_URL = process.env.RPC_URL || 'https://rpc.ankr.com/eth_sepolia';
const PRIVATE_KEY = process.env.PRIVATE_KEY;
const CONTRACT_ADDRESS = process.env.CONTRACT_ADDRESS;

// ABI complet du contrat Invoice
const INVOICE_ABI = [
  "function creerFacture(address client, uint256 montant, string calldata description) external returns (uint256)",
  "function payerFacture(uint256 id) external",
  "function estPayee(uint256 id) external view returns (bool)",
  "function getFacture(uint256 id) external view returns (tuple(address marchand, address client, uint256 montant, bool payee, uint256 dateCreation, string description))",
  "function getFacturesMarchand(address marchand) external view returns (uint256[] memory)",
  "function getFacturesClient(address client) external view returns (uint256[] memory)",
  "function getNombreFactures() external view returns (uint256)",
  "function factures(uint256) external view returns (address marchand, address client, uint256 montant, bool payee, uint256 dateCreation, string description)",
  "event FactureCreee(uint256 indexed id, address indexed marchand, address indexed client, uint256 montant, string description)",
  "event FacturePayee(uint256 indexed id, address indexed client, uint256 montant)"
];

// Validation des variables d'environnement
if (!CONTRACT_ADDRESS) {
  console.warn('⚠️ CONTRACT_ADDRESS non défini dans .env');
}

// Provider pour lire la blockchain
const provider = new ethers.JsonRpcProvider(RPC_URL);

// Wallet pour envoyer des transactions (optionnel)
const wallet = PRIVATE_KEY ? new ethers.Wallet(PRIVATE_KEY, provider) : null;

// Instance du contrat (lecture seule)
const contract = CONTRACT_ADDRESS ? new ethers.Contract(CONTRACT_ADDRESS, INVOICE_ABI, provider) : null;

// Instance du contrat avec wallet (pour écriture)
const contractWithSigner = (wallet && contract) ? contract.connect(wallet) : null;

/**
 * Vérifier la connexion au réseau
 */
async function checkConnection() {
  try {
    const network = await provider.getNetwork();
    const blockNumber = await provider.getBlockNumber();
    return {
      success: true,
      network: network.name,
      chainId: network.chainId.toString(),
      blockNumber,
      rpcUrl: RPC_URL
    };
  } catch (err) {
    console.error('Erreur connexion réseau:', err);
    throw new Error('Impossible de se connecter au réseau');
  }
}

/**
 * Créer une facture sur le smart contract
 */
async function createInvoiceOnChain(clientAddress, amount, description = '') {
  if (!contractWithSigner) {
    throw new Error('Wallet ou contrat non configuré pour les transactions');
  }
  
  try {
    // Validation des paramètres
    if (!ethers.isAddress(clientAddress)) {
      throw new Error('Adresse client invalide');
    }
    
    const amountWei = ethers.parseUnits(amount.toString(), 6); // USDC a 6 décimales
    
    console.log(`Création facture: client=${clientAddress}, montant=${amount} USDC, description="${description}"`);
    
    // Estimation du gas
    const gasEstimate = await contractWithSigner.creerFacture.estimateGas(
      clientAddress, 
      amountWei, 
      description
    );
    
    // Envoi de la transaction
    const tx = await contractWithSigner.creerFacture(
      clientAddress, 
      amountWei, 
      description,
      { gasLimit: gasEstimate * 120n / 100n } // +20% de marge
    );
    
    console.log(`Transaction envoyée: ${tx.hash}`);
    const receipt = await tx.wait();
    
    // Récupérer l'ID de la facture depuis les events
    const event = receipt.logs.find(log => {
      try {
        const parsed = contract.interface.parseLog(log);
        return parsed.name === 'FactureCreee';
      } catch {
        return false;
      }
    });
    
    const invoiceId = event ? contract.interface.parseLog(event).args[0] : null;
    
    return {
      success: true,
      txHash: tx.hash,
      invoiceId: invoiceId?.toString(),
      gasUsed: receipt.gasUsed.toString(),
      blockNumber: receipt.blockNumber
    };
  } catch (err) {
    console.error('Erreur création facture on-chain:', err);
    throw new Error(`Création facture échouée: ${err.message}`);
  }
}

/**
 * Vérifier le statut de paiement d'une facture
 */
async function getInvoiceStatus(invoiceId) {
  if (!contract) {
    throw new Error('Contrat non configuré');
  }
  
  try {
    const invoiceData = await contract.getFacture(invoiceId);
    
    return {
      id: invoiceId,
      merchant: invoiceData[0],
      client: invoiceData[1],
      amount: ethers.formatUnits(invoiceData[2], 6), // Convertir en USDC
      isPaid: invoiceData[3],
      creationDate: new Date(Number(invoiceData[4]) * 1000).toISOString(),
      description: invoiceData[5]
    };
  } catch (err) {
    console.error('Erreur lecture facture:', err);
    if (err.message.includes('Facture inexistante')) {
      throw new Error('Facture introuvable');
    }
    throw new Error(`Lecture facture échouée: ${err.message}`);
  }
}

/**
 * Récupérer toutes les factures d'un marchand
 */
async function getMerchantInvoices(merchantAddress) {
  if (!contract) {
    throw new Error('Contrat non configuré');
  }
  
  try {
    const invoiceIds = await contract.getFacturesMarchand(merchantAddress);
    const invoices = [];
    
    for (const id of invoiceIds) {
      try {
        const invoice = await getInvoiceStatus(id.toString());
        invoices.push(invoice);
      } catch (err) {
        console.warn(`Erreur lecture facture ${id}:`, err.message);
      }
    }
    
    return invoices;
  } catch (err) {
    console.error('Erreur lecture factures marchand:', err);
    throw new Error(`Lecture factures marchand échouée: ${err.message}`);
  }
}

/**
 * Obtenir toutes les factures d'un client
 */
async function getClientInvoices(clientAddress) {
  try {
    console.log(`📊 Récupération des factures pour le client: ${clientAddress}`);
    
    if (!contract) {
      throw new Error('Contrat non initialisé');
    }

    // Récupérer les IDs des factures du client
    const invoiceIds = await contract.getFacturesClient(clientAddress);
    console.log(`📄 ${invoiceIds.length} factures trouvées pour le client`);

    // Récupérer les détails de chaque facture
    const invoices = [];
    for (let i = 0; i < invoiceIds.length; i++) {
      try {
        const invoiceData = await contract.getFacture(invoiceIds[i]);
        invoices.push({
          id: invoiceIds[i].toString(),
          marchand: invoiceData.marchand,
          client: invoiceData.client,
          montant: invoiceData.montant.toString(),
          payee: invoiceData.payee,
          dateCreation: invoiceData.dateCreation.toString(),
          description: invoiceData.description
        });
      } catch (error) {
        console.warn(`⚠️ Erreur lors de la récupération de la facture ${invoiceIds[i]}:`, error.message);
      }
    }

    return invoices;
  } catch (error) {
    console.error('❌ Erreur lors de la récupération des factures client:', error);
    throw new Error(`Erreur récupération factures client: ${error.message}`);
  }
}

/**
 * Récupérer le nombre total de factures
 */
async function getTotalInvoiceCount() {
  if (!contract) {
    throw new Error('Contrat non configuré');
  }
  
  try {
    const count = await contract.getNombreFactures();
    return Number(count);
  } catch (err) {
    console.error('Erreur lecture nombre factures:', err);
    throw new Error(`Lecture nombre factures échouée: ${err.message}`);
  }
}

/**
 * Payer une facture on-chain
 */
async function payInvoiceOnChain(invoiceId) {
  try {
    console.log(`💳 Paiement de la facture ID: ${invoiceId}`);
    
    if (!contractWithSigner) {
      throw new Error('Wallet non configuré pour les transactions');
    }

    // Vérifier que la facture existe
    const invoiceData = await contract.getFacture(invoiceId);
    if (!invoiceData.marchand || invoiceData.marchand === ethers.ZeroAddress) {
      throw new Error('Facture inexistante');
    }

    // Vérifier que la facture n'est pas déjà payée
    if (invoiceData.payee) {
      throw new Error('Facture déjà payée');
    }

    console.log(`💰 Montant à payer: ${invoiceData.montant} USDC`);
    console.log(`👤 Paiement à: ${invoiceData.marchand}`);

    // Estimer les frais de gas
    const gasEstimate = await contractWithSigner.payerFacture.estimateGas(invoiceId);
    console.log(`⛽ Gas estimé: ${gasEstimate.toString()}`);

    // Exécuter la transaction de paiement
    const tx = await contractWithSigner.payerFacture(invoiceId, {
      gasLimit: gasEstimate * 120n / 100n // +20% de marge
    });

    console.log(`📤 Transaction envoyée: ${tx.hash}`);

    // Attendre la confirmation
    const receipt = await tx.wait();
    console.log(`✅ Transaction confirmée dans le bloc: ${receipt.blockNumber}`);

    // Rechercher l'événement FacturePayee
    const facturePayeeEvent = receipt.logs.find(log => {
      try {
        const parsed = contract.interface.parseLog(log);
        return parsed.name === 'FacturePayee';
      } catch {
        return false;
      }
    });

    const result = {
      success: true,
      transactionHash: tx.hash,
      blockNumber: receipt.blockNumber,
      gasUsed: receipt.gasUsed.toString()
    };

    if (facturePayeeEvent) {
      const parsed = contract.interface.parseLog(facturePayeeEvent);
      result.event = {
        invoiceId: parsed.args.id.toString(),
        client: parsed.args.client,
        montant: parsed.args.montant.toString()
      };
    }

    return result;
  } catch (error) {
    console.error('❌ Erreur lors du paiement:', error);
    
    // Messages d'erreur plus spécifiques
    if (error.message.includes('insufficient funds')) {
      throw new Error('Solde insuffisant pour payer les frais de transaction');
    } else if (error.message.includes('Allowance USDC insuffisante')) {
      throw new Error('Vous devez d\'abord approuver le contrat pour dépenser vos USDC');
    } else if (error.message.includes('Solde USDC insuffisant')) {
      throw new Error('Solde USDC insuffisant pour payer cette facture');
    } else if (error.message.includes('Seul le client peut payer')) {
      throw new Error('Seul le client peut payer cette facture');
    } else if (error.message.includes('Facture deja payee')) {
      throw new Error('Cette facture a déjà été payée');
    }
    
    throw new Error(`Erreur paiement facture: ${error.message}`);
  }
}

/**
 * Écouter les événements de création et paiement de factures
 */
function listenToInvoiceEvents(callback) {
  if (!contract) {
    console.warn('Contrat non configuré, impossible d\'écouter les événements');
    return;
  }
  
  // Écouter les créations de factures
  contract.on('FactureCreee', (id, merchant, client, amount, description, event) => {
    callback({
      type: 'created',
      invoiceId: id.toString(),
      merchant,
      client,
      amount: ethers.formatUnits(amount, 6),
      description,
      txHash: event.log.transactionHash,
      blockNumber: event.log.blockNumber
    });
  });
  
  // Écouter les paiements
  contract.on('FacturePayee', (id, client, amount, event) => {
    callback({
      type: 'paid',
      invoiceId: id.toString(),
      client,
      amount: ethers.formatUnits(amount, 6),
      txHash: event.log.transactionHash,
      blockNumber: event.log.blockNumber
    });
  });
  
  console.log('🎧 Écoute des événements de factures activée');
}

/**
 * Arrêter l'écoute des événements
 */
function stopListening() {
  if (contract) {
    contract.removeAllListeners();
    console.log('🛑 Écoute des événements arrêtée');
  }
}

module.exports = {
  checkConnection,
  createInvoiceOnChain,
  getInvoiceStatus,
  getMerchantInvoices,
  getClientInvoices,
  getTotalInvoiceCount,
  payInvoiceOnChain,
  listenToInvoiceEvents,
  stopListening,
  provider,
  contract,
  wallet
};
