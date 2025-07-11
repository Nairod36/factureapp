const express = require('express');
const router = express.Router();
const { db } = require('../database/sqlite');

// ==========================================
// CRUD FACTURES (BASE DE DONNÉES LOCALE)
// ==========================================

// GET - Récupérer toutes les factures
router.get('/', (req, res) => {
  const { status, limit, offset } = req.query;
  
  let sql = `SELECT * FROM invoices`;
  let params = [];
  
  if (status) {
    sql += ` WHERE status = ?`;
    params.push(status);
  }
  
  sql += ` ORDER BY created_at DESC`;
  
  if (limit) {
    sql += ` LIMIT ?`;
    params.push(parseInt(limit));
    
    if (offset) {
      sql += ` OFFSET ?`;
      params.push(parseInt(offset));
    }
  }
  
  db.all(sql, params, (err, rows) => {
    if (err) {
      console.error('Erreur récupération factures:', err);
      return res.status(500).json({ 
        error: 'Erreur lors de la récupération des factures',
        details: err.message 
      });
    }
    
    res.json({
      success: true,
      invoices: rows,
      count: rows.length
    });
  });
});

// GET - Récupérer une facture par ID
router.get('/:id', (req, res) => {
  const invoiceId = req.params.id;
  
  if (!invoiceId || isNaN(parseInt(invoiceId))) {
    return res.status(400).json({ 
      error: 'ID facture invalide' 
    });
  }
  
  const sql = `SELECT * FROM invoices WHERE id = ?`;
  
  db.get(sql, [invoiceId], (err, row) => {
    if (err) {
      console.error('Erreur récupération facture:', err);
      return res.status(500).json({ 
        error: 'Erreur lors de la récupération de la facture',
        details: err.message 
      });
    }
    
    if (!row) {
      return res.status(404).json({ 
        error: 'Facture non trouvée' 
      });
    }
    
    res.json({
      success: true,
      invoice: row
    });
  });
});

// GET - Récupérer les factures d'un marchand
router.get('/merchant/:address', (req, res) => {
  const merchantAddress = req.params.address;
  const { status, limit, offset } = req.query;
  
  if (!merchantAddress || !merchantAddress.match(/^0x[a-fA-F0-9]{40}$/)) {
    return res.status(400).json({ 
      error: 'Format d\'adresse marchand invalide' 
    });
  }
  
  let sql = `SELECT * FROM invoices WHERE merchant_address = ?`;
  let params = [merchantAddress];
  
  if (status) {
    sql += ` AND status = ?`;
    params.push(status);
  }
  
  sql += ` ORDER BY created_at DESC`;
  
  if (limit) {
    sql += ` LIMIT ?`;
    params.push(parseInt(limit));
    
    if (offset) {
      sql += ` OFFSET ?`;
      params.push(parseInt(offset));
    }
  }
  
  db.all(sql, params, (err, rows) => {
    if (err) {
      console.error('Erreur récupération factures marchand:', err);
      return res.status(500).json({ 
        error: 'Erreur lors de la récupération des factures',
        details: err.message 
      });
    }
    
    res.json({
      success: true,
      invoices: rows,
      count: rows.length
    });
  });
});

// GET - Récupérer les factures d'un client
router.get('/client/:address', (req, res) => {
  const clientAddress = req.params.address;
  const { status, limit, offset } = req.query;
  
  if (!clientAddress || !clientAddress.match(/^0x[a-fA-F0-9]{40}$/)) {
    return res.status(400).json({ 
      error: 'Format d\'adresse client invalide' 
    });
  }
  
  let sql = `SELECT * FROM invoices WHERE client_address = ?`;
  let params = [clientAddress];
  
  if (status) {
    sql += ` AND status = ?`;
    params.push(status);
  }
  
  sql += ` ORDER BY created_at DESC`;
  
  if (limit) {
    sql += ` LIMIT ?`;
    params.push(parseInt(limit));
    
    if (offset) {
      sql += ` OFFSET ?`;
      params.push(parseInt(offset));
    }
  }
  
  db.all(sql, params, (err, rows) => {
    if (err) {
      console.error('Erreur récupération factures client:', err);
      return res.status(500).json({ 
        error: 'Erreur lors de la récupération des factures',
        details: err.message 
      });
    }
    
    res.json({
      success: true,
      invoices: rows,
      count: rows.length
    });
  });
});

// POST - Créer une nouvelle facture
router.post('/', (req, res) => {
  const { merchant_address, client_address, description, amount, due_date, blockchain_invoice_id } = req.body;
  
  // Validation des champs obligatoires
  if (!merchant_address || !client_address || !description || !amount) {
    return res.status(400).json({ 
      error: 'Adresse marchand, adresse client, description et montant requis' 
    });
  }
  
  // Validation des adresses Ethereum
  if (!merchant_address.match(/^0x[a-fA-F0-9]{40}$/) || !client_address.match(/^0x[a-fA-F0-9]{40}$/)) {
    return res.status(400).json({ 
      error: 'Format d\'adresse Ethereum invalide' 
    });
  }
  
  // Validation du montant
  const numAmount = parseFloat(amount);
  if (isNaN(numAmount) || numAmount <= 0) {
    return res.status(400).json({ 
      error: 'Montant invalide' 
    });
  }
  
  const sql = `INSERT INTO invoices (merchant_address, client_address, description, amount, due_date, blockchain_invoice_id) VALUES (?, ?, ?, ?, ?, ?)`;
  
  db.run(sql, [merchant_address, client_address, description, numAmount, due_date, blockchain_invoice_id], function(err) {
    if (err) {
      console.error('Erreur création facture:', err);
      return res.status(500).json({ 
        error: 'Erreur lors de la création de la facture',
        details: err.message 
      });
    }
    
    res.status(201).json({
      success: true,
      invoice: {
        id: this.lastID,
        merchant_address,
        client_address,
        description,
        amount: numAmount,
        status: 'pending',
        due_date,
        blockchain_invoice_id
      },
      message: 'Facture créée avec succès'
    });
  });
});

