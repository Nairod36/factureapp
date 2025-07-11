import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/app_config.dart';
import '../models/user.dart';
import 'invoice_list_screen.dart';
import 'profile_screen.dart';
import 'transaction_history_screen.dart';
import 'pay_invoice_search_screen.dart';

class HomeScreen extends StatefulWidget {
  final User user;

  const HomeScreen({Key? key, required this.user}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic>? _stats;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Charger les statistiques (simulation)
      await Future.delayed(const Duration(seconds: 1));
      
      // En production, faire des appels API réels
      final response = await http.get(
        Uri.parse('${AppConfig.apiBaseUrl}/api/invoice/merchant/${widget.user.ethereumAddress}'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final invoices = List<Map<String, dynamic>>.from(data['invoices'] ?? []);
        
        // Calculer les statistiques
        int totalInvoices = invoices.length;
        int paidInvoices = invoices.where((inv) => inv['payee'] == true).length;
        int pendingInvoices = totalInvoices - paidInvoices;
        double totalAmount = invoices.fold(0.0, (sum, inv) => sum + double.parse(inv['montant'] ?? '0'));
        double paidAmount = invoices
            .where((inv) => inv['payee'] == true)
            .fold(0.0, (sum, inv) => sum + double.parse(inv['montant'] ?? '0'));

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
      } else {
        // Statistiques par défaut si pas de connexion
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
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur de chargement: $e';
        _stats = {
          'totalInvoices': 0,
          'paidInvoices': 0,
          'pendingInvoices': 0,
          'totalAmount': 0.0,
          'paidAmount': 0.0,
          'pendingAmount': 0.0,
        };
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
      appBar: AppBar(
        title: Text('Accueil - ${AppConfig.appName}'),
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
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadStats,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête de bienvenue
              _buildWelcomeCard(),
              const SizedBox(height: 20),
              
              // Statistiques
              _buildStatsSection(),
              const SizedBox(height: 20),
              
              // Actions rapides
              _buildQuickActions(),
              const SizedBox(height: 20),
              
              // Activité récente
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
          colors: [Colors.blue.shade400, Colors.blue.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bonjour ${AppConfig.userName ?? "Utilisateur"} 👋',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Wallet: ${AppConfig.formatAddress(widget.user.ethereumAddress ?? 'N/A')}',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Réseau: ${AppConfig.networkName}',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_errorMessage != null) {
      return Container(
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
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Aperçu de vos factures',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Total',
                '${_stats!['totalInvoices']}',
                'factures',
                Icons.receipt_long,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Payées',
                '${_stats!['paidInvoices']}',
                'factures',
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
                '${_stats!['pendingInvoices']}',
                'factures',
                Icons.pending,
                Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Revenus',
                '${AppConfig.formatAmount(_stats!['paidAmount'])}',
                'USDC',
                Icons.attach_money,
                Colors.green,
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
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 5,
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
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade500,
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
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: [
            _buildActionCard(
              'Créer une facture',
              Icons.add_circle,
              Colors.blue,
              () => Navigator.pushNamed(context, '/create-invoice', arguments: widget.user),
            ),
            _buildActionCard(
              'Mes factures',
              Icons.list_alt,
              Colors.green,
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
            _buildActionCard(
              'Payer une facture',
              Icons.payment,
              Colors.orange,
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PayInvoiceSearchScreen(
                    userAddress: widget.user.ethereumAddress ?? '',
                  ),
                ),
              ),
            ),
            _buildActionCard(
              'Historique',
              Icons.history,
              Colors.purple,
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TransactionHistoryScreen(
                    userAddress: widget.user.ethereumAddress ?? '',
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
          mainAxisAlignment: MainAxisAlignment.center,
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
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TransactionHistoryScreen(
                    userAddress: widget.user.ethereumAddress ?? '',
                  ),
                ),
              ),
              child: const Text('Voir tout'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(
            child: Text(
              'Aucune activité récente',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
