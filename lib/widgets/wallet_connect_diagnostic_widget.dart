import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../services/wallet_connect_interface.dart';
import '../services/wallet_connect_factory.dart';

class WalletConnectDiagnosticWidget extends StatefulWidget {
  const WalletConnectDiagnosticWidget({Key? key}) : super(key: key);

  @override
  State<WalletConnectDiagnosticWidget> createState() => _WalletConnectDiagnosticWidgetState();
}

class _WalletConnectDiagnosticWidgetState extends State<WalletConnectDiagnosticWidget> {
  Map<String, dynamic>? _serviceConfig;
  bool _isRealServiceAvailable = false;
  bool _isCheckingService = false;

  @override
  void initState() {
    super.initState();
    _loadConfiguration();
  }

  void _loadConfiguration() {
    setState(() {
      _serviceConfig = WalletConnectServiceFactory.getConfiguration();
    });
  }

  Future<void> _checkRealService() async {
    // Sur le web, ne pas tester le service réel
    if (kIsWeb) {
      setState(() {
        _isRealServiceAvailable = false;
      });
      return;
    }
    
    setState(() {
      _isCheckingService = true;
    });

    try {
      _isRealServiceAvailable = await WalletConnectServiceFactory.isRealServiceAvailable();
    } catch (e) {
      debugPrint('Erreur lors du test du service réel: $e');
      _isRealServiceAvailable = false;
    }

    setState(() {
      _isCheckingService = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.bug_report,
                  color: Colors.blue,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Diagnostic WalletConnect',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Configuration actuelle
            _buildConfigurationSection(),
            
            const SizedBox(height: 16),
            
            // État du service
            _buildServiceStatusSection(),
            
            const SizedBox(height: 16),
            
            // Actions
            _buildActionsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildConfigurationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Configuration',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        if (_serviceConfig != null) ...[
          _buildInfoRow('Service forcé', _serviceConfig!['forceMockService'] ? 'Mock' : 'Auto'),
          _buildInfoRow('Mode debug', _serviceConfig!['isDebugMode'] ? 'Oui' : 'Non'),
          _buildInfoRow('Plateforme Web', _serviceConfig!['isWeb'] ? 'Oui' : 'Non'),
          _buildInfoRow('Service recommandé', _serviceConfig!['recommendedService']),
        ],
      ],
    );
  }

  Widget _buildServiceStatusSection() {
    return Consumer<WalletConnectServiceInterface>(
      builder: (context, service, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'État du service',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            _buildInfoRow('Type de service', service.runtimeType.toString()),
            _buildInfoRow('Initialisé', service.isInitialized ? 'Oui' : 'Non'),
            _buildInfoRow('Connecté', service.isConnected ? 'Oui' : 'Non'),
            _buildInfoRow('En cours de connexion', service.isConnecting ? 'Oui' : 'Non'),
            _buildInfoRow('Adresse courante', service.currentAddress ?? 'Non disponible'),
            if (service.connectionUri != null)
              _buildInfoRow('URI de connexion', service.connectionUri!.length > 50 
                ? service.connectionUri!.substring(0, 50) + '...'
                : service.connectionUri!),
          ],
        );
      },
    );
  }

  Widget _buildActionsSection() {
    return Consumer<WalletConnectServiceInterface>(
      builder: (context, service, child) {
        // Vérifier si c'est le service mock pour afficher les contrôles de debug
        final isMockService = service.runtimeType.toString().contains('Mock');
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Actions',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: _loadConfiguration,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Recharger'),
                ),
                ElevatedButton.icon(
                  onPressed: (_isCheckingService || kIsWeb) ? null : _checkRealService,
                  icon: _isCheckingService 
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(kIsWeb ? Icons.not_interested : Icons.check_circle),
                  label: Text(kIsWeb ? 'Non disponible sur web' : 'Tester service réel'),
                ),
                
                // Boutons de debug spécifiques au service mock
                if (isMockService && service.connectionUri != null) ...[
                  ElevatedButton.icon(
                    onPressed: () => _simulateUserApproval(service),
                    icon: const Icon(Icons.check, color: Colors.green),
                    label: const Text('✅ Approuver'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade50,
                      foregroundColor: Colors.green.shade700,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _simulateUserRejection(service),
                    icon: const Icon(Icons.close, color: Colors.red),
                    label: const Text('❌ Rejeter'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade50,
                      foregroundColor: Colors.red.shade700,
                    ),
                  ),
                ],
              ],
            ),
            
            // Message d'aide pour le mode debug
            if (isMockService && service.connectionUri != null)
              Container(
                margin: const EdgeInsets.only(top: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  border: Border.all(color: Colors.amber.shade200),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.amber.shade700, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Mode Debug: Une demande de connexion est en attente. '
                        'Dans une vraie app, l\'utilisateur approuverait dans son wallet.',
                        style: TextStyle(
                          color: Colors.amber.shade700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            
            if (_isRealServiceAvailable)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      'Service réel disponible',
                      style: TextStyle(color: Colors.green),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
  
  // Méthodes pour simuler les actions utilisateur (debug uniquement)
  void _simulateUserApproval(WalletConnectServiceInterface service) async {
    try {
      // Utiliser la réflexion pour appeler la méthode du service mock
      if (service.runtimeType.toString().contains('Mock')) {
        // Essayer d'appeler simulateUserApproval via dynamic
        final dynamic mockService = service;
        await mockService.simulateUserApproval();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Connexion approuvée (simulation)'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Erreur lors de la simulation d\'approbation: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  void _simulateUserRejection(WalletConnectServiceInterface service) async {
    try {
      if (service.runtimeType.toString().contains('Mock')) {
        final dynamic mockService = service;
        await mockService.simulateUserRejection();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Connexion rejetée (simulation)'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Erreur lors de la simulation de rejet: $e');
    }
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
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
