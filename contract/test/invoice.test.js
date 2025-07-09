// Tests unitaires pour le contrat Invoice
// Nécessite : npm install mocha chai ethers

const { expect } = require('chai');
const { ethers } = require('ethers');

describe('Invoice Contract', function () {
  let invoiceContract;
  let usdcMock;
  let owner, client;
  
  beforeEach(async function () {
    [owner, client] = await ethers.getSigners();
    
    // Déployer un mock USDC pour les tests
    const ERC20Mock = await ethers.getContractFactory('ERC20Mock');
    usdcMock = await ERC20Mock.deploy('USDC Mock', 'USDC', 6);
    
    // Déployer le contrat Invoice
    const Invoice = await ethers.getContractFactory('Invoice');
    invoiceContract = await Invoice.deploy(await usdcMock.getAddress());
  });
  
  describe('Création de factures', function () {
    it('devrait créer une facture correctement', async function () {
      const amount = ethers.parseUnits('100', 6); // 100 USDC
      
      const tx = await invoiceContract.creerFacture(client.address, amount);
      const receipt = await tx.wait();
      
      // Vérifier l'événement
      const event = receipt.logs.find(log => log.fragment?.name === 'FactureCreee');
      expect(event).to.not.be.undefined;
      expect(event.args[1]).to.equal(owner.address); // marchand
      expect(event.args[2]).to.equal(client.address); // client
      expect(event.args[3]).to.equal(amount); // montant
      
      // Vérifier les données de la facture
      const invoice = await invoiceContract.factures(1);
      expect(invoice[0]).to.equal(owner.address); // marchand
      expect(invoice[1]).to.equal(client.address); // client
      expect(invoice[2]).to.equal(amount); // montant
      expect(invoice[3]).to.be.false; // non payée
    });
  });
  
  describe('Paiement de factures', function () {
    beforeEach(async function () {
      // Créer une facture
      const amount = ethers.parseUnits('100', 6);
      await invoiceContract.creerFacture(client.address, amount);
      
      // Donner des USDC au client
      await usdcMock.mint(client.address, amount);
      await usdcMock.connect(client).approve(await invoiceContract.getAddress(), amount);
    });
    
    it('devrait permettre le paiement d\'une facture', async function () {
      const tx = await invoiceContract.connect(client).payerFacture(1);
      const receipt = await tx.wait();
      
      // Vérifier l'événement
      const event = receipt.logs.find(log => log.fragment?.name === 'FacturePayee');
      expect(event).to.not.be.undefined;
      expect(event.args[0]).to.equal(1); // ID de la facture
      expect(event.args[1]).to.equal(client.address); // client
      
      // Vérifier que la facture est marquée comme payée
      const isPaid = await invoiceContract.estPayee(1);
      expect(isPaid).to.be.true;
    });
    
    it('devrait rejeter le paiement d\'une facture déjà payée', async function () {
      await invoiceContract.connect(client).payerFacture(1);
      
      await expect(
        invoiceContract.connect(client).payerFacture(1)
      ).to.be.revertedWith('Deja payee');
    });
    
    it('devrait rejeter le paiement par une autre personne que le client', async function () {
      await expect(
        invoiceContract.connect(owner).payerFacture(1)
      ).to.be.revertedWith('Seul le client peut payer');
    });
  });
});
