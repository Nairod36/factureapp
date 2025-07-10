import 'package:flutter_test/flutter_test.dart';
import 'package:factureapp/services/wallet_service.dart';

void main() {
  group('WalletService Tests', () {
    late WalletService walletService;

    setUp(() {
      walletService = WalletService();
    });

    tearDown(() {
      walletService.dispose();
    });

    test('should initialize successfully', () async {
      expect(walletService.isInitialized, false);
      
      await walletService.initialize();
      
      expect(walletService.isInitialized, true);
    });

    test('should not be connected initially', () {
      expect(walletService.isConnected, false);
      expect(walletService.currentAddress, null);
    });

    test('should connect with MetaMask', () async {
      await walletService.initialize();
      expect(walletService.isInitialized, true);
      
      await walletService.connectWallet('metamask');
      
      expect(walletService.isConnected, true);
      expect(walletService.currentAddress, isNotNull);
      expect(walletService.currentAddress!.startsWith('0x'), true);
      expect(walletService.currentAddress!.length, 42);
    });

    test('should connect with Coinbase Wallet', () async {
      await walletService.initialize();
      
      await walletService.connectWallet('coinbase');
      
      expect(walletService.isConnected, true);
      expect(walletService.currentAddress, isNotNull);
      expect(walletService.currentAddress, '0x1234567890123456789012345678901234567890');
    });

    test('should connect with WalletConnect', () async {
      await walletService.initialize();
      
      await walletService.connectWallet('walletconnect');
      
      expect(walletService.isConnected, true);
      expect(walletService.currentAddress, isNotNull);
      expect(walletService.currentAddress, '0xabcdefabcdefabcdefabcdefabcdefabcdefabcd');
    });

    test('should disconnect properly', () async {
      await walletService.initialize();
      await walletService.connectWallet('metamask');
      
      expect(walletService.isConnected, true);
      
      await walletService.disconnect();
      
      expect(walletService.isConnected, false);
      expect(walletService.currentAddress, null);
    });

    test('should throw error when connecting without initialization', () async {
      expect(
        () async => await walletService.connect(),
        throwsA(isA<Exception>()),
      );
    });

    test('should handle multiple connection attempts', () async {
      await walletService.initialize();
      
      await walletService.connectWallet('metamask');
      expect(walletService.isConnected, true);
      
      // Second connection should not change state
      await walletService.connectWallet('coinbase');
      expect(walletService.isConnected, true);
    });
  });
}