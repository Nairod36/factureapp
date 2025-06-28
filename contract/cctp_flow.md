# Flux CCTP (Circle Cross-Chain Transfer Protocol)

## Objets principaux

### 1. Message CCTP
- Représente la demande de transfert cross-chain USDC.
- Paramètres :
  - `amount` (en unités sans décimales, ex : 1 USDC = 1000000)
  - `fromChain` (ex : ETH, AVAX, POLYGON…)
  - `toChain` (ex : ETH, AVAX, POLYGON…)
  - `toAddress` (adresse du bénéficiaire sur la chaîne cible)
  - `partner` (identifiant marchand)

### 2. unsignedVaas
- Attestation renvoyée par Circle pour prouver l’autorisation du transfert.
- Doit être signée et soumise on-chain pour déclencher le burn des USDC.

### 3. Statut du message
- Endpoint Circle pour consulter l’état du message (pending, executed, confirmed…)
- Après burn exécuté, Circle mint automatiquement sur la chaîne cible.

---

## Séquence d’un paiement cross-chain USDC

1. **Création du message**
   - POST `https://iris-api-sandbox.circle.com/v2/messages`
   - Body : `{ amount, fromChain, toChain, toAddress, partner }`
   - Header : `Authorization: Bearer <CIRCLE_API_KEY>`
   - Réponse : `{ messageId, unsignedVaas }`

2. **Envoi de la transaction burn**
   - Option 1 : backend signe et soumet l’`unsignedVaas` via ethers.js/web3.js
   - Option 2 : mobile/wallet signe et soumet (WalletConnect, etc.)

3. **Monitoring du statut**
   - GET `/v2/messages/{messageId}`
   - Statuts : `PENDING`, `EXECUTED`, `COMPLETED`…
   - Quand `EXECUTED`, Circle procède au mint sur la chaîne cible.

4. **Finalisation**
   - Quand statut `COMPLETED`, paiement confirmé.
   - Mettre à jour la BDD, notifier l’utilisateur.

---

## Points clés
- **Sandbox** : utiliser `iris-api-sandbox.circle.com` pour les tests.
- **Sécurité** : ne jamais exposer la clé API côté client.
- **Décimales USDC** : 1 USDC = 1000000 (6 décimales).
- **Chaînes supportées** : vérifier la doc officielle CCTP.
- **Fiabilité** : prévoir des retries et/ou webhooks pour le suivi des statuts.

---

> Pour un exemple de code Node.js (création de message, monitoring, etc.), demande-le !
