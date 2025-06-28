// Exemple d'appel API Circle pour créer un paiement USDC
// Voir https://developers.circle.com/docs pour plus de détails

const axios = require('axios');

const CIRCLE_API_KEY = process.env.CIRCLE_API_KEY || 'VOTRE_CLE_API_CIRCLE';
const BASE_URL = 'https://api.circle.com/v1';

async function createPayment(amount, currency, recipientWallet) {
  try {
    const res = await axios.post(
      `${BASE_URL}/payments`,
      {
        amount: { amount: amount.toString(), currency },
        destination: { address: recipientWallet, chain: 'ETH' },
        description: 'Paiement facture USDC',
        metadata: { invoiceId: '1234' }
      },
      {
        headers: {
          'Authorization': `Bearer ${CIRCLE_API_KEY}`,
          'Content-Type': 'application/json'
        }
      }
    );
    console.log('Paiement Circle créé:', res.data);
    return res.data;
  } catch (err) {
    console.error('Erreur API Circle:', err.response?.data || err.message);
    throw err;
  }
}

// Exemple d'utilisation
// createPayment(10, 'USDC', '0x...').then(console.log).catch(console.error);

module.exports = { createPayment };
