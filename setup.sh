#!/bin/bash

# Script de configuration et déploiement pour l'application Facture USDC
# Ce script aide à configurer l'environnement de développement

echo "🚀 Configuration de l'application Facture USDC"
echo "=============================================="

# Couleurs pour les messages
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Fonction pour afficher les messages colorés
print_step() {
    echo -e "${BLUE}📋 $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Vérifier si Node.js est installé
print_step "Vérification de Node.js..."
if command -v node &> /dev/null; then
    NODE_VERSION=$(node --version)
    print_success "Node.js installé: $NODE_VERSION"
else
    print_error "Node.js n'est pas installé. Veuillez l'installer depuis https://nodejs.org/"
    exit 1
fi

# Vérifier si Flutter est installé
print_step "Vérification de Flutter..."
if command -v flutter &> /dev/null; then
    FLUTTER_VERSION=$(flutter --version | head -1)
    print_success "Flutter installé: $FLUTTER_VERSION"
else
    print_error "Flutter n'est pas installé. Veuillez l'installer depuis https://flutter.dev/"
    exit 1
fi

# Installation des dépendances du smart contract
print_step "Installation des dépendances du smart contract..."
cd contract
if [ -f "package.json" ]; then
    npm install
    if [ $? -eq 0 ]; then
        print_success "Dépendances du smart contract installées"
    else
        print_error "Erreur lors de l'installation des dépendances du smart contract"
        exit 1
    fi
else
    print_error "package.json non trouvé dans le dossier contract"
    exit 1
fi

# Compilation du smart contract
print_step "Compilation du smart contract..."
npm run compile
if [ $? -eq 0 ]; then
    print_success "Smart contract compilé avec succès"
else
    print_error "Erreur lors de la compilation du smart contract"
    exit 1
fi

cd ..

# Installation des dépendances du backend
print_step "Installation des dépendances du backend..."
cd lib/ApiBdd
if [ -f "package.json" ]; then
    npm install
    if [ $? -eq 0 ]; then
        print_success "Dépendances du backend installées"
    else
        print_error "Erreur lors de l'installation des dépendances du backend"
        exit 1
    fi
else
    print_error "package.json non trouvé dans le dossier lib/ApiBdd"
    exit 1
fi

cd ../..

# Configuration de l'environnement
print_step "Configuration de l'environnement..."
if [ ! -f "lib/ApiBdd/.env" ]; then
    if [ -f "lib/ApiBdd/.env.example" ]; then
        cp lib/ApiBdd/.env.example lib/ApiBdd/.env
        print_success "Fichier .env créé à partir de .env.example"
        print_warning "Veuillez éditer lib/ApiBdd/.env avec vos propres valeurs"
    else
        print_warning "Fichier .env.example non trouvé"
    fi
else
    print_success "Fichier .env déjà présent"
fi

# Installation des dépendances Flutter
print_step "Installation des dépendances Flutter..."
flutter pub get
if [ $? -eq 0 ]; then
    print_success "Dépendances Flutter installées"
else
    print_error "Erreur lors de l'installation des dépendances Flutter"
    exit 1
fi

echo ""
echo "🎉 Configuration terminée avec succès!"
echo ""
echo "📝 Prochaines étapes:"
echo "1. Éditez lib/ApiBdd/.env avec vos clés privées et adresses"
echo "2. Déployez le smart contract: cd contract && npm run deploy"
echo "3. Démarrez le backend: cd lib/ApiBdd && npm start"
echo "4. Démarrez l'app Flutter: flutter run"
echo ""
echo "📚 Documentation complète disponible dans README.md"
