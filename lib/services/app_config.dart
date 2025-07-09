import 'package:flutter/material.dart';

class AppConfig {
  // Configuration API
  static const String apiBaseUrl = 'http://localhost:3000';
  
  // Configuration Reown AppKit
  static const String projectId = 'your-project-id-here'; // À remplacer par votre projet ID
  static const String appDescription = 'Application de facturation USDC';
  static const String appUrl = 'https://factureapp.com';
  static const List<String> appIcons = ['https://factureapp.com/icon.png'];
  
  // Configuration utilisateur (à adapter selon l'authentification)
  static String userAddress = '0x742d35Cc6635C0532925a3b8D56c9E6eA22D9c08';
  static String? userName;
  static bool isAuthenticated = false;
  
  // Configuration réseau
  static const String networkName = 'Sepolia Testnet';
  static const String networkRpcUrl = 'https://rpc.ankr.com/eth_sepolia';
  static const String usdcAddress = '0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238';
  
  // Thème et couleurs
  static const Color primaryColor = Colors.blue;
  static const Color accentColor = Colors.blueAccent;
  static const Color successColor = Colors.green;
  static const Color errorColor = Colors.red;
  static const Color warningColor = Colors.orange;
  
  // Configuration des montants
  static const double minInvoiceAmount = 0.01;
  static const double maxInvoiceAmount = 1000000;
  
  // Messages
  static const String appName = 'Facture USDC';
  static const String appVersion = '2.0.0';
  static const String supportEmail = 'support@factureusdc.com';
  
  // Méthodes utilitaires
  static void setUserAddress(String address) {
    userAddress = address;
  }
  
  static void setAuthenticated(bool auth) {
    isAuthenticated = auth;
  }
  
  static void setUserName(String? name) {
    userName = name;
  }
  
  // Validation d'adresse Ethereum
  static bool isValidEthereumAddress(String address) {
    return RegExp(r'^0x[a-fA-F0-9]{40}$').hasMatch(address);
  }
  
  // Formatage des montants
  static String formatAmount(dynamic amount) {
    if (amount == null) return '0';
    double value = double.tryParse(amount.toString()) ?? 0;
    return value.toStringAsFixed(2);
  }
  
  // Formatage des adresses (raccourcies)
  static String formatAddress(String address) {
    if (address.length < 10) return address;
    return '${address.substring(0, 6)}...${address.substring(address.length - 4)}';
  }
  
  // Messages d'erreur standardisés
  static const Map<String, String> errorMessages = {
    'network_error': 'Erreur de connexion réseau',
    'invalid_address': 'Adresse Ethereum invalide',
    'invalid_amount': 'Montant invalide',
    'insufficient_balance': 'Solde insuffisant',
    'transaction_failed': 'Transaction échouée',
    'invoice_not_found': 'Facture non trouvée',
    'unauthorized': 'Accès non autorisé',
  };
  
  static String getErrorMessage(String key) {
    return errorMessages[key] ?? 'Erreur inconnue';
  }
}
