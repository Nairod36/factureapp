import 'package:flutter/material.dart';
import '../services/reown_wallet_connect_service.dart';

/// Widget pour la connexion WalletConnect avec Reown AppKit
class ReownWalletConnectWidget extends StatefulWidget {
  final Function(String address)? onConnected;
  final Function()? onDisconnected;

  const ReownWalletConnectWidget({
    Key? key,
    this.onConnected,
    this.onDisconnected,
  }) : super(key: key);

  @override
  State<ReownWalletConnectWidget> createState() => _ReownWalletConnectWidgetState();
}

class _ReownWalletConnectWidgetState extends State<ReownWalletConnectWidget> {
  late ReownWalletConnectService _walletService;
  bool _isInitializing = false;

  @override
  void initState() {
    super.initState();
    _walletService = ReownWalletConnectService();
    _walletService.addListener(_onWalletStateChanged);
    _initializeService();
  }

  @override
  void dispose() {
    _walletService.removeListener(_onWalletStateChanged);
    _walletService.dispose();
    super.dispose();
  }

  Future<void> _initializeService() async {
    if (_isInitializing) return;
    
    setState(() {
      _isInitializing = true;
    });

    try {
      // Initialisation de base
      await _walletService.initialize();
      
      debugPrint('✅ Service Reown initialisé avec succès');
    } catch (e) {
      debugPrint('❌ Erreur lors de l\'initialisation: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur d\'initialisation: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
    }
  }

  void _onWalletStateChanged() {
    if (!mounted) return;
    
    setState(() {});
    
    // Gérer les callbacks
    if (_walletService.isConnected && _walletService.currentAddress != null) {
      widget.onConnected?.call(_walletService.currentAddress!);
    } else if (!_walletService.isConnected) {
      widget.onDisconnected?.call();
    }
  }

  Future<void> _connectWallet() async {
    try {
      await _walletService.connect();
    } catch (e) {
      debugPrint('❌ Erreur de connexion: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur de connexion: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _disconnectWallet() async {
    try {
      await _walletService.disconnect();
    } catch (e) {
      debugPrint('❌ Erreur de déconnexion: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Initialisation de WalletConnect...'),
            ],
          ),
        ),
      );
    }

    if (!_walletService.isInitialized) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              const Text('Erreur d\'initialisation'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _initializeService,
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    if (_walletService.isConnected) {
      return _buildConnectedState();
    } else {
      return _buildDisconnectedState();
    }
  }

  Widget _buildConnectedState() {
    return Card(
      color: Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 48),
            const SizedBox(height: 16),
            const Text(
              'Portefeuille connecté',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _walletService.currentAddress ?? 'Adresse inconnue',
              style: const TextStyle(
                fontSize: 16,
                fontFamily: 'monospace',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _disconnectWallet,
                  icon: const Icon(Icons.logout),
                  label: const Text('Déconnecter'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showConnectionInfo(context),
                  icon: const Icon(Icons.info),
                  label: const Text('Info'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDisconnectedState() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.account_balance_wallet, size: 48, color: Colors.blue),
            const SizedBox(height: 16),
            const Text(
              'Connecter votre portefeuille',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Choisissez votre portefeuille pour commencer',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (_walletService.isConnecting)
              const Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Connexion en cours...'),
                ],
              )
            else
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _connectWallet,
                  icon: const Icon(Icons.link),
                  label: const Text('Connecter le portefeuille'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            const SizedBox(height: 16),
            const Text(
              'Compatible avec MetaMask, Trust Wallet, Rainbow, et plus',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showConnectionInfo(BuildContext context) async {
    // Informations simplifiées depuis le service
    final info = {
      'address': _walletService.currentAddress ?? 'Non connecté',
      'isConnected': _walletService.isConnected,
      'isInitialized': _walletService.isInitialized,
    };
    
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Informations de connexion'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildInfoRow('Service', 'Reown WalletConnect (Mock)'),
              _buildInfoRow('Adresse', info['address'].toString()),
              _buildInfoRow('Connecté', info['isConnected'].toString()),
              _buildInfoRow('Initialisé', info['isInitialized'].toString()),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontFamily: 'monospace'),
            ),
          ),
        ],
      ),
    );
  }
}
