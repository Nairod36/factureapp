import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/wallet_service.dart';

class AuthScreen extends StatefulWidget {
  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isLoading = false;
  String? _errorMessage;
  late WalletService _walletService;

  @override
  void initState() {
    super.initState();
    _walletService = Provider.of<WalletService>(context, listen: false);
    _initializeWalletService();
  }

  Future<void> _initializeWalletService() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _walletService.initialize();
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur d\'initialisation: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _connectWallet([String? walletName]) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (walletName != null) {
        await _walletService.connectWallet(walletName);
      } else {
        await _walletService.connect();
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur de connexion: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.shade400,
              Colors.blue.shade600,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Consumer<WalletService>(
                builder: (context, walletService, child) {
                  // Si le portefeuille est connecté, naviguer vers l'accueil
                  if (walletService.isConnected && walletService.currentAddress != null) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      Navigator.pushReplacementNamed(
                        context, 
                        '/home', 
                        arguments: walletService.currentAddress!
                      );
                    });
                  }
                  
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo/Icône
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.account_balance_wallet,
                          size: 64,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(height: 40),
                      
                      // Titre et description
                      const Text(
                        'Facture USDC',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Connectez votre portefeuille Ethereum',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 40),
                      
                      // Formulaire
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'Connexion Portefeuille',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Connectez votre portefeuille pour commencer',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.black54,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 32),
                            
                            // Affichage du statut du portefeuille
                            if (walletService.isConnected && walletService.currentAddress != null) ...[
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.green.shade200),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.check_circle, color: Colors.green.shade600),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Portefeuille connecté',
                                            style: TextStyle(
                                              color: Colors.green.shade700,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            '${walletService.currentAddress?.substring(0, 6)}...${walletService.currentAddress?.substring(walletService.currentAddress!.length - 4)}',
                                            style: TextStyle(
                                              color: Colors.green.shade600,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                            
                            // Loading state display
                            if (_isLoading || walletService.isConnecting) ...[
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.blue.shade200),
                                ),
                                child: const Row(
                                  children: [
                                    SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.blue,
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Text('Connexion en cours...'),
                                  ],
                                ),
                              ),
                            ],
                            
                            // Boutons de connexion pour différents portefeuilles
                            Column(
                              children: [
                                // Bouton MetaMask
                                ElevatedButton.icon(
                                  onPressed: (_isLoading || !walletService.isInitialized || walletService.isConnecting) 
                                      ? null 
                                      : () => _connectWallet('metamask'),
                                  icon: const Icon(Icons.account_balance_wallet),
                                  label: const Text('MetaMask'),
                                  style: ElevatedButton.styleFrom(
                                    minimumSize: const Size(double.infinity, 48),
                                    backgroundColor: Colors.orange,
                                  ),
                                ),
                                
                                const SizedBox(height: 12),
                                
                                // Bouton Coinbase Wallet
                                ElevatedButton.icon(
                                  onPressed: (_isLoading || !walletService.isInitialized || walletService.isConnecting) 
                                      ? null 
                                      : () => _connectWallet('coinbase'),
                                  icon: const Icon(Icons.monetization_on),
                                  label: const Text('Coinbase Wallet'),
                                  style: ElevatedButton.styleFrom(
                                    minimumSize: const Size(double.infinity, 48),
                                    backgroundColor: Colors.blue.shade800,
                                  ),
                                ),
                                
                                const SizedBox(height: 12),
                                
                                // Bouton WalletConnect
                                ElevatedButton.icon(
                                  onPressed: (_isLoading || !walletService.isInitialized || walletService.isConnecting) 
                                      ? null 
                                      : () => _connectWallet('walletconnect'),
                                  icon: const Icon(Icons.connect_without_contact),
                                  label: const Text('WalletConnect'),
                                  style: ElevatedButton.styleFrom(
                                    minimumSize: const Size(double.infinity, 48),
                                    backgroundColor: Colors.purple,
                                  ),
                                ),
                              ],
                            ),
                            
                            // Message d'erreur
                            if (_errorMessage != null) ...[
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.red.shade200),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.error, color: Colors.red.shade600),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _errorMessage!,
                                        style: TextStyle(
                                          color: Colors.red.shade700,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),
                      
                      // Instructions
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Icon(Icons.info_outline, color: Colors.white70),
                                const SizedBox(width: 8),
                                Text(
                                  'Portefeuilles supportés',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '• MetaMask\n'
                              '• WalletConnect\n'
                              '• Coinbase Wallet\n'
                              '• Et bien d\'autres...',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
