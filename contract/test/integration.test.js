// Test d'intégration pour vérifier l'interaction complète
// Backend ↔ Smart Contract ↔ Frontend

const { expect } = require('chai');
const { ethers } = require('ethers');
const http = require('http');
const { createApp } = require('../../lib/ApiBdd/server'); // À adapter selon votre structure
require('dotenv').config();

describe('Tests d\'intégration Facture USDC', function() {
  this.timeout(30000); // Timeout long pour les transactions blockchain
  
  let app, server;
  let provider, wallet, contract;
  let invoiceId;
  
  const API_BASE_URL = 'http://localhost:3001'; // Port de test différent
  const TEST_CLIENT_ADDRESS = '0x742d35Cc6635C0532925a3b8D56c9E6eA22D9c08';
  const TEST_AMOUNT = '100';
  const TEST_DESCRIPTION = 'Test facture d\'intégration';
  
  before(async function() {
    console.log('🔧 Configuration des tests d\'intégration...');
    
    // Démarrer le serveur de test
    app = createApp();
    server = app.listen(3001);
    
    // Connexion à la blockchain
    provider = new ethers.JsonRpcProvider(process.env.RPC_URL);
    wallet = new ethers.Wallet(process.env.PRIVATE_KEY, provider);
    
    // Charger le contrat déployé
    const artifacts = require('../artifacts.json');
    contract = new ethers.Contract(
      process.env.CONTRACT_ADDRESS,
      artifacts.abi,
      wallet
    );
    
    console.log('✅ Configuration terminée');
  });
  
  after(function() {
    if (server) {
      server.close();
    }
  });
  
  describe('Flux complet de facturation', function() {
    
    it('devrait créer une facture via l\'API', function(done) {
      const postData = JSON.stringify({
        client: TEST_CLIENT_ADDRESS,
        montant: TEST_AMOUNT,
        description: TEST_DESCRIPTION
      });
      
      const options = {
        hostname: 'localhost',
        port: 3001,
        path: '/api/invoice/create',
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Content-Length': Buffer.byteLength(postData)
        }
      };
      
      const req = http.request(options, (res) => {
        let data = '';
        
        res.on('data', (chunk) => {
          data += chunk;
        });
        
        res.on('end', () => {
          try {
            const response = JSON.parse(data);
            expect(res.statusCode).to.equal(200);
            expect(response).to.have.property('invoiceId');
            invoiceId = response.invoiceId;
            console.log(`📄 Facture créée avec ID: ${invoiceId}`);
            done();
          } catch (error) {
            done(error);
          }
        });
      });
      
      req.on('error', done);
      req.write(postData);
      req.end();
    });
    
    it('devrait récupérer les détails de la facture', function(done) {
      const options = {
        hostname: 'localhost',
        port: 3001,
        path: `/api/invoice/status/${invoiceId}`,
        method: 'GET'
      };
      
      const req = http.request(options, (res) => {
        let data = '';
        
        res.on('data', (chunk) => {
          data += chunk;
        });
        
        res.on('end', () => {
          try {
            const response = JSON.parse(data);
            expect(res.statusCode).to.equal(200);
            expect(response).to.have.property('invoice');
            
            const invoice = response.invoice;
            expect(invoice.client).to.equal(TEST_CLIENT_ADDRESS);
            expect(invoice.montant).to.equal(TEST_AMOUNT);
            expect(invoice.description).to.equal(TEST_DESCRIPTION);
            expect(invoice.payee).to.be.false;
            
            console.log('📋 Détails de la facture vérifiés');
            done();
          } catch (error) {
            done(error);
          }
        });
      });
      
      req.on('error', done);
      req.end();
    });
    
    it('devrait lister les factures du marchand', function(done) {
      const options = {
        hostname: 'localhost',
        port: 3001,
        path: `/api/invoice/merchant/${wallet.address}`,
        method: 'GET'
      };
      
      const req = http.request(options, (res) => {
        let data = '';
        
        res.on('data', (chunk) => {
          data += chunk;
        });
        
        res.on('end', () => {
          try {
            const response = JSON.parse(data);
            expect(res.statusCode).to.equal(200);
            expect(response).to.have.property('invoices');
            expect(response.invoices).to.be.an('array');
            expect(response.invoices.length).to.be.greaterThan(0);
            
            // Vérifier que notre facture est dans la liste
            const ourInvoice = response.invoices.find(inv => inv.id == invoiceId);
            expect(ourInvoice).to.not.be.undefined;
            
            console.log(`📋 Liste des factures récupérée (${response.invoices.length} factures)`);
            done();
          } catch (error) {
            done(error);
          }
        });
      });
      
      req.on('error', done);
      req.end();
    });
    
    it('devrait vérifier que la facture existe sur la blockchain', async function() {
      try {
        const invoiceData = await contract.getFacture(invoiceId);
        
        expect(invoiceData.marchand).to.equal(wallet.address);
        expect(invoiceData.client).to.equal(TEST_CLIENT_ADDRESS);
        expect(invoiceData.montant.toString()).to.equal(TEST_AMOUNT);
        expect(invoiceData.description).to.equal(TEST_DESCRIPTION);
        expect(invoiceData.payee).to.be.false;
        
        console.log('⛓️ Facture vérifiée sur la blockchain');
      } catch (error) {
        throw new Error(`Erreur lors de la vérification blockchain: ${error.message}`);
      }
    });
    
    it('devrait gérer les erreurs pour une facture inexistante', function(done) {
      const options = {
        hostname: 'localhost',
        port: 3001,
        path: '/api/invoice/status/99999',
        method: 'GET'
      };
      
      const req = http.request(options, (res) => {
        let data = '';
        
        res.on('data', (chunk) => {
          data += chunk;
        });
        
        res.on('end', () => {
          try {
            expect(res.statusCode).to.equal(404);
            const response = JSON.parse(data);
            expect(response).to.have.property('error');
            
            console.log('🚫 Gestion d\'erreur vérifiée');
            done();
          } catch (error) {
            done(error);
          }
        });
      });
      
      req.on('error', done);
      req.end();
    });
    
  });
  
  describe('Tests de robustesse', function() {
    
    it('devrait rejeter une facture avec des données invalides', function(done) {
      const postData = JSON.stringify({
        client: 'adresse_invalide',
        montant: '-100',
        description: ''
      });
      
      const options = {
        hostname: 'localhost',
        port: 3001,
        path: '/api/invoice/create',
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Content-Length': Buffer.byteLength(postData)
        }
      };
      
      const req = http.request(options, (res) => {
        expect(res.statusCode).to.equal(400);
        console.log('🛡️ Validation des données vérifiée');
        done();
      });
      
      req.on('error', done);
      req.write(postData);
      req.end();
    });
    
  });
  
});
