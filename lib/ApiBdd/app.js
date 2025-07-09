require('dotenv').config();
const express = require('express');
const cors = require('cors');
const morgan = require('morgan');

// Import des routes
const apiRouter = require('./routes/api');

const app = express();

// Middleware
app.use(cors({
  origin: ['http://localhost:3000', 'http://127.0.0.1:3000'], // Autoriser Flutter
  credentials: true
}));
app.use(morgan('combined')); // Logs détaillés
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));

// Routes principales
app.use('/api', apiRouter);

// Route de test
app.get('/', (req, res) => {
  res.json({ 
    message: 'API Facture USDC - Smart Contract',
    version: '2.0.0',
    timestamp: new Date().toISOString(),
    endpoints: {
      health: 'GET /api/health',
      createInvoice: 'POST /api/invoice/create',
      getInvoiceStatus: 'GET /api/invoice/status/:id',
      getMerchantInvoices: 'GET /api/invoice/merchant/:address',
      getClientInvoices: 'GET /api/invoice/client/:address',
      payInvoice: 'POST /api/invoice/pay',
      getTotalCount: 'GET /api/invoice/count'
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
