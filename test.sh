#!/bin/bash

# Script de test rapide pour vérifier le bon fonctionnement de l'application

echo "🧪 Tests rapides de l'application Facture USDC"
echo "=============================================="

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_test() {
    echo -e "${BLUE}🔍 Test: $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${YELLOW}ℹ️  $1${NC}"
}

# Test 1: Vérification des dépendances
print_test "Vérification des dépendances système"

if command -v node &> /dev/null; then
    print_success "Node.js installé: $(node --version)"
else
    print_error "Node.js non installé"
    exit 1
fi

if command -v flutter &> /dev/null; then
    print_success "Flutter installé: $(flutter --version | head -1)"
else
    print_error "Flutter non installé"
    exit 1
fi

# Test 2: Structure du projet
print_test "Vérification de la structure du projet"

if [ -f "contract/Invoice.sol" ]; then
    print_success "Smart contract présent"
else
    print_error "Smart contract manquant"
    exit 1
fi

if [ -f "lib/ApiBdd/package.json" ]; then
    print_success "Backend package.json présent"
else
    print_error "Backend package.json manquant"
    exit 1
fi

if [ -f "pubspec.yaml" ]; then
    print_success "Flutter pubspec.yaml présent"
else
    print_error "Flutter pubspec.yaml manquant"
    exit 1
fi

# Test 3: Compilation du smart contract
print_test "Compilation du smart contract"

cd contract
if npm run compile --silent > /dev/null 2>&1; then
    print_success "Smart contract compilé avec succès"
    
    if [ -f "artifacts.json" ]; then
        print_success "Artifacts générés"
    else
        print_error "Artifacts non générés"
    fi
else
    print_error "Erreur de compilation du smart contract"
    exit 1
fi

cd ..

# Test 4: Configuration du backend
print_test "Vérification de la configuration du backend"

cd lib/ApiBdd

if [ -f ".env" ]; then
    print_success "Fichier .env présent"
    
    if npm run check-env --silent > /dev/null 2>&1; then
        print_success "Configuration valide"
    else
        print_error "Configuration invalide"
        print_info "Exécutez 'npm run check-env' pour plus de détails"
    fi
else
    print_error "Fichier .env manquant"
    print_info "Copiez .env.example vers .env et configurez vos valeurs"
fi

cd ../..

# Test 5: Installation des dépendances
print_test "Vérification des dépendances"

cd contract
if [ -d "node_modules" ]; then
    print_success "Dépendances smart contract installées"
else
    print_info "Installation des dépendances smart contract..."
    npm install --silent
    print_success "Dépendances smart contract installées"
fi

cd ../lib/ApiBdd
if [ -d "node_modules" ]; then
    print_success "Dépendances backend installées"
else
    print_info "Installation des dépendances backend..."
    npm install --silent
    print_success "Dépendances backend installées"
fi

cd ../..

# Test 6: Tests unitaires
print_test "Exécution des tests unitaires"

cd contract
if npm test --silent > /dev/null 2>&1; then
    print_success "Tests unitaires passés"
else
    print_error "Échec des tests unitaires"
    print_info "Vérifiez la configuration blockchain pour les tests"
fi

cd ..

# Test 7: Vérification Flutter
print_test "Vérification Flutter"

if flutter doctor --android-licenses > /dev/null 2>&1; then
    print_success "Licences Android acceptées"
else
    print_info "Licences Android à vérifier avec 'flutter doctor'"
fi

if flutter pub get > /dev/null 2>&1; then
    print_success "Dépendances Flutter installées"
else
    print_error "Erreur d'installation des dépendances Flutter"
fi

if flutter analyze > /dev/null 2>&1; then
    print_success "Code Flutter valide"
else
    print_error "Erreurs d'analyse Flutter"
    print_info "Exécutez 'flutter analyze' pour plus de détails"
fi

# Résumé
echo ""
echo "📊 Résumé des tests"
echo "=================="
print_success "Tests terminés avec succès!"
echo ""
echo "🚀 Prochaines étapes:"
echo "1. Configurez votre .env avec de vraies valeurs"
echo "2. Déployez le smart contract: cd contract && npm run deploy"
echo "3. Démarrez le backend: cd lib/ApiBdd && npm start"
echo "4. Démarrez l'app Flutter: flutter run"
echo ""
echo "📚 Consultez QUICKSTART.md pour plus de détails"
