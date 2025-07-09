const express = require('express');
const router = express.Router();
const { createInvoiceOnChain, getInvoiceStatus, getMerchantInvoices, getClientInvoices, payInvoiceOnChain, getTotalInvoiceCount, checkConnection } = require('../web3_service');

// ==========================================
// ROUTES SMART CONTRACT POUR FACTURES USDC
// ==========================================

// Test de connexion blockchain
router.get('/health', async (req, res) => {
  try {
    const isConnected = await checkConnection();
    res.json({ 
      status: 'ok', 
      blockchain: isConnected,
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    res.status(500).json({ 
      status: 'error', 
      blockchain: false,
      error: error.message 
    });
  }
});

// Créer une facture on-chain
router.post('/invoice/create', async (req, res) => {
  try {
    const { client, montant, description } = req.body;
    
    // Validation des entrées
    if (!client || !montant || !description) {
      return res.status(400).json({ 
        error: 'Paramètres manquants: client, montant et description requis' 
      });
    }

    // Validation du format d'adresse Ethereum
    if (!client.match(/^0x[a-fA-F0-9]{40}$/)) {
      return res.status(400).json({ 
        error: 'Format d\'adresse client invalide' 
      });
    }

    // Validation du montant
    const amount = parseFloat(montant);
    if (isNaN(amount) || amount <= 0) {
      return res.status(400).json({ 
        error: 'Montant invalide' 
      });
    }

    console.log(`📝 Création facture: client=${client}, montant=${montant}, description=${description}`);
    
    const result = await createInvoiceOnChain(client, montant, description);
    res.json({
      success: true,
      invoiceId: result.invoiceId,
      transactionHash: result.transactionHash,
      message: 'Facture créée avec succès'
    });
    
  } catch (error) {
    console.error('Erreur création facture:', error);
    res.status(500).json({ 
      error: 'Erreur lors de la création de la facture',
      details: error.message 
    });
  }
});

// Obtenir le statut d'une facture
router.get('/invoice/status/:id', async (req, res) => {
  try {
    const invoiceId = req.params.id;
    
    // Validation de l'ID
    if (!invoiceId || isNaN(parseInt(invoiceId))) {
      return res.status(400).json({ 
        error: 'ID de facture invalide' 
      });
    }

    console.log(`📋 Consultation facture ID: ${invoiceId}`);
    
    const invoice = await getInvoiceStatus(invoiceId);
    res.json({
      success: true,
      invoice: invoice
    });
    
  } catch (error) {
    console.error('Erreur consultation facture:', error);
    if (error.message.includes('Facture inexistante')) {
      res.status(404).json({ 
        error: 'Facture non trouvée',
        details: error.message 
      });
    } else {
      res.status(500).json({ 
        error: 'Erreur lors de la consultation de la facture',
        details: error.message 
      });
    }
  }
});

// Obtenir toutes les factures d'un marchand
router.get('/invoice/merchant/:address', async (req, res) => {
  try {
    const merchantAddress = req.params.address;
    
    // Validation de l'adresse
    if (!merchantAddress.match(/^0x[a-fA-F0-9]{40}$/)) {
      return res.status(400).json({ 
        error: 'Format d\'adresse marchand invalide' 
      });
    }

    console.log(`📊 Liste factures marchand: ${merchantAddress}`);
    
    const invoices = await getMerchantInvoices(merchantAddress);
    res.json({
      success: true,
      invoices: invoices,
      count: invoices.length
    });
    
  } catch (error) {
    console.error('Erreur liste factures marchand:', error);
    res.status(500).json({ 
      error: 'Erreur lors de la récupération des factures',
      details: error.message 
    });
  }
});

// Obtenir toutes les factures d'un client
router.get('/invoice/client/:address', async (req, res) => {
  try {
    const clientAddress = req.params.address;
    
    // Validation de l'adresse
    if (!clientAddress.match(/^0x[a-fA-F0-9]{40}$/)) {
      return res.status(400).json({ 
        error: 'Format d\'adresse client invalide' 
      });
    }

    console.log(`📊 Liste factures client: ${clientAddress}`);
    
    const invoices = await getClientInvoices(clientAddress);
    res.json({
      success: true,
      invoices: invoices,
      count: invoices.length
    });
    
  } catch (error) {
    console.error('Erreur liste factures client:', error);
    res.status(500).json({ 
      error: 'Erreur lors de la récupération des factures',
      details: error.message 
    });
  }
});

// Payer une facture
router.post('/invoice/pay', async (req, res) => {
  try {
    const { invoiceId } = req.body;
    
    // Validation de l'ID
    if (!invoiceId || isNaN(parseInt(invoiceId))) {
      return res.status(400).json({ 
        error: 'ID de facture invalide' 
      });
    }

    console.log(`💳 Paiement facture ID: ${invoiceId}`);
    
    const result = await payInvoiceOnChain(invoiceId);
    res.json({
      success: true,
      transactionHash: result.transactionHash,
      message: 'Paiement initié avec succès'
    });
    
  } catch (error) {
    console.error('Erreur paiement facture:', error);
    res.status(500).json({ 
      error: 'Erreur lors du paiement de la facture',
      details: error.message 
    });
  }
});

// Obtenir le nombre total de factures
router.get('/invoice/count', async (req, res) => {
  try {
    console.log('📊 Consultation nombre total de factures');
    
    const count = await getTotalInvoiceCount();
    res.json({
      success: true,
      totalInvoices: count
    });
    
  } catch (error) {
    console.error('Erreur comptage factures:', error);
    res.status(500).json({ 
      error: 'Erreur lors du comptage des factures',
      details: error.message 
    });
  }
});

module.exports = router;
