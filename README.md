# Facture USDC – Application Flutter & API Node.js (Circle CCTP)

<p align="center">
  <img src="https://raw.githubusercontent.com/CircleFin/brand-assets/main/circle-logo.svg" alt="Circle" width="120"/>
  <br><br>
  <img src="https://img.shields.io/badge/Flutter-Ready-blue?logo=flutter"/>
  <img src="https://img.shields.io/badge/Node.js-API-green?logo=node.js"/>
  <img src="https://img.shields.io/badge/Circle-CCTP-blueviolet?logo=circle"/>
  <img src="https://img.shields.io/badge/SQLite-DB-lightgrey?logo=sqlite"/>
</p>

---

**Facture USDC** est une solution complète pour commerçants permettant de générer, visualiser et envoyer des factures USDC multichain, avec gestion d’utilisateurs, QR code, stockage sécurisé, UX professionnelle, et intégration Circle (CCTP, gasless à venir).

---

## Aperçu visuel

<p align="center">
  <img src="https://user-images.githubusercontent.com/2514172/29242013-7e2e2e7e-7f7e-11e7-8c3e-6b7b8e6b7b8e.png" alt="Aperçu Flutter" width="350"/>
  <img src="https://user-images.githubusercontent.com/2514172/29242014-7e2e2e7e-7f7e-11e7-8c3e-6b7b8e6b7b8e.png" alt="Aperçu QR" width="350"/>
</p>

---

## Fonctionnalités principales
- Authentification sécurisée (JWT, API Node.js, SQLite)
- Création, visualisation et envoi de factures USDC (mobile/web)
- Génération de QR code pour paiement crypto
- Envoi de factures par email
- Intégration Circle CCTP (transfert cross-chain USDC, monitoring, unsignedVaas)
- Prêt pour l’intégration gasless (Circle Paymaster)
- Responsive, UX pro, navigation fluide

---

## Architecture

```mermaid
flowchart TD
    subgraph Frontend[Flutter]
      A[Login/Register] --> B[HomePage]
      B --> C[Créer Facture]
      B --> D[Liste Factures]
      C --> E[QR Code]
      D --> F[Détail Facture]
    end
    subgraph Backend[Node.js/Express]
      G[API REST]
      H[SQLite DB]
      I[Circle CCTP Service]
      G --> H
      G --> I
    end
    A <--> G
```

---

## Installation & Lancement

### 1. Backend Node.js
```bash
cd lib/ApiBdd
npm install
# Créez un fichier .env avec :
# CIRCLE_API_KEY=VOTRE_CLE_SANDBOX
node app.js
```
- Serveur sur `http://localhost:3000`
- Variables d’environnement :
  - `CIRCLE_API_KEY` (obligatoire pour Circle CCTP)
  - `PORT` (optionnel, défaut 3000)

### 2. Frontend Flutter
```bash
flutter pub get
flutter run -d chrome # ou -d ios/android selon la plateforme
```
- Modifiez l’URL API dans `main.dart` si besoin (pour mobile, utilisez l’IP du backend)

---

## API REST principale

| Méthode | Endpoint | Description |
|---------|----------|-------------|
| POST    | /api/register | Crée un utilisateur |
| POST    | /api/login    | Authentifie et retourne un JWT |
| GET     | /api/invoices?user_email=... | Liste les factures |
| POST    | /api/invoices | Crée une facture |
| GET     | /api/invoices/:id | Détail d’une facture |
| PUT     | /api/invoices/:id | Modifie une facture |
| DELETE  | /api/invoices/:id | Supprime une facture |
| POST    | /api/cctp | Crée un message CCTP (Circle) |
| GET     | /api/cctp/:messageId | Statut du transfert CCTP |

---

## Intégration Circle CCTP
- Voir `/contract/cctp_circle_service.js` pour le service Node.js
- Voir `/contract/cctp_flow.md` pour la doc complète du flux CCTP
- Utilisez la sandbox Circle pour tous les tests
- Ne jamais exposer la clé API côté client

---

## Structure du dossier `contract/`
- `Invoice.sol` : exemple de smart contract de facturation USDC (optionnel)
- `cctp_circle_service.js` : service Node.js pour Circle CCTP
- `cctp_flow.md` : documentation flux CCTP
- `deploy/`, `test/` : scripts de déploiement/tests (à compléter)

---

## Sécurité & bonnes pratiques
- Stockez la clé API Circle dans `.env` (jamais dans le code)
- Utilisez HTTPS en production
- Testez d’abord en sandbox
- Protégez toutes les routes sensibles par JWT

---

## Roadmap / TODO
- Ajout du paiement gasless (Circle Paymaster)
- Export PDF/partage QR code
- Webhooks Circle pour monitoring automatique
- UI/UX avancée (dark mode, notifications…)
- Déploiement cloud (Heroku, Vercel, etc.)

---

## Liens utiles
- [Doc Circle CCTP](https://developers.circle.com/docs/cctp)
- [Flutter](https://flutter.dev/)
- [Node.js](https://nodejs.org/)

---

**Licence MIT**

---

> Pour toute question ou contribution, ouvrez une issue ou une pull request sur ce repo !
