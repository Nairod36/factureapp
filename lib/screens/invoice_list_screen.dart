import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/user.dart';
import '../models/invoice.dart';

class InvoiceListScreen extends StatefulWidget {
  final User user;
  final String userType; // 'merchant' ou 'client'

  const InvoiceListScreen({
    Key? key,
    required this.user,
    required this.userType,
  }) : super(key: key);

  @override
  _InvoiceListScreenState createState() => _InvoiceListScreenState();
}

class _InvoiceListScreenState extends State<InvoiceListScreen> {
  List<Invoice> _invoices = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _currentFilter = 'all'; // 'all', 'paid', 'pending'

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
      List<Invoice> invoices;
      if (widget.userType == 'merchant') {
        invoices = await ApiService.getInvoicesByMerchant(widget.user.identifier);
      } else {
        invoices = await ApiService.getInvoicesByClient(widget.user.identifier);
      }

      setState(() {
        _invoices = invoices;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur de chargement: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<Invoice> get _filteredInvoices {
    switch (_currentFilter) {
      case 'paid':
        return _invoices.where((invoice) => invoice.isPaid).toList();
      case 'pending':
        return _invoices.where((invoice) => !invoice.isPaid).toList();
      default:
        return _invoices;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.userType == 'merchant' ? 'Mes factures' : 'Factures reçues'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadInvoices,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterTabs(),
          Expanded(
            child: _buildInvoiceList(),
          ),
        ],
      ),
      floatingActionButton: widget.userType == 'merchant'
          ? FloatingActionButton(
              onPressed: () => Navigator.pushNamed(
                context,
                '/create-invoice',
                arguments: widget.user,
              ),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildFilterTabs() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildFilterTab('all', 'Toutes', _invoices.length),
          ),
          Expanded(
            child: _buildFilterTab(
              'paid',
              'Payées',
              _invoices.where((inv) => inv.isPaid).length,
            ),
          ),
          Expanded(
            child: _buildFilterTab(
              'pending',
              'En attente',
              _invoices.where((inv) => !inv.isPaid).length,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTab(String filter, String label, int count) {
    final isSelected = _currentFilter == filter;
    return GestureDetector(
      onTap: () => setState(() => _currentFilter = filter),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : Colors.grey[700],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : Colors.blue,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInvoiceList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadInvoices,
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    final filteredInvoices = _filteredInvoices;

    if (filteredInvoices.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadInvoices,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filteredInvoices.length,
        itemBuilder: (context, index) {
          return _buildInvoiceCard(filteredInvoices[index]);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    String message;
    String description;
    IconData icon;

    switch (_currentFilter) {
      case 'paid':
        message = 'Aucune facture payée';
        description = 'Les factures payées apparaîtront ici';
        icon = Icons.check_circle;
        break;
      case 'pending':
        message = 'Aucune facture en attente';
        description = 'Les factures en attente de paiement apparaîtront ici';
        icon = Icons.pending;
        break;
      default:
        message = widget.userType == 'merchant'
            ? 'Aucune facture créée'
            : 'Aucune facture reçue';
        description = widget.userType == 'merchant'
            ? 'Commencez par créer votre première facture'
            : 'Les factures qui vous sont adressées apparaîtront ici';
        icon = Icons.receipt_long;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          if (widget.userType == 'merchant' && _currentFilter == 'all') ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(
                context,
                '/create-invoice',
                arguments: widget.user,
              ),
              icon: const Icon(Icons.add),
              label: const Text('Créer une facture'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInvoiceCard(Invoice invoice) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => {
          // TODO: Navigation vers l'écran de détail
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Détail de la facture ${invoice.shortId}'),
            ),
          )
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    invoice.shortId,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  _buildStatusChip(invoice.isPaid),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                invoice.description,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.userType == 'merchant' ? 'Client' : 'Marchand',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                        Tooltip(
                          message: widget.userType == 'merchant'
                              ? invoice.client
                              : invoice.merchant,
                          child: Text(
                            _shortenAddress(widget.userType == 'merchant'
                                ? invoice.client
                                : invoice.merchant),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Montant',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                        Text(
                          invoice.formattedAmount,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Créé le ${_formatDate(invoice.createdAt)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                  ),
                  if (invoice.isPaid && invoice.paidAt != null)
                    Text(
                      'Payé le ${_formatDate(invoice.paidAt!)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
              // Bouton de paiement pour les clients
              if (widget.userType == 'client' && !invoice.isPaid) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _payInvoice(invoice),
                    icon: const Icon(Icons.payment, size: 18),
                    label: const Text('Payer cette facture'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
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

  Widget _buildStatusChip(bool isPaid) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isPaid ? Colors.green[100] : Colors.orange[100],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPaid ? Icons.check_circle : Icons.pending,
            size: 16,
            color: isPaid ? Colors.green[700] : Colors.orange[700],
          ),
          const SizedBox(width: 4),
          Text(
            isPaid ? 'Payée' : 'En attente',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isPaid ? Colors.green[700] : Colors.orange[700],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _shortenAddress(String address) {
    if (address.length <= 10) return address;
    return '${address.substring(0, 6)}...${address.substring(address.length - 4)}';
  }

  Future<void> _payInvoice(Invoice invoice) async {
    // Afficher une boîte de dialogue de confirmation
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Payer la facture ${invoice.shortId}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Montant: ${invoice.formattedAmount}'),
              const SizedBox(height: 8),
              Text('Description: ${invoice.description}'),
              const SizedBox(height: 16),
              const Text(
                'Êtes-vous sûr de vouloir payer cette facture ?',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Payer'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    // Afficher un indicateur de chargement
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const AlertDialog(
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Traitement du paiement...'),
            ],
          ),
        );
      },
    );

    try {
      // Mettre à jour le statut de la facture à "paid"
      await ApiService.updateInvoice(
        invoiceId: invoice.id,
        status: 'paid',
        paidAt: DateTime.now().toIso8601String(),
        transactionHash: 'fake_tx_${DateTime.now().millisecondsSinceEpoch}', // Simulation
      );

      if (!mounted) return;
      Navigator.of(context).pop(); // Fermer le dialogue de chargement

      // Afficher un message de succès
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Facture ${invoice.shortId} payée avec succès !'),
          backgroundColor: Colors.green,
          action: SnackBarAction(
            label: 'OK',
            textColor: Colors.white,
            onPressed: () {},
          ),
        ),
      );

      // Recharger la liste des factures
      await _loadInvoices();
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop(); // Fermer le dialogue de chargement

      // Afficher un message d'erreur
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors du paiement: $e'),
          backgroundColor: Colors.red,
          action: SnackBarAction(
            label: 'Réessayer',
            textColor: Colors.white,
            onPressed: () => _payInvoice(invoice),
          ),
        ),
      );
    }
  }
}
