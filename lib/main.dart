import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'dart:io';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppDatabaseService.instance.init();
  runApp(AppWithAuth());
}

class AuthService extends ChangeNotifier {
  String? _userEmail;
  String? get userEmail => _userEmail;
  bool get isLoggedIn => _userEmail != null;

  Future<bool> login(String email, String password) async {
    final ok = await AppDatabaseService.instance.loginUser(email, password);
    if (ok) {
      _userEmail = email;
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> register(String email, String password) async {
    final ok = await AppDatabaseService.instance.registerUser(email, password);
    if (ok) {
      _userEmail = email;
      notifyListeners();
      return true;
    }
    return false;
  }

  void logout() {
    _userEmail = null;
    notifyListeners();
  }
}

class AppWithAuth extends StatelessWidget {
  final AuthService authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Facture USDC',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: AuthGate(authService: authService),
    );
  }
}

class AuthGate extends StatefulWidget {
  final AuthService authService;
  AuthGate({required this.authService});
  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  void initState() {
    super.initState();
    widget.authService.addListener(_onAuthChanged);
  }
  @override
  void dispose() {
    widget.authService.removeListener(_onAuthChanged);
    super.dispose();
  }
  void _onAuthChanged() => setState(() {});
  @override
  Widget build(BuildContext context) {
    if (widget.authService.isLoggedIn) {
      return HomePage(authService: widget.authService);
    } else {
      return LoginPage(authService: widget.authService);
    }
  }
}

