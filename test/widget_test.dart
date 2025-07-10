import 'package:flutter_test/flutter_test.dart';

import 'package:factureapp/services/wallet_connect_interface.dart';
import 'package:factureapp/services/wallet_connect_mock_service.dart';

void main() {
  group('WalletConnect Mock Service Tests', () {
    late WalletConnectServiceInterface walletService;

    setUp(() {
      walletService = WalletConnectMockService();
    });

    test('Service initializes correctly', () async {
      expect(walletService.isInitialized, isFalse);
      
      await walletService.initialize();
      
      expect(walletService.isInitialized, isTrue);
    });

    test('Service can connect and disconnect', () async {
      await walletService.initialize();
      
      expect(walletService.isConnected, isFalse);
      expect(walletService.isConnecting, isFalse);
      
      final uri = await walletService.connect();
      
      expect(uri, isNotNull);
      expect(walletService.isConnecting, isTrue);
      expect(walletService.connectionUri, isNotNull);
      
      // Simulate connection completion
      await Future.delayed(Duration(milliseconds: 100));
      
      await walletService.disconnect();
      
      expect(walletService.isConnected, isFalse);
    });

    test('Service provides mock address when connected', () async {
      await walletService.initialize();
      await walletService.connect();
      
      // In mock service, address is set after connection
      expect(walletService.currentAddress, isNotNull);
    });
  });
}
