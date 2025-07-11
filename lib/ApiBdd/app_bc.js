require('dotenv').config();
const express = require('express');
const cors = require('cors');
const morgan = require('morgan');

// Import des routes
const apiRouter = require('./routes/api');
const usersRouter = require('./routes/users');
const invoicesRouter = require('./routes/invoices');

// Import et initialisation de la base de données
const { initDb } = require('./database/sqlite');

const app = express();

// Initialisation de la base de données
initDb();

// Middleware
app.use(cors({
  origin: [
    'http://localhost:3000', 
    'http://127.0.0.1:3000', 
    'http://localhost:8080',
    'http://localhost:56778',  // Port Flutter web
    'http://127.0.0.1:56778',
    'http://localhost',
    /^http:\/\/localhost:\d+$/,  // Tous les ports localhost
    /^http:\/\/127\.0\.0\.1:\d+$/  // Tous les ports 127.0.0.1
  ],
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization'],
  optionsSuccessStatus: 200
}));

app.use(morgan('combined')); // Logs détaillés
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));

// Routes principales
app.use('/api', apiRouter);
app.use('/api/users', usersRouter);
app.use('/api/invoices', invoicesRouter);

// Route de test
app.get('/', (req, res) => {
  res.json({ 
    message: 'API Facture USDC - Smart Contract + Database',
    version: '3.0.0',
    timestamp: new Date().toISOString(),
    endpoints: {
      // Blockchain endpoints
      health: 'GET /api/health',
      createInvoice: 'POST /api/invoice/create',
      getInvoiceStatus: 'GET /api/invoice/status/:id',
      getMerchantInvoices: 'GET /api/invoice/merchant/:address',
      getClientInvoices: 'GET /api/invoice/client/:address',
      payInvoice: 'POST /api/invoice/pay',
      getTotalCount: 'GET /api/invoice/count',
      
      // Database endpoints
      users: {
        getAll: 'GET /api/users',
        getById: 'GET /api/users/:id',
        getByAddress: 'GET /api/users/address/:address',
        create: 'POST /api/users',
        update: 'PUT /api/users/:id',
        delete: 'DELETE /api/users/:id',
        auth: 'POST /api/users/auth'
      },
      invoices: {
        getAll: 'GET /api/invoices',
        getById: 'GET /api/invoices/:id',
        getByMerchant: 'GET /api/invoices/merchant/:address',
        getByClient: 'GET /api/invoices/client/:address',
        create: 'POST /api/invoices',
        update: 'PUT /api/invoices/:id',
        delete: 'DELETE /api/invoices/:id',
        stats: 'GET /api/invoices/stats/overview'
      }
    }
  });
});

// Gestion des erreurs 404
app.use((req, res) => {
  res.status(404).json({ 
    error: 'Route non trouvée',
    path: req.path,
    method: req.method 
  });
});

// Gestion des erreurs générales
app.use((err, req, res, next) => {
  console.error('Erreur serveur:', err);
  res.status(500).json({ 
    error: 'Erreur interne du serveur',
    details: process.env.NODE_ENV === 'development' ? err.message : undefined
  });
});

// Démarrage du serveur
const PORT = process.env.PORT || 3000;
const server = app.listen(PORT, () => {
  console.log(`🚀 Serveur API Facture USDC démarré sur le port ${PORT}`);
  console.log(`📍 URL: http://localhost:${PORT}`);
  console.log(`🔗 Testez avec: http://localhost:${PORT}/api/health`);
});

// Gestion gracieuse de l'arrêt
process.on('SIGTERM', () => {
  console.log('🛑 Signal SIGTERM reçu, arrêt du serveur...');
  server.close(() => {
    console.log('✅ Serveur arrêté proprement');
  });
});

module.exports = app;
