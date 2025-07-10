# Reown AppKit Integration Guide

This document explains how to integrate Reown AppKit (formerly WalletConnect) with the Facture USDC Flutter application.

## Overview

Reown AppKit is a comprehensive SDK that provides an easy way to connect to various wallets and interact with the Ethereum blockchain. It supports over 200 wallets and provides a unified interface for wallet connections.

## Setup Instructions

### 1. Get Your Project ID

1. Go to [Reown Cloud](https://cloud.reown.com/)
2. Create a new project
3. Get your Project ID from the dashboard
4. Update `lib/services/app_config.dart` with your Project ID

### 2. Add Dependencies

Add the following to your `pubspec.yaml`:

```yaml
dependencies:
  reown_appkit: ^1.0.2
```

### 3. Configuration

Update the `projectId` in `lib/services/app_config.dart`:

```dart
static const String projectId = 'your-actual-project-id-here';
```

### 4. Initialize the Service

The `WalletService` class handles all wallet interactions:

```dart
// Initialize the service
final walletService = WalletService();
await walletService.initialize();

// Connect to a wallet
await walletService.connect();

// Get current address
String? address = walletService.currentAddress;

// Check connection status
bool isConnected = walletService.isConnected;
```

## Features

### Supported Wallets

- MetaMask
- Coinbase Wallet
- WalletConnect Protocol
- Over 200 other wallets

### Authentication Flow

1. User selects a wallet option
2. WalletService initiates connection
3. User approves connection in their wallet
4. App receives wallet address
5. User is redirected to home screen

### State Management

The app uses Provider for state management:

```dart
Consumer<WalletService>(
  builder: (context, walletService, child) {
    if (walletService.isConnected) {
      // Show connected state
    }
    return // UI based on connection state
  },
)
```

## Implementation Details

### File Structure

```
lib/
├── services/
│   ├── wallet_service.dart    # Main wallet service
│   └── app_config.dart        # Configuration
├── screens/
│   ├── auth_screen.dart       # Authentication screen
│   └── auth_screen_new.dart   # Alternative auth screen
└── main.dart                  # App entry point with Provider
```

### Key Methods

- `initialize()` - Initialize the AppKit
- `connect()` - Open wallet selection modal
- `connectWallet(String walletName)` - Connect to specific wallet
- `disconnect()` - Disconnect from wallet

## Security Considerations

1. **Never store private keys** - The service only handles connection, not private keys
2. **Validate addresses** - Always validate received addresses
3. **Use testnet first** - Test on Sepolia before mainnet
4. **Monitor sessions** - Handle session expiration gracefully

## Error Handling

The service includes comprehensive error handling:

```dart
try {
  await walletService.connect();
} catch (e) {
  // Handle connection errors
  print('Connection failed: $e');
}
```

## Next Steps

1. Replace the mock implementation with actual Reown AppKit calls
2. Add proper error handling for network issues
3. Implement session persistence
4. Add support for multiple networks
5. Add transaction signing capabilities

## Resources

- [Reown AppKit Documentation](https://docs.reown.com/appkit/flutter/core/installation)
- [Flutter Provider Documentation](https://pub.dev/packages/provider)
- [Ethereum Address Validation](https://ethereum.org/en/developers/docs/accounts/)