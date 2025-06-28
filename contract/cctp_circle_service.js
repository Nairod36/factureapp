// Service Node.js pour gérer le flux CCTP Circle (sandbox)
// Nécessite : npm install axios dotenv

const axios = require('axios');
require('dotenv').config();

const CIRCLE_API_KEY = process.env.CIRCLE_API_KEY || 'VOTRE_CLE_API_CIRCLE';
const BASE_URL = 'https://iris-api-sandbox.circle.com/v2';

/**
 * 1. Création du message CCTP (cross-chain USDC)
 */
async function createCctpMessage({ amount, fromChain, toChain, toAddress, partner, gasless }) {
  try {
    const body = {
      amount: amount.toString(), // ex: 1000000 pour 1 USDC
      fromChain,
      toChain,
      toAddress,
      partner
    };
    // Si gasless, ajoute le paramètre paymaster selon la doc Circle
    if (gasless) {
      body.paymaster = true; // ou selon la doc officielle (ex: paymaster: { type: 'circle' })
    }
    const res = await axios.post(
      `${BASE_URL}/messages`,
      body,
      {
        headers: {
          'Authorization': `Bearer ${CIRCLE_API_KEY}`,
          'Content-Type': 'application/json'
        }
      }
    );
    return res.data;
  } catch (err) {
    console.error('Erreur création message CCTP:', err.response?.data || err.message);
    throw err;
  }
}

/**
 * 2. Monitoring du statut d'un message (burn/mint)
 */
async function getCctpMessageStatus(messageId) {
  try {
    const res = await axios.get(
      `${BASE_URL}/messages/${messageId}`,
      {
        headers: {
          'Authorization': `Bearer ${CIRCLE_API_KEY}`
        }
      }
    );
    return res.data;
  } catch (err) {
    console.error('Erreur statut message CCTP:', err.response?.data || err.message);
    throw err;
  }
}

// 3. (Optionnel) Envoi de l'unsignedVaas à signer et soumettre on-chain :
// - Utiliser ethers.js côté backend OU
// - Transférer à l'app mobile pour signature WalletConnect

module.exports = { createCctpMessage, getCctpMessageStatus };