// PUT - Mettre à jour une facture
router.put('/:id', (req, res) => {
  const invoiceId = req.params.id;
  const { status, transaction_hash, paid_at, due_date } = req.body;
  
  if (!invoiceId || isNaN(parseInt(invoiceId))) {
    return res.status(400).json({ 
      error: 'ID facture invalide' 
    });
  }
  
  // Construction de la requête de mise à jour dynamique
  let updates = [];
  let values = [];
  
  if (status) {
    updates.push('status = ?');
    values.push(status);
  }
  
  if (transaction_hash) {
    updates.push('transaction_hash = ?');
    values.push(transaction_hash);
  }
  
  if (paid_at !== undefined) {
    updates.push('paid_at = ?');
    values.push(paid_at);
  }
  
  if (due_date !== undefined) {
    updates.push('due_date = ?');
    values.push(due_date);
  }
  
  if (updates.length === 0) {
    return res.status(400).json({ 
      error: 'Aucun champ à mettre à jour' 
    });
  }
  
  updates.push('updated_at = CURRENT_TIMESTAMP');
  values.push(invoiceId);
  
  const sql = `UPDATE invoices SET ${updates.join(', ')} WHERE id = ?`;
  
  db.run(sql, values, function(err) {
    if (err) {
      console.error('Erreur mise à jour facture:', err);
      return res.status(500).json({ 
        error: 'Erreur lors de la mise à jour de la facture',
        details: err.message 
      });
    }
    
    if (this.changes === 0) {
      return res.status(404).json({ 
        error: 'Facture non trouvée' 
      });
    }
    
    res.json({
      success: true,
      message: 'Facture mise à jour avec succès'
    });
  });
});

// PUT - Marquer une facture comme payée
router.put('/:id/pay', (req, res) => {
  const invoiceId = req.params.id;
  
  if (!invoiceId) {
    return res.status(400).json({ 
      error: 'ID de facture requis' 
    });
  }
  
  // Vérifier que la facture existe
  db.get('SELECT * FROM invoices WHERE id = ?', [invoiceId], (err, invoice) => {
    if (err) {
      console.error('Erreur vérification facture:', err);
      return res.status(500).json({ 
        error: 'Erreur lors de la vérification de la facture',
        details: err.message 
      });
    }
    
    if (!invoice) {
      return res.status(404).json({ 
        error: 'Facture non trouvée' 
      });
    }
    
    if (invoice.status === 'paid') {
      return res.status(400).json({ 
        error: 'Cette facture est déjà payée' 
      });
    }
    
    // Marquer la facture comme payée
    const sql = `
      UPDATE invoices 
      SET 
        status = 'paid',
        updated_at = datetime('now'),
        paid_at = datetime('now')
      WHERE id = ?
    `;
    
    db.run(sql, [invoiceId], function(err) {
      if (err) {
        console.error('Erreur paiement facture:', err);
        return res.status(500).json({ 
          error: 'Erreur lors du paiement de la facture',
          details: err.message 
        });
      }
      
      if (this.changes === 0) {
        return res.status(404).json({ 
          error: 'Facture non trouvée' 
        });
      }
      
      // Récupérer la facture mise à jour
      db.get('SELECT * FROM invoices WHERE id = ?', [invoiceId], (err, updatedInvoice) => {
        if (err) {
          console.error('Erreur récupération facture mise à jour:', err);
          return res.status(500).json({ 
            error: 'Facture payée mais erreur de récupération',
            details: err.message 
          });
        }
        
        res.json({
          success: true,
          message: 'Facture marquée comme payée',
          invoice: updatedInvoice
        });
      });
    });
  });
});

// GET - Statistiques des factures
router.get('/stats/overview', (req, res) => {
  const { merchant_address, client_address } = req.query;
  
  let whereClauses = [];
  let params = [];
  
  if (merchant_address) {
    whereClauses.push('merchant_address = ?');
    params.push(merchant_address);
  }
  
  if (client_address) {
    whereClauses.push('client_address = ?');
    params.push(client_address);
  }
  
  const whereClause = whereClauses.length > 0 ? `WHERE ${whereClauses.join(' AND ')}` : '';
  
  const sql = `
    SELECT 
      COUNT(*) as total_invoices,
      COUNT(CASE WHEN status = 'pending' THEN 1 END) as pending_invoices,
      COUNT(CASE WHEN status = 'paid' THEN 1 END) as paid_invoices,
      COUNT(CASE WHEN status = 'cancelled' THEN 1 END) as cancelled_invoices,
      COALESCE(SUM(amount), 0) as total_amount,
      COALESCE(SUM(CASE WHEN status = 'paid' THEN amount ELSE 0 END), 0) as paid_amount,
      COALESCE(SUM(CASE WHEN status = 'pending' THEN amount ELSE 0 END), 0) as pending_amount
    FROM invoices 
    ${whereClause}
  `;
  
  db.get(sql, params, (err, row) => {
    if (err) {
      console.error('Erreur statistiques factures:', err);
      return res.status(500).json({ 
        error: 'Erreur lors de la récupération des statistiques',
        details: err.message 
      });
    }
    
    res.json({
      success: true,
      stats: row
    });
  });
});

module.exports = router;
