import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/app_config.dart';

class TransactionHistoryScreen extends StatefulWidget {
  final String userAddress;

  const TransactionHistoryScreen({
    Key? key,
    required this.userAddress,
  }) : super(key: key);

  @override
  _TransactionHistoryScreenState createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  List<Map<String, dynamic>> transactions = [];
  bool isLoading = true;
  String errorMessage = '';
  String filter = 'all'; // 'all', 'sent', 'received'

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      // Charger les factures émises (sent)
      final merchantResponse = await http.get(
        Uri.parse('${AppConfig.apiBaseUrl}/api/invoices/merchant/${widget.userAddress}'),
        headers: {'Content-Type': 'application/json'},
      );

      // Charger les factures reçues (received)
      final clientResponse = await http.get(
        Uri.parse('${AppConfig.apiBaseUrl}/api/invoices/client/${widget.userAddress}'),
        headers: {'Content-Type': 'application/json'},
      );

      List<Map<String, dynamic>> allTransactions = [];

      if (merchantResponse.statusCode == 200) {
        final merchantData = json.decode(merchantResponse.body);
        final merchantInvoices = List<Map<String, dynamic>>.from(merchantData['invoices'] ?? []);
        
        for (var invoice in merchantInvoices) {
          if (invoice['status'] == 1) { // Only paid invoices
            allTransactions.add({
              ...invoice,
              'type': 'received', // Received payment
              'timestamp': DateTime.now().millisecondsSinceEpoch, // Mock timestamp
            });
          }
        }
      }

      if (clientResponse.statusCode == 200) {
        final clientData = json.decode(clientResponse.body);
        final clientInvoices = List<Map<String, dynamic>>.from(clientData['invoices'] ?? []);
        
        for (var invoice in clientInvoices) {
          if (invoice['status'] == 1) { // Only paid invoices
            allTransactions.add({
              ...invoice,
              'type': 'sent', // Sent payment
              'timestamp': DateTime.now().millisecondsSinceEpoch, // Mock timestamp
            });
          }
        }
      }

      // Trier par timestamp (plus récent d'abord)
      allTransactions.sort((a, b) => b['timestamp'].compareTo(a['timestamp']));

      setState(() {
        transactions = allTransactions;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Erreur de connexion: $e';
        isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> get filteredTransactions {
    if (filter == 'all') return transactions;
    return transactions.where((tx) => tx['type'] == filter).toList();
  }

  String _formatAddress(String address) {
    if (address.length > 10) {
      return '${address.substring(0, 6)}...${address.substring(address.length - 4)}';
    }
    return address;
  }

  String _formatDate(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historique des transactions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTransactions,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Tabs
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: SegmentedButton<String>(
                    segments: const [
                      ButtonSegment<String>(
                        value: 'all',
                        label: Text('Toutes'),
                        icon: Icon(Icons.all_inclusive),
                      ),
                      ButtonSegment<String>(
                        value: 'received',
                        label: Text('Reçues'),
                        icon: Icon(Icons.call_received),
                      ),
                      ButtonSegment<String>(
                        value: 'sent',
                        label: Text('Envoyées'),
                        icon: Icon(Icons.call_made),
                      ),
                    ],
                    selected: {filter},
                    onSelectionChanged: (Set<String> selection) {
                      setState(() {
                        filter = selection.first;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          
          // Transaction List
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : errorMessage.isNotEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline, size: 64, color: Colors.red),
                            const SizedBox(height: 16),
                            Text(
                              errorMessage,
                              style: const TextStyle(fontSize: 16, color: Colors.red),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadTransactions,
                              child: const Text('Réessayer'),
                            ),
                          ],
                        ),
                      )
                    : filteredTransactions.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.history, size: 64, color: Colors.grey),
                                const SizedBox(height: 16),
                                Text(
                                  'Aucune transaction trouvée',
                                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Vos transactions payées apparaîtront ici',
                                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadTransactions,
                            child: ListView.builder(
                              itemCount: filteredTransactions.length,
                              itemBuilder: (context, index) {
                                final transaction = filteredTransactions[index];
                                final isReceived = transaction['type'] == 'received';
                                final amount = transaction['amount'] ?? '0';
                                final description = transaction['description'] ?? '';
                                final invoiceId = transaction['invoiceId']?.toString() ?? '';
                                final otherParty = isReceived 
                                    ? transaction['client'] ?? ''
                                    : transaction['merchant'] ?? '';

                                return Card(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 4,
                                  ),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: isReceived ? Colors.green : Colors.blue,
                                      child: Icon(
                                        isReceived ? Icons.call_received : Icons.call_made,
                                        color: Colors.white,
                                      ),
                                    ),
                                    title: Text(
                                      isReceived ? 'Paiement reçu' : 'Paiement envoyé',
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Facture #$invoiceId',
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                        Text(
                                          description.length > 30
                                              ? '${description.substring(0, 30)}...'
                                              : description,
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                        Text(
                                          '${isReceived ? 'De' : 'À'}: ${_formatAddress(otherParty)}',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey[600],
                                            fontFamily: 'monospace',
                                          ),
                                        ),
                                        Text(
                                          _formatDate(transaction['timestamp']),
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey[500],
                                          ),
                                        ),
                                      ],
                                    ),
                                    trailing: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          '${isReceived ? '+' : '-'}${double.parse(amount).toStringAsFixed(2)}',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: isReceived ? Colors.green : Colors.red,
                                          ),
                                        ),
                                        Text(
                                          'USDC',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                    onTap: () {
                                      // TODO: Show transaction details
                                      showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: Text('Transaction #$invoiceId'),
                                          content: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text('Type: ${isReceived ? 'Paiement reçu' : 'Paiement envoyé'}'),
                                              Text('Montant: ${double.parse(amount).toStringAsFixed(2)} USDC'),
                                              Text('Description: $description'),
                                              Text('${isReceived ? 'De' : 'À'}: ${_formatAddress(otherParty)}'),
                                              Text('Date: ${_formatDate(transaction['timestamp'])}'),
                                            ],
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(context),
                                              child: const Text('Fermer'),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}
