const express = require('express');
const router = express.Router();
const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const { db } = require('../database/sqlite');
const { createCctpMessage, getCctpMessageStatus } = require('../../contract/cctp_circle_service');

const JWT_SECRET = process.env.JWT_SECRET || 'changeme';

// REGISTER
router.post('/register', (req, res) => {
  const { email, password } = req.body;
  if (!email || !password) return res.status(400).json({ error: 'Email et mot de passe requis' });
  const hash = bcrypt.hashSync(password, 10);
  db.run('INSERT INTO users (email, password) VALUES (?, ?)', [email, hash], function(err) {
    if (err) {
      console.error('Erreur inscription:', err);
      if (err.code === 'SQLITE_CONSTRAINT') {
        return res.status(409).json({ error: 'Email déjà utilisé' });
      }
      return res.status(500).json({ error: 'Erreur serveur' });
    }
    res.json({ success: true });
  });
});

// LOGIN
router.post('/login', (req, res) => {
  const { email, password } = req.body;
  db.get('SELECT * FROM users WHERE email = ?', [email], (err, user) => {
    if (err) return res.status(500).json({ error: 'Erreur serveur' });
    if (!user) return res.status(401).json({ error: 'Identifiants invalides' });
    if (!bcrypt.compareSync(password, user.password)) return res.status(401).json({ error: 'Identifiants invalides' });
    const token = jwt.sign({ email: user.email }, JWT_SECRET, { expiresIn: '7d' });
    res.json({ token });
  });
});

// MIDDLEWARE JWT
function requireAuth(req, res, next) {
  const auth = req.headers.authorization;
  if (!auth || !auth.startsWith('Bearer ')) return res.status(401).json({ error: 'Token manquant' });
  try {
    req.user = jwt.verify(auth.split(' ')[1], JWT_SECRET);
    next();
  } catch {
    res.status(401).json({ error: 'Token invalide' });
  }
}

// GET ALL INVOICES FOR USER
router.get('/invoices', requireAuth, (req, res) => {
  const { user_email } = req.query;
  db.all('SELECT * FROM invoices WHERE user_email = ?', [user_email], (err, rows) => {
    if (err) return res.status(500).json({ error: 'Erreur BDD' });
    res.json(rows);
  });
});

// CREATE INVOICE
router.post('/invoices', requireAuth, (req, res) => {
  const { user_email, client_email, description, amount, gasless } = req.body;
  db.run('INSERT INTO invoices (user_email, client_email, description, amount, gasless) VALUES (?, ?, ?, ?, ?)',
    [user_email, client_email, description, amount, gasless ? 1 : 0],
    function(err) {
      if (err) return res.status(500).json({ error: 'Erreur BDD' });
      res.json({ id: this.lastID });
    });
});

// GET ONE INVOICE
router.get('/invoices/:id', requireAuth, (req, res) => {
  db.get('SELECT * FROM invoices WHERE id = ?', [req.params.id], (err, row) => {
    if (err || !row) return res.status(404).json({ error: 'Facture introuvable' });
    res.json(row);
  });
});

// UPDATE INVOICE
router.put('/invoices/:id', requireAuth, (req, res) => {
  const { description, amount, gasless } = req.body;
  db.run('UPDATE invoices SET description = ?, amount = ?, gasless = ? WHERE id = ?',
    [description, amount, gasless ? 1 : 0, req.params.id],
    function(err) {
      if (err) return res.status(500).json({ error: 'Erreur BDD' });
      res.json({ success: true });
    });
});

// DELETE INVOICE
router.delete('/invoices/:id', requireAuth, (req, res) => {
  db.run('DELETE FROM invoices WHERE id = ?', [req.params.id], function(err) {
    if (err) return res.status(500).json({ error: 'Erreur BDD' });
    res.json({ success: true });
  });
});

// Route pour initier un transfert CCTP (Circle Cross-Chain) avec support gasless
router.post('/cctp', async (req, res) => {
  const { amount, fromChain, toChain, toAddress, partner, gasless } = req.body;
  try {
    const result = await createCctpMessage({ amount, fromChain, toChain, toAddress, partner, gasless });
    res.json(result); // Contient messageId, unsignedVaas, etc.
  } catch (err) {
    res.status(500).json({ error: 'Erreur Circle CCTP', details: err.message });
  }
});

// Route pour vérifier le statut d'un message CCTP
router.get('/cctp/:messageId', async (req, res) => {
  try {
    const result = await getCctpMessageStatus(req.params.messageId);
    res.json(result);
  } catch (err) {
    res.status(500).json({ error: 'Erreur statut CCTP', details: err.message });
  }
});

module.exports = router;
