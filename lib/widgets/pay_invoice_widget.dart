import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PayInvoiceWidget extends StatefulWidget {
  final String apiBaseUrl;

  const PayInvoiceWidget({Key? key, required this.apiBaseUrl}) : super(key: key);

  @override
  _PayInvoiceWidgetState createState() => _PayInvoiceWidgetState();
}

class _PayInvoiceWidgetState extends State<PayInvoiceWidget> {
  final _formKey = GlobalKey<FormState>();
  final _invoiceIdController = TextEditingController();
  bool _isLoading = false;
  bool _isChecking = false;
  String? _resultMessage;
  Map<String, dynamic>? _invoiceDetails;

  @override
  void dispose() {
    _invoiceIdController.dispose();
    super.dispose();
  }

  Future<void> _checkInvoice() async {
    if (_invoiceIdController.text.trim().isEmpty) return;

    setState(() {
      _isChecking = true;
      _invoiceDetails = null;
      _resultMessage = null;
    });

    try {
      final response = await http.get(
        Uri.parse('${widget.apiBaseUrl}/api/invoice/status/${_invoiceIdController.text.trim()}'),
        headers: {'Content-Type': 'application/json'},
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        setState(() {
          _invoiceDetails = data['invoice'];
        });
      } else {
        setState(() {
          _resultMessage = 'Erreur: ${data['error'] ?? 'Facture non trouvée'}';
        });
      }
    } catch (e) {
      setState(() {
        _resultMessage = 'Erreur de connexion: $e';
      });
    } finally {
      setState(() {
        _isChecking = false;
      });
    }
  }

  Future<void> _payInvoice() async {
    if (_invoiceDetails == null) return;

    setState(() {
      _isLoading = true;
      _resultMessage = null;
    });

    try {
      final response = await http.post(
        Uri.parse('${widget.apiBaseUrl}/api/invoice/pay'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'invoiceId': _invoiceIdController.text.trim(),
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        setState(() {
          _resultMessage = 'Paiement initié avec succès! Hash: ${data['transactionHash']}';
          _invoiceDetails = null;
        });
        _invoiceIdController.clear();
      } else {
        setState(() {
          _resultMessage = 'Erreur: ${data['error'] ?? 'Paiement échoué'}';
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

  String _formatDate(String timestamp) {
    try {
      final date = DateTime.fromMillisecondsSinceEpoch(int.parse(timestamp) * 1000);
      return '${date.day}/${date.month}/${date.year} à ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Date inconnue';
    }
  }

  String _truncateAddress(String address) {
    if (address.length < 10) return address;
    return '${address.substring(0, 6)}...${address.substring(address.length - 4)}';
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
                'Payer une facture',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _invoiceIdController,
                      decoration: const InputDecoration(
                        labelText: 'ID de la facture',
                        hintText: '1',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer l\'ID de la facture';
                        }
                        final id = int.tryParse(value);
                        if (id == null || id <= 0) {
                          return 'ID invalide';
                        }
                        return null;
                      },
                      onChanged: (value) {
                        if (_invoiceDetails != null) {
                          setState(() {
                            _invoiceDetails = null;
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _isChecking ? null : _checkInvoice,
                    child: _isChecking
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Vérifier'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Détails de la facture
              if (_invoiceDetails != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    border: Border.all(color: Colors.blue.shade200),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Détails de la facture:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      _detailRow('Marchand', _truncateAddress(_invoiceDetails!['marchand'] ?? '')),
                      _detailRow('Montant', '${_invoiceDetails!['montant'] ?? '0'} USDC'),
                      _detailRow('Date de création', _formatDate(_invoiceDetails!['dateCreation'] ?? '0')),
                      _detailRow('Statut', _invoiceDetails!['payee'] == true ? 'Déjà payée' : 'En attente de paiement'),
                      if (_invoiceDetails!['description'] != null && _invoiceDetails!['description'].isNotEmpty)
                        _detailRow('Description', _invoiceDetails!['description']),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
                if (_invoiceDetails!['payee'] == true)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      border: Border.all(color: Colors.green),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green.shade700),
                        const SizedBox(width: 8),
                        Text(
                          'Cette facture a déjà été payée',
                          style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  )
                else
                  ElevatedButton(
                    onPressed: _isLoading ? null : _payInvoice,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.green,
                    ),
                    child: _isLoading
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              ),
                              SizedBox(width: 8),
                              Text('Paiement en cours...', style: TextStyle(color: Colors.white)),
                            ],
                          )
                        : const Text(
                            'Payer cette facture',
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                  ),
              ],
              
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
              
              const SizedBox(height: 16),
              const Text(
                '⚠️ Assurez-vous d\'avoir suffisamment d\'USDC et d\'avoir approuvé le contrat avant de payer.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}
