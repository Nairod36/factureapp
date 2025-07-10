import 'package:flutter/foundation.dart';
import 'app_config.dart';

class WalletService extends ChangeNotifier {
  bool _isInitialized = false;
  String? _currentAddress;
  bool _isConnected = false;
  bool _isConnecting = false;

  // Getters
  bool get isInitialized => _isInitialized;
  String? get currentAddress => _currentAddress;
  bool get isConnected => _isConnected;
  bool get isConnecting => _isConnecting;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Simulate initialization delay
      await Future.delayed(const Duration(milliseconds: 500));
      
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing wallet service: $e');
      }
    }
  }

  Future<void> connect() async {
    if (!_isInitialized) {
      throw Exception('WalletService not initialized');
    }

    if (_isConnected) return;

    try {
      _isConnecting = true;
      notifyListeners();
      
      // Simulate wallet connection with popular wallets
      await Future.delayed(const Duration(seconds: 2));
      
      // For demonstration, simulate successful connection
      _isConnected = true;
      _currentAddress = '0x742d35Cc6635C0532925a3b8D56c9E6eA22D9c08'; // Example address
      
      // Update app config
      AppConfig.setUserAddress(_currentAddress!);
      AppConfig.setAuthenticated(true);
      
      _isConnecting = false;
      notifyListeners();
    } catch (e) {
      _isConnecting = false;
      notifyListeners();
      if (kDebugMode) {
        print('Error connecting wallet: $e');
      }
      rethrow;
    }
  }

  Future<void> disconnect() async {
    if (!_isConnected) return;

    try {
      _isConnected = false;
      _currentAddress = null;
      
      // Update app config
      AppConfig.setAuthenticated(false);
      
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Error disconnecting wallet: $e');
      }
    }
  }

  // Method to simulate different wallet connections
  Future<void> connectWallet(String walletName) async {
    if (!_isInitialized) {
      throw Exception('WalletService not initialized');
    }

    if (_isConnected) return;

    try {
      _isConnecting = true;
      notifyListeners();
      
      // Simulate wallet-specific connection
      await Future.delayed(const Duration(seconds: 2));
      
      // Generate different addresses for different wallets (for demo)
      String address;
      switch (walletName.toLowerCase()) {
        case 'metamask':
          address = '0x742d35Cc6635C0532925a3b8D56c9E6eA22D9c08';
          break;
        case 'coinbase':
          address = '0x1234567890123456789012345678901234567890';
          break;
        case 'walletconnect':
          address = '0xabcdefabcdefabcdefabcdefabcdefabcdefabcd';
          break;
        default:
          address = '0x742d35Cc6635C0532925a3b8D56c9E6eA22D9c08';
      }
      
      _isConnected = true;
      _currentAddress = address;
      
      // Update app config
      AppConfig.setUserAddress(_currentAddress!);
      AppConfig.setAuthenticated(true);
      
      _isConnecting = false;
      notifyListeners();
    } catch (e) {
      _isConnecting = false;
      notifyListeners();
      if (kDebugMode) {
        print('Error connecting wallet: $e');
      }
      rethrow;
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
}