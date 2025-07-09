# Facture USDC - Architecture Flutter Moderne

## 📱 Structure de l'application

L'application Flutter a été complètement restructurée pour utiliser une architecture moderne avec 8 écrans complets :

### 🔐 1. AuthScreen (`/lib/screens/auth_screen.dart`)
- **Fonction** : Écran d'authentification et de connexion de portefeuille
- **Caractéristiques** :
  - Interface de connexion avec champ d'adresse Ethereum
  - Validation de l'adresse de portefeuille
  - Navigation automatique vers l'écran d'accueil après connexion
  - Design moderne avec animations et feedback utilisateur

### 🏠 2. HomeScreen (`/lib/screens/home_screen.dart`)
- **Fonction** : Tableau de bord principal avec statistiques et navigation
- **Caractéristiques** :
  - Statistiques en temps réel des factures
  - Cartes de navigation vers toutes les fonctionnalités
  - Profil utilisateur avec adresse de portefeuille
  - Accès rapide aux actions principales

### ➕ 3. CreateInvoiceScreen (`/lib/screens/create_invoice_screen.dart`)
- **Fonction** : Création de nouvelles factures
- **Caractéristiques** :
  - Formulaire complet avec validation
  - Intégration avec l'API backend
  - Feedback visuel (succès/erreur)
  - Réinitialisation automatique du formulaire

### 📋 4. InvoiceListScreen (`/lib/screens/invoice_list_screen.dart`)
- **Fonction** : Liste des factures (émises ou reçues)
- **Caractéristiques** :
  - Affichage différencié pour marchands et clients
  - Filtres par statut (toutes/payées/en attente)
  - Navigation vers les détails de facture
  - Indicateurs visuels de statut
  - Pull-to-refresh

### 📄 5. InvoiceDetailScreen (`/lib/screens/invoice_detail_screen.dart`)
- **Fonction** : Détails complets d'une facture
- **Caractéristiques** :
  - Affichage complet des informations
  - Actions contextuelles (payer/annuler)
  - Formatage des adresses Ethereum
  - Statut visuel avec icônes et couleurs

### 💳 6. PayInvoiceScreen (`/lib/screens/pay_invoice_screen.dart`)
- **Fonction** : Paiement d'une facture spécifique
- **Caractéristiques** :
  - Résumé détaillé de la facture
  - Informations de paiement
  - Intégration avec l'API de paiement
  - Feedback de progression

### 🔍 7. PayInvoiceSearchScreen (`/lib/screens/pay_invoice_search_screen.dart`)
- **Fonction** : Recherche et paiement par ID de facture
- **Caractéristiques** :
  - Recherche par ID de facture
  - Validation des factures impayées
  - Guide d'utilisation intégré
  - Transition automatique vers l'écran de paiement

### 👤 8. ProfileScreen (`/lib/screens/profile_screen.dart`)
- **Fonction** : Profil utilisateur et paramètres
- **Caractéristiques** :
  - Informations de profil avec adresse de portefeuille
  - Statistiques détaillées des factures
  - Paramètres d'application
  - Option de déconnexion

### 📊 9. TransactionHistoryScreen (`/lib/screens/transaction_history_screen.dart`)
- **Fonction** : Historique des transactions
- **Caractéristiques** :
  - Filtres par type (toutes/reçues/envoyées)
  - Formatage des montants et dates
  - Détails des transactions
  - Interface segmentée

## 🏗️ Architecture technique

### Navigation
- **Système** : Navigation basée sur `Navigator.push()` avec arguments
- **Généreateur de routes** : `onGenerateRoute` dans `main.dart`
- **Passage de paramètres** : Arguments typés entre écrans

### Configuration
- **Fichier central** : `/lib/services/app_config.dart`
- **Variables d'environnement** : Configuration API centralisée
- **Formatage** : Fonctions utilitaires pour adresses et montants

### Intégration API
- **HTTP Client** : Package `http` pour les requêtes
- **Endpoints** : Integration complète avec l'API backend
- **Gestion d'erreurs** : Feedback utilisateur avec messages d'erreur

## 🔧 Fonctionnalités implémentées

### ✅ Créer une facture
- Formulaire complet avec validation
- Intégration avec smart contract
- Feedback visuel de succès/erreur

### ✅ Lister les factures
- Vue marchant et client
- Filtres par statut
- Pull-to-refresh

### ✅ Détails de facture
- Informations complètes
- Actions contextuelles
- Formatage des données

### ✅ Paiement de facture
- Recherche par ID
- Confirmation de paiement
- Intégration blockchain

### ✅ Profil utilisateur
- Statistiques personnelles
- Paramètres d'application
- Gestion de session

### ✅ Historique des transactions
- Filtres avancés
- Détails des paiements
- Interface intuitive

## 📱 Design System

### Couleurs
- **Primaire** : Bleu (`Colors.blue`)
- **Succès** : Vert (`Colors.green`)
- **Erreur** : Rouge (`Colors.red`)
- **Attention** : Orange (`Colors.orange`)

### Composants
- **Cards** : Conteneurs pour les informations
- **Buttons** : Styles cohérents pour les actions
- **Icons** : Iconographie claire et contextuelle
- **Typography** : Hiérarchie visuelle bien définie

### Responsive Design
- **Adaptabilité** : Interface adaptée aux différentes tailles d'écran
- **Scrolling** : Gestion du défilement pour le contenu long
- **Touch** : Zones de touch optimisées

## 🔌 Intégration Backend

### Endpoints utilisés
- `GET /api/invoices/count` - Statistiques générales
- `GET /api/invoices/merchant/{address}` - Factures émises
- `GET /api/invoices/client/{address}` - Factures reçues
- `GET /api/invoices/status/{id}` - Détails d'une facture
- `POST /api/invoice/create` - Création de facture
- `POST /api/invoices/pay` - Paiement de facture

### Gestion des erreurs
- **Codes HTTP** : Gestion appropriée des codes de réponse
- **Messages d'erreur** : Feedback utilisateur informatif
- **Retry logic** : Possibilité de réessayer les requêtes

## 🚀 Prochaines améliorations

### Fonctionnalités avancées
- [ ] Scan QR code pour payer
- [ ] Export PDF des factures
- [ ] Notifications push
- [ ] Mode sombre
- [ ] Multi-langues
- [ ] Wallet Connect intégration

### Optimisations
- [ ] Cache des données
- [ ] Offline mode
- [ ] Amélioration des performances
- [ ] Tests unitaires et d'intégration

### UX/UI
- [ ] Animations avancées
- [ ] Skeleton loading
- [ ] Amélioration de l'accessibilité
- [ ] Feedback haptique

## 📝 Utilisation

1. **Démarrer l'application** : L'écran d'authentification s'affiche
2. **Se connecter** : Entrer une adresse Ethereum valide
3. **Naviguer** : Utiliser le tableau de bord pour accéder aux fonctionnalités
4. **Créer une facture** : Remplir le formulaire et soumettre
5. **Payer une facture** : Rechercher par ID et confirmer le paiement
6. **Consulter l'historique** : Voir toutes les transactions passées

Cette architecture moderne offre une expérience utilisateur fluide et intuitive tout en maintenant une structure de code maintenable et évolutive.
