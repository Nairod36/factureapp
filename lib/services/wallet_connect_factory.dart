import 'package:flutter/foundation.dart';
import 'wallet_connect_interface.dart';
// import 'wallet_connect_service.dart';  // Service réel avec plugin - Désactivé (problèmes Android)
import 'reown_wallet_connect_service.dart';  // Service utilisant Reown AppKit (nouvelle solution officielle)
import 'wallet_connect_mock_service.dart';

/// Factory pour créer le service WalletConnect approprié
/// Permet de basculer facilement entre service réel et mock
class WalletConnectServiceFactory {
  static const bool _forceUseMockService = false; // Service Reown maintenant disponible
  
  /// Crée le service WalletConnect approprié
  static WalletConnectServiceInterface createService() {
    if (_forceUseMockService || kDebugMode) {
      debugPrint('🔧 Utilisation du service WalletConnect mock pour debug');
      return WalletConnectMockService();
    } else {
      debugPrint('🔌 Utilisation du service Reown WalletConnect');
      return ReownWalletConnectService();
    }
  }
  
  /// Vérifie si le service réel est disponible
  static Future<bool> isRealServiceAvailable() async {
    return !_forceUseMockService; // Service Reown disponible
  }
  
  /// Retourne la configuration actuelle
  static Map<String, dynamic> getConfiguration() {
    return {
      'forceMockService': _forceUseMockService,
      'isDebugMode': kDebugMode,
      'isWeb': kIsWeb,
      'recommendedService': 'mock',
      'serviceType': 'Mock',
    };
  }
}
