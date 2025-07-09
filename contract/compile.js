// Script de compilation du contrat Invoice
// Génère l'ABI et le bytecode nécessaires au déploiement

const fs = require('fs');
const path = require('path');
const solc = require('solc');

function compileContract() {
  try {
    console.log('🔨 Compilation du contrat Invoice.sol...');
    
    // Lire le fichier source
    const contractPath = path.join(__dirname, 'Invoice.sol');
    const source = fs.readFileSync(contractPath, 'utf8');
    
    // Configuration de compilation
    const input = {
      language: 'Solidity',
      sources: {
        'Invoice.sol': {
          content: source
        }
      },
      settings: {
        outputSelection: {
          '*': {
            '*': ['abi', 'evm.bytecode.object']
          }
        },
        optimizer: {
          enabled: true,
          runs: 200
        }
      }
    };
    
    // Compiler
    const output = JSON.parse(solc.compile(JSON.stringify(input)));
    
    if (output.errors) {
      const hasErrors = output.errors.some(error => error.severity === 'error');
      if (hasErrors) {
        console.error('❌ Erreurs de compilation:');
        output.errors.forEach(error => {
          if (error.severity === 'error') {
            console.error(`  - ${error.formattedMessage}`);
          }
        });
        process.exit(1);
      } else {
        console.log('⚠️ Avertissements:');
        output.errors.forEach(error => {
          console.log(`  - ${error.formattedMessage}`);
        });
      }
    }
    
    const contract = output.contracts['Invoice.sol']['Invoice'];
    const abi = contract.abi;
    const bytecode = '0x' + contract.evm.bytecode.object;
    
    // Sauvegarder l'ABI
    const abiPath = path.join(__dirname, 'abi.json');
    fs.writeFileSync(abiPath, JSON.stringify(abi, null, 2));
    
    // Sauvegarder le bytecode
    const bytecodePath = path.join(__dirname, 'bytecode.txt');
    fs.writeFileSync(bytecodePath, bytecode);
    
    // Créer un fichier d'artifacts complet
    const artifacts = {
      contractName: 'Invoice',
      abi: abi,
      bytecode: bytecode,
      compiledAt: new Date().toISOString()
    };
    
    const artifactsPath = path.join(__dirname, 'artifacts.json');
    fs.writeFileSync(artifactsPath, JSON.stringify(artifacts, null, 2));
    
    console.log('✅ Compilation terminée avec succès!');
    console.log(`📁 ABI sauvegardée: ${abiPath}`);
    console.log(`📁 Bytecode sauvegardé: ${bytecodePath}`);
    console.log(`📁 Artifacts complets: ${artifactsPath}`);
    
    return { abi, bytecode };
    
  } catch (error) {
    console.error('❌ Erreur de compilation:', error);
    process.exit(1);
  }
}

// Exécuter la compilation si le script est appelé directement
if (require.main === module) {
  compileContract();
}

module.exports = { compileContract };