class LoginPage extends StatefulWidget {
  final AuthService authService;
  LoginPage({required this.authService});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  String email = '';
  String password = '';
  bool isLogin = true;
  String? error;

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      bool success = false;
      if (isLogin) {
        success = await widget.authService.login(email, password);
        if (!success) error = 'Identifiants invalides';
      } else {
        success = await widget.authService.register(email, password);
        if (!success) error = 'Email déjà utilisé';
      }
      if (success) setState(() => error = null);
      else setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(isLogin ? 'Connexion' : 'Créer un compte')),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(isLogin ? 'Connecte-toi à ton compte' : 'Crée un compte', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                SizedBox(height: 20),
                if (error != null) ...[
                  Text(error!, style: TextStyle(color: Colors.red)),
                  SizedBox(height: 10),
                ],
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      MainTextField(
                        label: 'Email',
                        onSaved: (val) => email = val ?? '',
                        validator: (val) => val != null && val.contains('@') ? null : 'Email invalide',
                      ),
                      MainTextField(
                        label: 'Mot de passe',
                        obscureText: true,
                        onSaved: (val) => password = val ?? '',
                        validator: (val) => val != null && val.length >= 4 ? null : 'Min 4 caractères',
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),
                MainButton(
                  label: isLogin ? 'Se connecter' : 'Créer le compte',
                  onPressed: _submit,
                  icon: isLogin ? Icons.login : Icons.person_add,
                ),
                TextButton(
                  onPressed: () => setState(() => isLogin = !isLogin),
                  child: Text(isLogin ? 'Créer un compte' : 'Déjà un compte ? Se connecter'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  final AuthService authService;
  HomePage({required this.authService});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Facture USDC'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            tooltip: 'Déconnexion',
            onPressed: () {
              authService.logout();
            },
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(Icons.receipt_long, size: 80, color: Colors.blue),
              SizedBox(height: 10),
              Text('Bienvenue, ${authService.userEmail ?? ''}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              SizedBox(height: 30),
              MainButton(
                label: 'Créer une facture',
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CreateInvoicePage(authService: authService))),
                icon: Icons.add,
              ),
              SizedBox(height: 10),
              MainButton(
                label: 'Voir les factures',
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => InvoiceListPage(authService: authService))),
                icon: Icons.list_alt,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CreateInvoicePage extends StatefulWidget {
  final AuthService authService;
  CreateInvoicePage({required this.authService});
  @override
  _CreateInvoicePageState createState() => _CreateInvoicePageState();
}

class _CreateInvoicePageState extends State<CreateInvoicePage> {
  final _formKey = GlobalKey<FormState>();
  String email = '';
  String description = '';
  String amount = '';
  String chain = 'Polygon';
  bool gasless = false;
  final List<String> chains = ['Polygon', 'Ethereum', 'Base', 'Avalanche'];

  @override
  Widget build(BuildContext context) {
    final authService = widget.authService;
    return Scaffold(
      appBar: AppBar(title: Text('Créer une facture')),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  MainTextField(
                    label: 'Email du destinataire',
                    onSaved: (val) => email = val ?? '',
                    validator: (val) => val != null && val.contains('@') ? null : 'Email invalide',
                  ),
                  MainTextField(
                    label: 'Description',
                    onSaved: (val) => description = val ?? '',
                  ),
                  MainTextField(
                    label: 'Montant (USDC)',
                    onSaved: (val) => amount = val ?? '',
                    validator: (val) => val != null && double.tryParse(val) != null ? null : 'Montant invalide',
                  ),
                  SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: chain,
                    items: chains.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                    onChanged: (val) => setState(() => chain = val ?? 'Polygon'),
                    decoration: InputDecoration(
                      labelText: 'Chaîne cible',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  SizedBox(height: 12),
                  CheckboxListTile(
                    value: gasless,
                    onChanged: (val) => setState(() => gasless = val ?? false),
                    title: Text('Paiement gasless (Circle Paymaster)'),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                  SizedBox(height: 24),
                  MainButton(
                    label: 'Générer la facture',
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        _formKey.currentState!.save();
                        await AppDatabaseService.instance.addInvoice(
                          authService.userEmail!, email, description, amount);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => InvoiceDetailPage(
                              email: email,
                              description: description,
                              amount: amount,
                              chain: chain,
                              gasless: gasless,
                            ),
                          ),
                        );
                      }
                    },
                    icon: Icons.qr_code,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class InvoiceListPage extends StatefulWidget {
  final AuthService authService;
  InvoiceListPage({required this.authService});
  @override
  State<InvoiceListPage> createState() => _InvoiceListPageState();
}

class _InvoiceListPageState extends State<InvoiceListPage> {
  List<Map<String, dynamic>> invoices = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadInvoices();
  }

  Future<void> _loadInvoices() async {
    final authService = widget.authService;
    final data = await AppDatabaseService.instance.getInvoices(authService.userEmail!);
    setState(() {
      invoices = data;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Factures générées')),
      body: loading
          ? Center(child: CircularProgressIndicator())
          : invoices.isEmpty
              ? Center(child: Text('Aucune facture enregistrée'))
              : Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
                  child: ListView.builder(
                    itemCount: invoices.length,
                    itemBuilder: (context, index) {
                      final invoice = invoices[index];
                      return Card(
                        margin: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 2,
                        child: ListTile(
                          leading: Icon(Icons.receipt, color: Colors.blue),
                          title: Text('${invoice['description']} - ${invoice['amount']} USDC', style: TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(invoice['client_email'] ?? ''),
                          trailing: Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => InvoiceDetailPage(
                                  email: invoice['client_email'],
                                  description: invoice['description'],
                                  amount: invoice['amount'],
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

class InvoiceDetailPage extends StatelessWidget {
  final String email;
  final String description;
  final String amount;
  final String chain;
  final bool gasless;

  InvoiceDetailPage({required this.email, required this.description, required this.amount, this.chain = 'Polygon', this.gasless = false});

  @override
  Widget build(BuildContext context) {
    final usdcAddress = '0x1234567890abcdef1234567890abcdef12345678';
    final invoiceId = DateTime.now().millisecondsSinceEpoch.toString();
    final qrData = {
      'type': 'usdc_invoice',
      'amount': amount,
      'currency': 'USDC',
      'chain': chain,
      'merchant_address': usdcAddress,
      'gasless': gasless,
      'invoice_id': invoiceId,
      'client_email': email,
      'description': description,
    };
    return Scaffold(
      appBar: AppBar(title: Text('Détail de la facture')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text('Destinataire : $email', style: TextStyle(fontSize: 16)),
              Text('Description : $description', style: TextStyle(fontSize: 16)),
              Text('Montant : $amount USDC', style: TextStyle(fontSize: 16)),
              Text('Chaîne : $chain', style: TextStyle(fontSize: 16)),
              Text('Gasless : ${gasless ? "Oui" : "Non"}', style: TextStyle(fontSize: 16)),
              SizedBox(height: 30),
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text('Payer en crypto', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      SizedBox(height: 10),
                      QrImageView(
                        data: qrData.toString(),
                        size: 200,
                      ),
                      SizedBox(height: 10),
                      SelectableText('Adresse USDC :\n$usdcAddress', textAlign: TextAlign.center),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Service de base de données pour utilisateurs et factures
class DatabaseService {
  static Database? _db;
  static final DatabaseService instance = DatabaseService._();
  DatabaseService._();

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  Future<Database> _initDB() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = p.join(documentsDirectory.path, 'factureapp.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            email TEXT UNIQUE,
            password TEXT
          );
        ''');
        await db.execute('''
          CREATE TABLE invoices (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_email TEXT,
            client_email TEXT,
            description TEXT,
            amount TEXT
          );
        ''');
      },
    );
  }

  // Utilisateur
  Future<bool> registerUser(String email, String password) async {
    final db = await database;
    try {
      await db.insert('users', {'email': email, 'password': password});
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> loginUser(String email, String password) async {
    final db = await database;
    final res = await db.query('users', where: 'email = ? AND password = ?', whereArgs: [email, password]);
    return res.isNotEmpty;
  }

  // Factures
  Future<void> addInvoice(String userEmail, String clientEmail, String description, String amount) async {
    final db = await database;
    await db.insert('invoices', {
      'user_email': userEmail,
      'client_email': clientEmail,
      'description': description,
      'amount': amount,
    });
  }

  Future<List<Map<String, dynamic>>> getInvoices(String userEmail) async {
    final db = await database;
    return await db.query('invoices', where: 'user_email = ?', whereArgs: [userEmail]);
  }
}

// Service de base de données multiplateforme (mobile: sqflite, web: hive)
class AppDatabaseService {
  static final AppDatabaseService instance = AppDatabaseService._();
  AppDatabaseService._();

  Future<void> init() async {
    if (kIsWeb) {
      await Hive.initFlutter();
      await Hive.openBox('users');
      await Hive.openBox('invoices');
    } else {
      // sqflite déjà initialisé par DatabaseService
    }
  }

  // Utilisateur
  Future<bool> registerUser(String email, String password) async {
    if (kIsWeb) {
      final box = Hive.box('users');
      if (box.containsKey(email)) return false;
      await box.put(email, password);
      return true;
    } else {
      return await DatabaseService.instance.registerUser(email, password);
    }
  }

  Future<bool> loginUser(String email, String password) async {
    if (kIsWeb) {
      final box = Hive.box('users');
      return box.get(email) == password;
    } else {
      return await DatabaseService.instance.loginUser(email, password);
    }
  }

  // Factures
  Future<void> addInvoice(String userEmail, String clientEmail, String description, String amount) async {
    if (kIsWeb) {
      final box = Hive.box('invoices');
      final invoices = box.get(userEmail, defaultValue: <Map<String, dynamic>>[]).cast<Map<String, dynamic>>();
      invoices.add({
        'client_email': clientEmail,
        'description': description,
        'amount': amount,
      });
      await box.put(userEmail, invoices);
    } else {
      await DatabaseService.instance.addInvoice(userEmail, clientEmail, description, amount);
    }
  }

  Future<List<Map<String, dynamic>>> getInvoices(String userEmail) async {
    if (kIsWeb) {
      final box = Hive.box('invoices');
      final invoices = box.get(userEmail, defaultValue: <Map<String, dynamic>>[]).cast<Map<String, dynamic>>();
      return List<Map<String, dynamic>>.from(invoices);
    } else {
      return await DatabaseService.instance.getInvoices(userEmail);
    }
  }
}

// Widget réutilisable pour les boutons principaux
class MainButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
  const MainButton({required this.label, required this.onPressed, this.icon, super.key});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: icon != null ? Icon(icon) : SizedBox.shrink(),
        label: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14.0),
          child: Text(label, style: TextStyle(fontSize: 18)),
        ),
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}

// Widget réutilisable pour les champs de formulaire
class MainTextField extends StatelessWidget {
  final String label;
  final bool obscureText;
  final FormFieldSetter<String>? onSaved;
  final FormFieldValidator<String>? validator;
  const MainTextField({required this.label, this.obscureText = false, this.onSaved, this.validator, super.key});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        obscureText: obscureText,
        onSaved: onSaved,
        validator: validator,
      ),
    );
  }
}
