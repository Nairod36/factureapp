import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CreateInvoiceWidget extends StatefulWidget {
  final String apiBaseUrl;

  const CreateInvoiceWidget({Key? key, required this.apiBaseUrl}) : super(key: key);

  @override
  _CreateInvoiceWidgetState createState() => _CreateInvoiceWidgetState();
}

class _CreateInvoiceWidgetState extends State<CreateInvoiceWidget> {
  final _formKey = GlobalKey<FormState>();
  final _clientController = TextEditingController();
  final _montantController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isLoading = false;
  String? _resultMessage;

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
    });

    try {
      final response = await http.post(
        Uri.parse('${widget.apiBaseUrl}/api/invoice/create'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'client': _clientController.text.trim(),
          'montant': _montantController.text.trim(),
          'description': _descriptionController.text.trim(),
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        setState(() {
          _resultMessage = 'Facture créée avec succès! ID: ${data['invoiceId']}';
        });
        _formKey.currentState!.reset();
        _clientController.clear();
        _montantController.clear();
        _descriptionController.clear();
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

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Créer une facture',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _clientController,
                decoration: const InputDecoration(
                  labelText: 'Adresse du client',
                  hintText: '0x...',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer l\'adresse du client';
                  }
                  if (!value.startsWith('0x') || value.length != 42) {
                    return 'Format d\'adresse invalide';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _montantController,
                decoration: const InputDecoration(
                  labelText: 'Montant USDC',
                  hintText: '100',
                  border: OutlineInputBorder(),
                  suffixText: 'USDC',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer le montant';
                  }
                  final montant = double.tryParse(value);
                  if (montant == null || montant <= 0) {
                    return 'Montant invalide';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Services de développement...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer une description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _isLoading ? null : _createInvoice,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
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
                    : const Text(
                        'Créer la facture',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
              if (_resultMessage != null) ...[
                const SizedBox(height: 12),
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
            ],
          ),
        ),
      ),
    );
  }
}
