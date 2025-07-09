import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class InvoiceListWidget extends StatefulWidget {
  final String apiBaseUrl;
  final String userAddress;

  const InvoiceListWidget({
    Key? key,
    required this.apiBaseUrl,
    required this.userAddress,
  }) : super(key: key);

  @override
  _InvoiceListWidgetState createState() => _InvoiceListWidgetState();
}

class _InvoiceListWidgetState extends State<InvoiceListWidget> {
  List<Map<String, dynamic>> _invoices = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadInvoices();
  }

  Future<void> _loadInvoices() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await http.get(
        Uri.parse('${widget.apiBaseUrl}/api/invoice/merchant/${widget.userAddress}'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _invoices = List<Map<String, dynamic>>.from(data['invoices'] ?? []);
        });
      } else {
        final data = jsonDecode(response.body);
        setState(() {
          _errorMessage = data['error'] ?? 'Erreur lors du chargement';
        });
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

  Future<void> _refreshInvoices() async {
    await _loadInvoices();
  }

  String _formatDate(String timestamp) {
    try {
      final date = DateTime.fromMillisecondsSinceEpoch(int.parse(timestamp) * 1000);
      return '${date.day}/${date.month}/${date.year}';
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Mes factures',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: _isLoading ? null : _refreshInvoices,
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Actualiser',
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  border: Border.all(color: Colors.red),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(color: Colors.red.shade700),
                ),
              )
            else if (_invoices.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Text(
                    'Aucune facture trouvée',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _invoices.length,
                itemBuilder: (context, index) {
                  final invoice = _invoices[index];
                  final isPaid = invoice['payee'] == true;
                  
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isPaid ? Colors.green : Colors.orange,
                        child: Icon(
                          isPaid ? Icons.check : Icons.access_time,
                          color: Colors.white,
                        ),
                      ),
                      title: Text(
                        'Facture #${invoice['id'] ?? 'N/A'}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Client: ${_truncateAddress(invoice['client'] ?? '')}'),
                          Text('Montant: ${invoice['montant'] ?? '0'} USDC'),
                          Text('Date: ${_formatDate(invoice['dateCreation'] ?? '0')}'),
                          if (invoice['description'] != null && invoice['description'].isNotEmpty)
                            Text('Description: ${invoice['description']}'),
                        ],
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isPaid ? Colors.green : Colors.orange,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          isPaid ? 'Payée' : 'En attente',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      onTap: () {
                        _showInvoiceDetails(context, invoice);
                      },
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showInvoiceDetails(BuildContext context, Map<String, dynamic> invoice) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Facture #${invoice['id']}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _detailRow('Client', invoice['client'] ?? 'N/A'),
              _detailRow('Montant', '${invoice['montant'] ?? '0'} USDC'),
              _detailRow('Date de création', _formatDate(invoice['dateCreation'] ?? '0')),
              _detailRow('Statut', invoice['payee'] == true ? 'Payée' : 'En attente'),
              if (invoice['description'] != null && invoice['description'].isNotEmpty)
                _detailRow('Description', invoice['description']),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Fermer'),
            ),
          ],
        );
      },
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
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
