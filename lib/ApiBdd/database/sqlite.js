const sqlite3 = require('sqlite3').verbose();
const path = require('path');
const dbPath = process.env.DB_PATH || path.join(__dirname, 'factureapp.db');

const db = new sqlite3.Database(dbPath);

// Création des tables si elles n'existent pas
function initDb() {
  db.serialize(() => {
    // Table des utilisateurs avec adresse Ethereum
    db.run(`CREATE TABLE IF NOT EXISTS users (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      email TEXT UNIQUE NOT NULL,
      password TEXT NOT NULL,
      ethereum_address TEXT UNIQUE,
      first_name TEXT,
      last_name TEXT,
      phone TEXT,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
      updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
    )`);
    
    // Table des factures améliorée
    db.run(`CREATE TABLE IF NOT EXISTS invoices (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      merchant_address TEXT NOT NULL,
      client_address TEXT NOT NULL,
      description TEXT NOT NULL,
      amount DECIMAL(10,2) NOT NULL,
      status TEXT DEFAULT 'pending',
      transaction_hash TEXT,
      blockchain_invoice_id INTEGER,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
      updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
      due_date DATETIME,
      paid_at DATETIME
    )`);
    
    // Index pour les performances
    db.run(`CREATE INDEX IF NOT EXISTS idx_invoices_merchant ON invoices(merchant_address)`);
    db.run(`CREATE INDEX IF NOT EXISTS idx_invoices_client ON invoices(client_address)`);
    db.run(`CREATE INDEX IF NOT EXISTS idx_invoices_status ON invoices(status)`);
    db.run(`CREATE INDEX IF NOT EXISTS idx_users_ethereum ON users(ethereum_address)`);
  });
}

module.exports = { db, initDb };
