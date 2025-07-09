import 'package:flutter/material.dart';
import 'widgets/create_invoice_widget.dart';
import 'widgets/invoice_list_widget.dart';
import 'widgets/pay_invoice_widget.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Facture USDC',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: InvoiceHomePage(),
    );
  }
}

class InvoiceHomePage extends StatefulWidget {
  @override
  _InvoiceHomePageState createState() => _InvoiceHomePageState();
}

class _InvoiceHomePageState extends State<InvoiceHomePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Configuration API - À adapter selon votre environnement
  final String apiBaseUrl = 'http://localhost:3000'; // Backend Node.js
  final String userAddress = '0x742d35Cc6635C0532925a3b8D56c9E6eA22D9c08'; // Adresse exemple
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Facture USDC'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.add), text: 'Créer'),
            Tab(icon: Icon(Icons.list), text: 'Mes factures'),
            Tab(icon: Icon(Icons.payment), text: 'Payer'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Onglet Créer une facture
          SingleChildScrollView(
            child: CreateInvoiceWidget(apiBaseUrl: apiBaseUrl),
          ),
          
          // Onglet Mes factures
          SingleChildScrollView(
            child: InvoiceListWidget(
              apiBaseUrl: apiBaseUrl,
              userAddress: userAddress,
            ),
          ),
          
          // Onglet Payer une facture
          SingleChildScrollView(
            child: PayInvoiceWidget(apiBaseUrl: apiBaseUrl),
          ),
        ],
      ),
    );
  }
}
