import 'package:flutter_test/flutter_test.dart';
import 'package:factureapp/services/reown_wallet_connect_service.dart';

void main() {
  group('ReownWalletConnectService', () {
    late ReownWalletConnectService service;

    setUp(() {
      service = ReownWalletConnectService();
    });

    tearDown(() {
      service.dispose();
    });

    test('should initialize without context', () async {
      expect(service.isInitialized, false);
      expect(service.isConnected, false);
      expect(service.isConnecting, false);
      expect(service.currentAddress, null);
      
      // L'initialisation de base
      await service.initialize();
      
      expect(service.isInitialized, true);
      expect(service.isConnected, false);
    });

    test('should return correct initial state', () {
      expect(service.isInitialized, false);
      expect(service.isConnected, false);
      expect(service.isConnecting, false);
      expect(service.currentAddress, null);
      expect(service.connectionUri, null);
    });

    test('should implement WalletConnectServiceInterface methods', () async {
      await service.initialize();
      
      // Test que toutes les méthodes de l'interface sont disponibles
      expect(() => service.launchWalletApp(), returnsNormally);
      
      // Ces méthodes lèvent des exceptions quand pas connecté (comportement attendu)
      expect(() => service.sendPersonalSignRequest('test'), throwsException);
      expect(() => service.getEthBalance(), returnsNormally);
      expect(() => service.isOnCorrectNetwork(), returnsNormally);
    });

    test('should handle service state correctly', () async {
      await service.initialize();
      
      expect(service.isInitialized, true);
      expect(service.isConnected, false);
      expect(service.currentAddress, null);
    });

    test('should throw error when connecting without initialization', () async {
      expect(
        () => service.connect(),
        throwsA(isA<Exception>()),
      );
    });

    test('should handle disconnect gracefully when not connected', () async {
      await service.initialize();
      
      // Ne devrait pas lever d'erreur même si pas connecté
      expect(() => service.disconnect(), returnsNormally);
    });

    test('should validate network checking', () async {
      await service.initialize();
      
      final isCorrectNetwork = await service.isOnCorrectNetwork();
      
      // Devrait retourner false car pas connecté
      expect(isCorrectNetwork, false);
    });

    test('should handle balance retrieval when not connected', () async {
      await service.initialize();
      
      final balance = await service.getEthBalance();
      
      // Devrait retourner 0.0 car pas connecté
      expect(balance, 0.0);
    });
  });
}
