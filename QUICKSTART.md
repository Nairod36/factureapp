# 🚀 Guide de Démarrage Rapide - Facture USDC

Ce guide vous permet de démarrer rapidement avec l'application Facture USDC.

## ⚡ Installation Automatique

### 1. Configuration Rapide

```bash
# Cloner et configurer automatiquement
./setup.sh
```

Ce script va :
- ✅ Vérifier Node.js et Flutter
- ✅ Installer toutes les dépendances
- ✅ Compiler le smart contract
- ✅ Créer le fichier .env

### 2. Configuration Manuelle (si nécessaire)

Éditez `lib/ApiBdd/.env` avec vos valeurs :

```bash
# Configuration blockchain
RPC_URL=https://rpc.ankr.com/eth_sepolia
PRIVATE_KEY=0xvotre_clé_privée
CONTRACT_ADDRESS=0xadresse_du_contrat_deployé

# Configuration USDC (Sepolia Testnet)
USDC_ADDRESS=0xA0b86a33E6417d69e83e5B5F4E4B4b0e

# Configuration serveur
PORT=3000
NODE_ENV=development
```

## 🚀 Démarrage

### 1. Déployer le Smart Contract

```bash
cd contract
npm run deploy
# Copiez l'adresse du contrat dans .env
```

### 2. Démarrer le Backend

```bash
cd lib/ApiBdd
npm start
```

### 3. Démarrer l'App Flutter

```bash
flutter run
```

## 📱 Utilisation de l'App

### Interface Utilisateur

L'app Flutter contient 3 onglets :

1. **Créer** - Créer une nouvelle facture
2. **Mes factures** - Voir les factures émises
3. **Payer** - Payer une facture existante

### Fonctionnalités

- ✅ Création de factures on-chain
- ✅ Consultation des factures
- ✅ Paiement en USDC
- ✅ Suivi en temps réel
- ✅ Interface intuitive

## 🧪 Tests

### Tests Unitaires

```bash
cd contract
npm test
```

### Tests d'Intégration

```bash
cd contract
npm run test:integration
```

### Tests Flutter

```bash
flutter test
```

## 🔧 Développement

### Structure du Projet

```
factureapp/
├── contract/           # Smart contracts
│   ├── Invoice.sol
│   ├── deploy/
│   └── test/
├── lib/
│   ├── ApiBdd/        # Backend Node.js
│   ├── widgets/       # Widgets Flutter
│   └── main.dart      # App Flutter
└── setup.sh           # Configuration automatique
```

### Scripts Disponibles

```bash
# Smart Contract
cd contract
npm run compile        # Compiler le contrat
npm run deploy         # Déployer sur le réseau
npm run test          # Tests unitaires
npm run deploy:sepolia # Déployer sur Sepolia
npm run deploy:polygon # Déployer sur Polygon

# Backend
cd lib/ApiBdd
npm start             # Démarrer le serveur
npm run dev           # Mode développement

# Flutter
flutter run           # Démarrer l'app
flutter build apk     # Build Android
flutter build ios     # Build iOS
```

## 🌐 Réseaux Supportés

### Testnet (Recommandé pour débuter)
- **Sepolia** : RPC inclus
- **Mumbai** : `https://rpc-mumbai.maticvigil.com`

### Mainnet
- **Ethereum** : `https://mainnet.infura.io/v3/YOUR_KEY`
- **Polygon** : `https://polygon-rpc.com`

## 💰 Obtenir des Tokens de Test

### USDC Testnet (Sepolia)
1. Aller sur https://faucet.circle.com/
2. Demander des USDC de test
3. Utiliser l'adresse dans l'app

### ETH Testnet (pour les frais de gas)
1. Aller sur https://sepoliafaucet.com/
2. Demander des ETH de test

## 🔒 Sécurité

### ⚠️ Important

- **Jamais** de clés privées mainnet dans le code
- Utilisez des variables d'environnement
- Testez toujours sur testnet d'abord
- Vérifiez les montants avant paiement

### Configuration Sécurisée

```bash
# .env
PRIVATE_KEY=0x...  # ⚠️ Gardez secret !
RPC_URL=...       # ✅ Peut être public
```

## 🆘 Dépannage

### Problèmes Courants

**1. Erreur de compilation du contrat**
```bash
cd contract
npm install solc@0.8.20
npm run compile
```

**2. Erreur de connexion blockchain**
- Vérifiez votre RPC_URL
- Vérifiez votre solde ETH pour les frais

**3. Erreur Flutter**
```bash
flutter clean
flutter pub get
flutter run
```

**4. Erreur Backend**
```bash
cd lib/ApiBdd
npm install
npm start
```

## 📚 Ressources

- [Documentation Solidity](https://docs.soliditylang.org/)
- [Guide Ethers.js](https://docs.ethers.org/)
- [Documentation Flutter](https://flutter.dev/docs)
- [Circle USDC](https://www.centre.io/usdc)

## 🤝 Support

- Consultez les logs pour les erreurs détaillées
- Vérifiez que tous les services sont démarrés
- Testez avec de petits montants d'abord

---

✨ **Votre app Facture USDC est prête !** ✨
