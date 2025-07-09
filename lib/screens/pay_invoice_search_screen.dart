import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/app_config.dart';
import 'pay_invoice_screen.dart';

class PayInvoiceSearchScreen extends StatefulWidget {
  final String userAddress;

  const PayInvoiceSearchScreen({
    Key? key,
    required this.userAddress,
  }) : super(key: key);

  @override
  _PayInvoiceSearchScreenState createState() => _PayInvoiceSearchScreenState();
}

class _PayInvoiceSearchScreenState extends State<PayInvoiceSearchScreen> {
  final _invoiceIdController = TextEditingController();
  bool isLoading = false;
  String errorMessage = '';

  Future<void> _searchAndPayInvoice() async {
    if (_invoiceIdController.text.trim().isEmpty) {
      setState(() {
        errorMessage = 'Veuillez entrer un ID de facture';
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final response = await http.get(
        Uri.parse('${AppConfig.apiBaseUrl}/api/invoices/status/${_invoiceIdController.text.trim()}'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final invoice = data['invoice'];
        
        if (invoice['status'] == 0) { // Only unpaid invoices
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => PayInvoiceScreen(
                invoiceId: _invoiceIdController.text.trim(),
                amount: invoice['amount'] ?? '0',
                description: invoice['description'] ?? '',
                userAddress: widget.userAddress,
              ),
            ),
          );
        } else {
          setState(() {
            errorMessage = 'Cette facture a déjà été payée ou annulée';
          });
        }
      } else {
        setState(() {
          errorMessage = 'Facture introuvable';
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Erreur de connexion: $e';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payer une facture'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.search, color: Colors.blue),
                        const SizedBox(width: 8),
                        Text(
                          'Rechercher une facture',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _invoiceIdController,
                      decoration: const InputDecoration(
                        labelText: 'ID de la facture',
                        hintText: 'Entrez l\'ID de la facture à payer',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.receipt),
                      ),
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.search,
                      onSubmitted: (_) => _searchAndPayInvoice(),
                    ),
                    if (errorMessage.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red[200]!),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error, color: Colors.red),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                errorMessage,
                                style: const TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isLoading ? null : _searchAndPayInvoice,
                icon: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.search),
                label: Text(
                  isLoading ? 'Recherche...' : 'Rechercher et payer',
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  textStyle: const TextStyle(fontSize: 16),
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue),
                        const SizedBox(width: 8),
                        Text(
                          'Comment payer une facture',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '1. Obtenez l\'ID de la facture du marchand',
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '2. Entrez l\'ID dans le champ ci-dessus',
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '3. Cliquez sur "Rechercher et payer"',
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '4. Confirmez le paiement avec votre portefeuille',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  @override
  void dispose() {
    _invoiceIdController.dispose();
    super.dispose();
  }
}
