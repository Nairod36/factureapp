import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'wallet_connect_interface.dart';

/// Service de développement qui simule WalletConnect
/// À utiliser uniquement pendant le développement
class WalletConnectMockService extends WalletConnectServiceInterface {
  // Configuration
  static const String appName = 'Facture USDC';
  static const String chainId = 'eip155:11155111';
  static const String networkName = 'Sepolia';
  
  String? _currentAddress;
  String? _connectionUri;
  bool _isLoading = false;
  bool _isInitialized = false;
  bool _isConnected = false;
  
  // Getters
  @override
  bool get isConnected => _isConnected && _currentAddress != null;
  @override
  bool get isConnecting => _isLoading;
  @override
  String? get currentAddress => _currentAddress;
  @override
  String? get connectionUri => _connectionUri;
  @override
  bool get isInitialized => _isInitialized;
  
  // Initialisation du service mock
  @override
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      debugPrint('Initialisation du service WalletConnect Mock...');
      
      // Charger une session sauvegardée s'il y en a une
      await _loadSavedSession();
      
      _isInitialized = true;
      debugPrint('Service WalletConnect Mock initialisé avec succès');
      notifyListeners();
    } catch (e) {
      debugPrint('Erreur lors de l\'initialisation du service Mock: $e');
      _isInitialized = false;
      notifyListeners();
    }
  }
  
  // Connexion simulée
  @override
  Future<String?> connect() async {
    if (_isLoading || !_isInitialized) return null;
    
    try {
      _isLoading = true;
      notifyListeners();
      
      // Générer un URI de connexion simulé
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final randomBytes = utf8.encode('walletconnect-mock-$timestamp');
      final hash = sha256.convert(randomBytes);
      final uri = 'wc:${hash.toString().substring(0, 32)}@1?bridge=https://bridge.walletconnect.org&key=mock';
      
      _connectionUri = uri;
      debugPrint('URI de connexion simulée: $uri');
      notifyListeners();
      
      return uri;
    } catch (e) {
      debugPrint('Erreur lors de la connexion simulée: $e');
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Simulation de la connexion avec une adresse
  Future<void> simulateConnection(String address) async {
    try {
      if (!_isValidEthereumAddress(address)) {
        throw Exception('Adresse Ethereum invalide');
      }
      
      _currentAddress = address;
      _isConnected = true;
      _connectionUri = null;
      
      await _saveSession();
      
      debugPrint('Connexion simulée avec l\'adresse: $address');
      notifyListeners();
    } catch (e) {
      debugPrint('Erreur lors de la simulation de connexion: $e');
    }
  }
  
  // Déconnexion
  @override
  Future<void> disconnect() async {
    try {
      await _clearSession();
      _resetState();
      
      debugPrint('Déconnexion simulée réussie');
      notifyListeners();
    } catch (e) {
      debugPrint('Erreur lors de la déconnexion simulée: $e');
    }
  }
  
  // Lancer l'application du portefeuille (simulé)
  @override
  Future<void> launchWalletApp([String? walletScheme]) async {
    if (_connectionUri == null) return;
    
    try {
      debugPrint('🔗 Simulation: Ouverture du wallet ${walletScheme ?? 'MetaMask'}...');
      debugPrint('📱 Dans un vrai scénario, ${walletScheme ?? 'MetaMask'} s\'ouvrirait maintenant');
      debugPrint('⏳ L\'utilisateur devrait approuver la connexion dans son wallet');
      debugPrint('💡 Pour tester: appelez simulateUserApproval() pour simuler l\'approbation');
      
      // Ne pas se connecter automatiquement - attendre une action utilisateur
      
    } catch (e) {
      debugPrint('Erreur lors du lancement simulé: $e');
    }
  }
  
  /// Simule l'approbation de l'utilisateur dans son wallet
  /// Dans une vraie app, cette méthode n'existerait pas - la connexion 
  /// se ferait via le callback WalletConnect
  Future<void> simulateUserApproval({String? customAddress}) async {
    if (_connectionUri == null) {
      debugPrint('❌ Aucune demande de connexion en cours');
      return;
    }
    
    try {
      debugPrint('✅ Simulation: L\'utilisateur a approuvé la connexion dans son wallet');
      debugPrint('🔐 Simulation: Génération de la signature d\'authentification...');
      
      // Simuler le délai de signature
      await Future.delayed(const Duration(seconds: 1));
      
      // Utiliser une adresse personnalisée ou l'adresse de test
      const defaultTestAddress = '0x742d35Cc6635C0532925a3b8D56c9E6eA22D9c08';
      final address = customAddress ?? defaultTestAddress;
      
      debugPrint('🎉 Connexion établie avec l\'adresse: $address');
      await simulateConnection(address);
      
    } catch (e) {
      debugPrint('❌ Erreur lors de la simulation d\'approbation: $e');
    }
  }
  
  /// Simule le rejet de l'utilisateur
  Future<void> simulateUserRejection() async {
    if (_connectionUri == null) {
      debugPrint('❌ Aucune demande de connexion en cours');
      return;
    }
    
    try {
      debugPrint('❌ Simulation: L\'utilisateur a rejeté la connexion');
      _connectionUri = null;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Erreur lors de la simulation de rejet: $e');
    }
  }
  
  // Méthodes utilitaires
  bool _isValidEthereumAddress(String address) {
    return address.startsWith('0x') && address.length == 42;
  }
  
  Future<void> _saveSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('mock_wallet_address', _currentAddress ?? '');
      await prefs.setBool('mock_wallet_connected', _isConnected);
    } catch (e) {
      debugPrint('Erreur lors de la sauvegarde de session mock: $e');
    }
  }
  
  Future<void> _loadSavedSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _currentAddress = prefs.getString('mock_wallet_address');
      _isConnected = prefs.getBool('mock_wallet_connected') ?? false;
      
      if (_currentAddress != null && _currentAddress!.isNotEmpty && _isConnected) {
        debugPrint('Session mock restaurée: $_currentAddress');
      }
    } catch (e) {
      debugPrint('Erreur lors du chargement de session mock: $e');
    }
  }
  
  Future<void> _clearSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('mock_wallet_address');
      await prefs.remove('mock_wallet_connected');
    } catch (e) {
      debugPrint('Erreur lors de la suppression de session mock: $e');
    }
  }
  
  void _resetState() {
    _currentAddress = null;
    _connectionUri = null;
    _isLoading = false;
    _isConnected = false;
    notifyListeners();
  }

  // Implémentation des méthodes optionnelles de l'interface
  @override
  Future<void> sendPersonalSignRequest(String message) async {
    debugPrint('Mock: Signature personnelle - message: $message');
    // Simulation d'une signature
    await Future.delayed(const Duration(seconds: 1));
  }

  @override
  Future<void> sendTransaction({
    required String to,
    required String value,
    String? data,
    String? gasLimit,
    String? gasPrice,
  }) async {
    debugPrint('Mock: Transaction - vers: $to, valeur: $value');
    // Simulation d'envoi de transaction
    await Future.delayed(const Duration(seconds: 2));
  }

  @override
  Future<double> getEthBalance() async {
    debugPrint('Mock: Récupération du solde ETH');
    // Retourner un solde fictif
    await Future.delayed(const Duration(milliseconds: 500));
    return 0.1234; // Solde fictif en ETH
  }

  @override
  Future<bool> isOnCorrectNetwork() async {
    debugPrint('Mock: Vérification du réseau');
    // Simuler que nous sommes sur le bon réseau
    return true;
  }
}
