// Script de vérification de l'environnement
// Vérifie que toutes les variables d'environnement nécessaires sont configurées

const fs = require('fs');
const path = require('path');

console.log('🔍 Vérification de l\'environnement...');
console.log('================================');

// Variables d'environnement requises
const requiredEnvVars = [
  'RPC_URL',
  'PRIVATE_KEY', 
  'CONTRACT_ADDRESS',
  'USDC_ADDRESS'
];

// Variables optionnelles avec valeurs par défaut
const optionalEnvVars = {
  'PORT': '3000',
  'NODE_ENV': 'development'
};

let allOk = true;
let warnings = [];

// Vérifier si le fichier .env existe
const envPath = path.join(__dirname, '.env');
if (!fs.existsSync(envPath)) {
  console.log('❌ Fichier .env manquant');
  console.log('   Copiez .env.example vers .env et configurez vos valeurs');
  process.exit(1);
}

// Charger les variables d'environnement
require('dotenv').config();

console.log('📋 Variables d\'environnement requises:');
console.log('=====================================');

// Vérifier les variables requises
requiredEnvVars.forEach(varName => {
  const value = process.env[varName];
  if (!value) {
    console.log(`❌ ${varName}: MANQUANT`);
    allOk = false;
  } else {
    // Masquer les clés privées dans l'affichage
    const displayValue = varName === 'PRIVATE_KEY' 
      ? `${value.substring(0, 10)}...${value.substring(value.length - 4)}` 
      : value;
    console.log(`✅ ${varName}: ${displayValue}`);
  }
});

console.log('\n📋 Variables d\'environnement optionnelles:');
console.log('==========================================');

// Vérifier les variables optionnelles
Object.entries(optionalEnvVars).forEach(([varName, defaultValue]) => {
  const value = process.env[varName] || defaultValue;
  const isDefault = !process.env[varName];
  
  if (isDefault) {
    warnings.push(`${varName} utilise la valeur par défaut: ${defaultValue}`);
  }
  
  console.log(`${isDefault ? '⚠️' : '✅'} ${varName}: ${value}${isDefault ? ' (défaut)' : ''}`);
});

// Vérifications supplémentaires
console.log('\n🔍 Vérifications supplémentaires:');
console.log('=================================');

// Vérifier le format de la clé privée
const privateKey = process.env.PRIVATE_KEY;
if (privateKey) {
  if (!privateKey.startsWith('0x') || privateKey.length !== 66) {
    console.log('❌ Format de PRIVATE_KEY invalide (doit commencer par 0x et faire 66 caractères)');
    allOk = false;
  } else {
    console.log('✅ Format de PRIVATE_KEY valide');
  }
}

// Vérifier le format des adresses
const contractAddress = process.env.CONTRACT_ADDRESS;
const usdcAddress = process.env.USDC_ADDRESS;

[
  { name: 'CONTRACT_ADDRESS', value: contractAddress },
  { name: 'USDC_ADDRESS', value: usdcAddress }
].forEach(({ name, value }) => {
  if (value) {
    if (!value.startsWith('0x') || value.length !== 42) {
      console.log(`❌ Format de ${name} invalide (doit commencer par 0x et faire 42 caractères)`);
      allOk = false;
    } else {
      console.log(`✅ Format de ${name} valide`);
    }
  }
});

// Vérifier l'URL RPC
const rpcUrl = process.env.RPC_URL;
if (rpcUrl) {
  if (!rpcUrl.startsWith('http://') && !rpcUrl.startsWith('https://')) {
    console.log('❌ Format de RPC_URL invalide (doit commencer par http:// ou https://)');
    allOk = false;
  } else {
    console.log('✅ Format de RPC_URL valide');
  }
}

// Vérifier les fichiers nécessaires
console.log('\n📁 Fichiers requis:');
console.log('==================');

const requiredFiles = [
  '../../contract/artifacts.json',
  '../../contract/Invoice.sol',
  './routes/api.js',
  './web3_service.js'
];

requiredFiles.forEach(filePath => {
  const fullPath = path.join(__dirname, filePath);
  if (fs.existsSync(fullPath)) {
    console.log(`✅ ${filePath}`);
  } else {
    console.log(`❌ ${filePath} MANQUANT`);
    allOk = false;
  }
});

// Résumé final
console.log('\n📊 Résumé:');
console.log('=========');

if (warnings.length > 0) {
  console.log('⚠️  Avertissements:');
  warnings.forEach(warning => console.log(`   - ${warning}`));
  console.log('');
}

if (allOk) {
  console.log('🎉 Environnement configuré correctement!');
  console.log('   Vous pouvez maintenant démarrer l\'application.');
  process.exit(0);
} else {
  console.log('❌ Configuration incomplète');
  console.log('   Veuillez corriger les erreurs ci-dessus avant de continuer.');
  process.exit(1);
}
