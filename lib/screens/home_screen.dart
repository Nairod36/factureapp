import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../models/user.dart';
import '../models/invoice.dart';
import 'invoice_list_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  final User user;

  const HomeScreen({Key? key, required this.user}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic>? _stats;
  List<Invoice> _recentInvoices = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await Future.wait([
        _loadStats(),
        _loadRecentInvoices(),
      ]);
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

  Future<void> _loadStats() async {
    try {
      // Charger les factures du marchand pour calculer les statistiques
      final invoices = await ApiService.getInvoicesByMerchant(widget.user.identifier);
      
      int totalInvoices = invoices.length;
      int paidInvoices = invoices.where((inv) => inv.isPaid).length;
      int pendingInvoices = totalInvoices - paidInvoices;
      double totalAmount = invoices.fold(0.0, (sum, inv) => sum + inv.amount);
      double paidAmount = invoices
          .where((inv) => inv.isPaid)
          .fold(0.0, (sum, inv) => sum + inv.amount);

      setState(() {
        _stats = {
          'totalInvoices': totalInvoices,
          'paidInvoices': paidInvoices,
          'pendingInvoices': pendingInvoices,
          'totalAmount': totalAmount,
          'paidAmount': paidAmount,
          'pendingAmount': totalAmount - paidAmount,
        };
      });
    } catch (e) {
      // Statistiques par défaut en cas d'erreur
      setState(() {
        _stats = {
          'totalInvoices': 0,
          'paidInvoices': 0,
          'pendingInvoices': 0,
          'totalAmount': 0.0,
          'paidAmount': 0.0,
          'pendingAmount': 0.0,
        };
      });
    }
  }

  Future<void> _loadRecentInvoices() async {
    try {
      final invoices = await ApiService.getInvoicesByMerchant(widget.user.identifier);
      // Prendre les 5 dernières factures
      final recent = invoices.take(5).toList();
      setState(() {
        _recentInvoices = recent;
      });
    } catch (e) {
      setState(() {
        _recentInvoices = [];
      });
    }
  }

  void _logout() {
    Provider.of<UserState>(context, listen: false).logout();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tableau de bord'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProfileScreen(user: widget.user),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
                ? Center(
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
                          onPressed: _loadData,
                          child: const Text('Réessayer'),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildWelcomeCard(),
                        const SizedBox(height: 20),
                        _buildStatsSection(),
                        const SizedBox(height: 20),
                        _buildQuickActions(),
                        const SizedBox(height: 20),
                        _buildRecentActivity(),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[600]!, Colors.blue[400]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bonjour ${widget.user.displayName} 👋',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Bienvenue sur votre tableau de bord',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'ID: ${widget.user.identifier}',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.8),
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    if (_stats == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Statistiques',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Total',
                _stats!['totalInvoices'].toString(),
                'Factures',
                Icons.receipt_long,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Payées',
                _stats!['paidInvoices'].toString(),
                'Factures',
                Icons.check_circle,
                Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'En attente',
                _stats!['pendingInvoices'].toString(),
                'Factures',
                Icons.pending,
                Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Total',
                '${_stats!['totalAmount'].toStringAsFixed(2)}',
                'USDC',
                Icons.account_balance_wallet,
                Colors.purple,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, String subtitle, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Actions rapides',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                'Créer une facture',
                Icons.add,
                Colors.green,
                () => Navigator.pushNamed(context, '/create-invoice', arguments: widget.user),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                'Mes factures',
                Icons.list,
                Colors.blue,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => InvoiceListScreen(
                      user: widget.user,
                      userType: 'merchant',
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                'À payer',
                Icons.payment,
                Colors.orange,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => InvoiceListScreen(
                      user: widget.user,
                      userType: 'client',
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                'Mon profil',
                Icons.person,
                Colors.purple,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProfileScreen(user: widget.user),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Activité récente',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => InvoiceListScreen(
                    user: widget.user,
                    userType: 'merchant',
                  ),
                ),
              ),
              child: const Text('Voir tout'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_recentInvoices.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Column(
              children: [
                Icon(Icons.receipt_long, size: 48, color: Colors.grey[400]),
                const SizedBox(height: 12),
                Text(
                  'Aucune facture récente',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Commencez par créer votre première facture',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          )
        else
          ...(_recentInvoices.map((invoice) => _buildInvoiceCard(invoice)).toList()),
      ],
    );
  }

  Widget _buildInvoiceCard(Invoice invoice) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: invoice.isPaid ? Colors.green[100] : Colors.orange[100],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              invoice.isPaid ? Icons.check_circle : Icons.pending,
              color: invoice.isPaid ? Colors.green : Colors.orange,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  invoice.shortId,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  invoice.description.isNotEmpty 
                      ? invoice.description 
                      : 'Facture',
                  style: TextStyle(
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  'Client: ${invoice.client}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                invoice.formattedAmount,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                invoice.statusText,
                style: TextStyle(
                  fontSize: 12,
                  color: invoice.isPaid ? Colors.green : Colors.orange,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
