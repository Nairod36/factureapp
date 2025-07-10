import 'package:flutter/foundation.dart';

/// Interface abstraite pour les services WalletConnect
abstract class WalletConnectServiceInterface extends ChangeNotifier {
  // Getters
  bool get isConnected;
  bool get isConnecting;
  String? get currentAddress;
  String? get connectionUri;
  bool get isInitialized;
  
  // Méthodes abstraites
  Future<void> initialize();
  Future<String?> connect();
  Future<void> disconnect();
  Future<void> launchWalletApp([String? walletScheme]);
  
  // Méthodes optionnelles pour les fonctionnalités avancées
  Future<void> sendPersonalSignRequest(String message);
  Future<void> sendTransaction({
    required String to,
    required String value,
    String? data,
    String? gasLimit,
    String? gasPrice,
  });
  Future<double> getEthBalance();
  Future<bool> isOnCorrectNetwork();
}
