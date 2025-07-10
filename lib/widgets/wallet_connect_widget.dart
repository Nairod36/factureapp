import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../services/wallet_connect_interface.dart';

class WalletConnectWidget extends StatefulWidget {
  final Function(String address)? onConnected;
  final Function()? onDisconnected;

  const WalletConnectWidget({
    Key? key,
    this.onConnected,
    this.onDisconnected,
  }) : super(key: key);

  @override
  State<WalletConnectWidget> createState() => _WalletConnectWidgetState();
}

class _WalletConnectWidgetState extends State<WalletConnectWidget> {
  @override
  void initState() {
    super.initState();
    _initializeWalletConnect();
  }

  Future<void> _initializeWalletConnect() async {
    final walletService = Provider.of<WalletConnectServiceInterface>(context, listen: false);
    if (!walletService.isInitialized) {
      await walletService.initialize();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WalletConnectServiceInterface>(
      builder: (context, walletService, child) {
        if (!walletService.isInitialized) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (walletService.isConnected) {
          // Appeler le callback onConnected si une adresse est disponible
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (walletService.currentAddress != null && widget.onConnected != null) {
              widget.onConnected!(walletService.currentAddress!);
            }
          });
          return _buildConnectedState(walletService);
        } else if (walletService.isConnecting && walletService.connectionUri != null) {
          return _buildConnectingState(walletService);
        } else {
          return _buildDisconnectedState(walletService);
        }
      },
    );
  }

  Widget _buildConnectedState(WalletConnectServiceInterface walletService) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.account_balance_wallet,
              color: Colors.green,
              size: 32,
            ),
            const SizedBox(height: 8),
            const Text(
              'Portefeuille connecté',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _formatAddress(walletService.currentAddress ?? ''),
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    if (walletService.currentAddress != null) {
                      Clipboard.setData(
                        ClipboardData(text: walletService.currentAddress!),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Adresse copiée dans le presse-papiers'),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.copy, size: 16),
                  label: const Text('Copier'),
                ),
                ElevatedButton.icon(
                  onPressed: () => _disconnect(walletService),
                  icon: const Icon(Icons.logout, size: 16),
                  label: const Text('Déconnecter'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectingState(WalletConnectServiceInterface walletService) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Connexion au portefeuille',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // QR Code
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: QrImageView(
                data: walletService.connectionUri!,
                version: QrVersions.auto,
                size: 200,
                backgroundColor: Colors.white,
                eyeStyle: const QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: Colors.black,
                ),
                dataModuleStyle: const QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: Colors.black,
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            const Text(
              'Scannez le QR code avec votre portefeuille ou utilisez les boutons ci-dessous',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14),
            ),
            
            const SizedBox(height: 16),
            
            // Boutons de lancement d'applications
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildWalletButton(
                  'MetaMask',
                  'assets/images/metamask.png',
                  () => walletService.launchWalletApp('metamask'),
                ),
                _buildWalletButton(
                  'Trust Wallet',
                  'assets/images/trust.png',
                  () => walletService.launchWalletApp('trust'),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Boutons d'action
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton.icon(
                  onPressed: () {
                    Clipboard.setData(
                      ClipboardData(text: walletService.connectionUri!),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('URI copiée dans le presse-papiers'),
                      ),
                    );
                  },
                  icon: const Icon(Icons.copy, size: 16),
                  label: const Text('Copier URI'),
                ),
                TextButton.icon(
                  onPressed: () => _cancelConnection(walletService),
                  icon: const Icon(Icons.cancel, size: 16),
                  label: const Text('Annuler'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDisconnectedState(WalletConnectServiceInterface walletService) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.account_balance_wallet_outlined,
              size: 32,
              color: Colors.grey,
            ),
            const SizedBox(height: 8),
            const Text(
              'Portefeuille non connecté',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Connectez votre portefeuille Ethereum pour continuer',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: walletService.isConnecting ? null : () => _connect(walletService),
              icon: walletService.isConnecting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.account_balance_wallet),
              label: Text(walletService.isConnecting ? 'Connexion...' : 'Connecter le portefeuille'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWalletButton(String name, String iconPath, VoidCallback onPressed) {
    return Column(
      children: [
        GestureDetector(
          onTap: onPressed,
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Center(
              child: Image.asset(
                iconPath,
                width: 32,
                height: 32,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.account_balance_wallet,
                    size: 32,
                    color: Colors.grey.shade600,
                  );
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          name,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  Future<void> _connect(WalletConnectServiceInterface walletService) async {
    try {
      final uri = await walletService.connect();
      if (uri != null) {
        // La connexion a été initiée avec succès
        // L'état sera mis à jour automatiquement via le Provider
      }
    } catch (e) {
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

  Future<void> _disconnect(WalletConnectServiceInterface walletService) async {
    try {
      await walletService.disconnect();
      if (widget.onDisconnected != null) {
        widget.onDisconnected!();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur de déconnexion: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _cancelConnection(WalletConnectServiceInterface walletService) {
    // Réinitialiser l'état de connexion
    walletService.disconnect();
  }

  String _formatAddress(String address) {
    if (address.length < 10) return address;
    return '${address.substring(0, 6)}...${address.substring(address.length - 4)}';
  }
}
