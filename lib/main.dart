import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

String? jwtToken;

Future<bool> loginApi(String email, String password) async {
  final res = await http.post(
    Uri.parse('http://localhost:3000/api/login'), // Correction du chemin
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'email': email, 'password': password}),
  );
  if (res.statusCode == 200) {
    jwtToken = jsonDecode(res.body)['token'];
    return true;
  }
  return false;
}

Future<bool> registerApi(String email, String password) async {
  final res = await http.post(
    Uri.parse('http://localhost:3000/api/register'), // Correction du chemin
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'email': email, 'password': password}),
  );
  return res.statusCode == 200;
}

Future<bool> addInvoiceApi(String userEmail, String clientEmail, String description, String amount, {bool gasless = false}) async {
  final res = await http.post(
    Uri.parse('http://localhost:3000/api/invoices'), // Correction du chemin
    headers: {
      'Content-Type': 'application/json',
      if (jwtToken != null) 'Authorization': 'Bearer $jwtToken',
    },
    body: jsonEncode({
      'user_email': userEmail,
      'client_email': clientEmail,
      'description': description,
      'amount': amount,
      'gasless': gasless,
    }),
  );
  return res.statusCode == 200 || res.statusCode == 201;
}

Future<List<Map<String, dynamic>>> getInvoicesApi(String userEmail) async {
  final res = await http.get(
    Uri.parse('http://localhost:3000/api/invoices?user_email=$userEmail'), // Correction du chemin
    headers: {
      if (jwtToken != null) 'Authorization': 'Bearer $jwtToken',
    },
  );
  if (res.statusCode == 200) {
    final decoded = jsonDecode(res.body);
    if (decoded is List) {
      return List<Map<String, dynamic>>.from(decoded);
    }
  }
  return [];
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(AppWithAuth());
}

final Color kPrimaryColor = Color(0xFF005EA6); // Bleu PayPal
final Color kAccentColor = Color(0xFF00B6F3); // Bleu clair accent
final Color kBackgroundColor = Color(0xFFF6F8FB); // Gris très clair
final Color kCardColor = Colors.white;
final Color kTextColor = Color(0xFF222B45);

class AuthService extends ChangeNotifier {
  String? _userEmail;
  String? get userEmail => _userEmail;
  bool get isLoggedIn => _userEmail != null;

  Future<bool> login(String email, String password) async {
    final ok = await loginApi(email, password);
    if (ok) {
      _userEmail = email;
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> register(String email, String password) async {
    final ok = await registerApi(email, password);
    if (ok) {
      _userEmail = email;
      notifyListeners();
      return true;
    }
    return false;
  }

  void logout() {
    _userEmail = null;
    jwtToken = null;
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
        fontFamily: 'Roboto',
        primaryColor: kPrimaryColor,
        scaffoldBackgroundColor: kBackgroundColor,
        appBarTheme: AppBarTheme(
          backgroundColor: kCardColor,
          elevation: 2,
          iconTheme: IconThemeData(color: kPrimaryColor),
          titleTextStyle: TextStyle(color: kTextColor, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        cardColor: kCardColor,
        colorScheme: ColorScheme.fromSwatch().copyWith(
          primary: kPrimaryColor,
          secondary: kAccentColor,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: kPrimaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 3,
            textStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
          contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          labelStyle: TextStyle(color: kPrimaryColor),
        ),
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
  bool gasless = false;

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
                    icon: Icons.email,
                    onSaved: (val) => email = val ?? '',
                    validator: (val) => val != null && val.contains('@') ? null : 'Email invalide',
                  ),
                  MainTextField(
                    label: 'Description',
                    icon: Icons.description,
                    onSaved: (val) => description = val ?? '',
                  ),
                  MainTextField(
                    label: 'Montant (USDC)',
                    icon: Icons.attach_money,
                    onSaved: (val) => amount = val ?? '',
                    validator: (val) => val != null && double.tryParse(val) != null ? null : 'Montant invalide',
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
                        await addInvoiceApi(
                          authService.userEmail!, email, description, amount, gasless: gasless);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => InvoiceDetailPage(
                              email: email,
                              description: description,
                              amount: amount,
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
    final data = await getInvoicesApi(authService.userEmail!);
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
                          leading: CircleAvatar(
                            backgroundColor: kAccentColor.withOpacity(0.15),
                            child: Icon(Icons.receipt, color: kPrimaryColor),
                          ),
                          title: Text('${invoice['description']} - ${invoice['amount']} USDC', style: TextStyle(fontWeight: FontWeight.bold, color: kTextColor)),
                          subtitle: Text(invoice['client_email'] ?? '', style: TextStyle(color: Colors.grey[700])),
                          trailing: Icon(Icons.arrow_forward_ios, size: 16, color: kPrimaryColor),
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
  final bool gasless;

  InvoiceDetailPage({required this.email, required this.description, required this.amount, this.gasless = false});

  @override
  Widget build(BuildContext context) {
    final usdcAddress = '0x1234567890abcdef1234567890abcdef12345678';
    final invoiceId = DateTime.now().millisecondsSinceEpoch.toString();
    final qrData = {
      'type': 'usdc_invoice',
      'amount': amount,
      'currency': 'USDC',
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
              Text('Gasless : ${gasless ? "Oui" : "Non"}', style: TextStyle(fontSize: 16)),
              SizedBox(height: 30),
              Card(
                elevation: 6,
                margin: EdgeInsets.symmetric(vertical: 8, horizontal: 0),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                color: kCardColor,
                shadowColor: kAccentColor.withOpacity(0.12),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      Text('Payer en crypto', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: kPrimaryColor)),
                      SizedBox(height: 16),
                      QrImageView(
                        data: qrData.toString(),
                        size: 220,
                        backgroundColor: Colors.white,
                      ),
                      SizedBox(height: 18),
                      SelectableText('Adresse USDC :\n$usdcAddress', textAlign: TextAlign.center, style: TextStyle(color: kTextColor, fontWeight: FontWeight.w500)),
                      SizedBox(height: 10),
                      Text('Le choix de la blockchain se fera lors du paiement par l’acheteur.', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                      SizedBox(height: 24),
                      MainButton(
                        label: 'Envoyer la facture par mail',
                        icon: Icons.email,
                        onPressed: () async {
                          final subject = Uri.encodeComponent('Facture USDC - $amount USDC');
                          final body = Uri.encodeComponent('Bonjour,\n\nVoici votre facture :\n- Montant : $amount USDC\n- Description : $description\n- Paiement gasless : ${gasless ? "Oui" : "Non"}\n\nPour payer, scannez le QR code ci-dessous dans votre app crypto compatible :\n$qrData\n\nMerci !');
                          final mailto = 'mailto:$email?subject=$subject&body=$body';
                          if (await canLaunchUrl(Uri.parse(mailto))) {
                            await launchUrl(Uri.parse(mailto));
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Impossible d’ouvrir le client mail.')),
                            );
                          }
                        },
                      ),
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
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: kPrimaryColor,
          foregroundColor: Colors.white,
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          shadowColor: kAccentColor.withOpacity(0.2),
          padding: EdgeInsets.symmetric(vertical: 18),
        ),
        onPressed: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 22, color: Colors.white),
              SizedBox(width: 10),
            ],
            Text(label, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
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
  final IconData? icon;
  const MainTextField({required this.label, this.obscureText = false, this.onSaved, this.validator, this.icon, super.key});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: icon != null ? Icon(icon, color: kPrimaryColor) : null,
        ),
        obscureText: obscureText,
        onSaved: onSaved,
        validator: validator,
      ),
    );
  }
}
