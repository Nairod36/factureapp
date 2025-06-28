# Backend API - Facture USDC

Ce backend Express.js fournit une API REST pour :
- Authentification (inscription, connexion, JWT)
- Gestion des factures (CRUD)
- Stockage SQLite (par défaut, simple à déployer)

## Lancer le serveur

```bash
npm install
npm start
```

## Endpoints principaux
- POST `/register` : inscription utilisateur
- POST `/login` : connexion utilisateur (retourne un JWT)
- GET `/invoices?user_email=...` : liste des factures d’un commerçant
- POST `/invoices` : créer une facture
- GET `/invoices/:id` : détail d’une facture
- PUT `/invoices/:id` : modifier une facture
- DELETE `/invoices/:id` : supprimer une facture

## Sécurité
- Toutes les routes factures nécessitent un JWT (header `Authorization: Bearer <token>`)

## Configuration
- Variables d’environnement dans `.env` (clé secrète JWT, chemin BDD, etc.)

---

Ce backend est prêt à être connecté à l’app Flutter du dossier parent.
