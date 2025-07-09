import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/app_config.dart';

class CreateInvoiceScreen extends StatefulWidget {
  final String userAddress;

  const CreateInvoiceScreen({Key? key, required this.userAddress}) : super(key: key);

  @override
  _CreateInvoiceScreenState createState() => _CreateInvoiceScreenState();
}

class _CreateInvoiceScreenState extends State<CreateInvoiceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _clientController = TextEditingController();
  final _montantController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isLoading = false;
  String? _resultMessage;
  String? _invoiceId;

  @override
  void dispose() {
    _clientController.dispose();
    _montantController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _createInvoice() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _resultMessage = null;
      _invoiceId = null;
    });

    try {
      final response = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/api/invoice/create'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'merchant': widget.userAddress,
          'client': _clientController.text.trim(),
          'montant': _montantController.text.trim(),
          'description': _descriptionController.text.trim(),
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        setState(() {
          _invoiceId = data['invoiceId'].toString();
          _resultMessage = 'Facture créée avec succès! ID: $_invoiceId';
        });
        
        // Réinitialiser le formulaire
        _formKey.currentState!.reset();
        _clientController.clear();
        _montantController.clear();
        _descriptionController.clear();
        
        // Afficher la boîte de dialogue de succès
        _showSuccessDialog();
      } else {
        setState(() {
          _resultMessage = 'Erreur: ${data['error'] ?? 'Création échouée'}';
        });
      }
    } catch (e) {
      setState(() {
        _resultMessage = 'Erreur de connexion: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 8),
              Text('Succès!'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Votre facture a été créée avec succès.'),
              const SizedBox(height: 8),
              Text('ID de la facture: $_invoiceId', style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushNamed(context, '/invoice-list');
              },
              child: const Text('Voir mes factures'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Créer une facture'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // En-tête informatif
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue.shade700),
                        const SizedBox(width: 8),
                        Text(
                          'Nouvelle facture USDC',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Créez une facture qui sera enregistrée sur la blockchain. '
                      'Le client pourra la payer directement en USDC.',
                      style: TextStyle(color: Colors.blue.shade600),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Informations marchand
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Informations marchand',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.person, color: Colors.grey),
                          const SizedBox(width: 8),
                          Text('Nom: ${AppConfig.userName ?? "Non défini"}'),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.account_balance_wallet, color: Colors.grey),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text('Wallet: ${AppConfig.formatAddress(AppConfig.userAddress)}'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Formulaire de facture
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Détails de la facture',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Adresse du client
                      TextFormField(
                        controller: _clientController,
                        decoration: InputDecoration(
                          labelText: 'Adresse du client',
                          hintText: '0x...',
                          prefixIcon: const Icon(Icons.person_outline),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          helperText: 'Adresse Ethereum du client qui paiera la facture',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Veuillez entrer l\'adresse du client';
                          }
                          if (!AppConfig.isValidEthereumAddress(value)) {
                            return 'Format d\'adresse invalide';
                          }
                          if (value.toLowerCase() == AppConfig.userAddress.toLowerCase()) {
                            return 'Le client ne peut pas être le même que le marchand';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Montant
                      TextFormField(
                        controller: _montantController,
                        decoration: InputDecoration(
                          labelText: 'Montant',
                          hintText: '100.00',
                          prefixIcon: const Icon(Icons.attach_money),
                          suffixText: 'USDC',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          helperText: 'Montant en USDC (minimum ${AppConfig.minInvoiceAmount})',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Veuillez entrer le montant';
                          }
                          final montant = double.tryParse(value);
                          if (montant == null) {
                            return 'Montant invalide';
                          }
                          if (montant < AppConfig.minInvoiceAmount) {
                            return 'Montant minimum: ${AppConfig.minInvoiceAmount} USDC';
                          }
                          if (montant > AppConfig.maxInvoiceAmount) {
                            return 'Montant maximum: ${AppConfig.maxInvoiceAmount} USDC';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Description
                      TextFormField(
                        controller: _descriptionController,
                        decoration: InputDecoration(
                          labelText: 'Description',
                          hintText: 'Services de développement, produits vendus...',
                          prefixIcon: const Icon(Icons.description),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          helperText: 'Description détaillée des services/produits facturés',
                        ),
                        maxLines: 3,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Veuillez entrer une description';
                          }
                          if (value.trim().length < 10) {
                            return 'Description trop courte (minimum 10 caractères)';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Bouton de création
              ElevatedButton(
                onPressed: _isLoading ? null : _createInvoice,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 8),
                          Text('Création en cours...'),
                        ],
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_circle_outline),
                          SizedBox(width: 8),
                          Text(
                            'Créer la facture',
                            style: TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
              ),
              
              // Message de résultat
              if (_resultMessage != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _resultMessage!.contains('Erreur')
                        ? Colors.red.shade50
                        : Colors.green.shade50,
                    border: Border.all(
                      color: _resultMessage!.contains('Erreur')
                          ? Colors.red
                          : Colors.green,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _resultMessage!.contains('Erreur')
                            ? Icons.error_outline
                            : Icons.check_circle_outline,
                        color: _resultMessage!.contains('Erreur')
                            ? Colors.red.shade700
                            : Colors.green.shade700,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _resultMessage!,
                          style: TextStyle(
                            color: _resultMessage!.contains('Erreur')
                                ? Colors.red.shade700
                                : Colors.green.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              const SizedBox(height: 16),
              
              // Informations utiles
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.lightbulb_outline, color: Colors.grey.shade600),
                        const SizedBox(width: 8),
                        Text(
                          'Conseils',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '• La facture sera enregistrée sur la blockchain\n'
                      '• Le client pourra la payer directement en USDC\n'
                      '• Vous recevrez les fonds instantanément après paiement\n'
                      '• Assurez-vous que l\'adresse du client est correcte',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
