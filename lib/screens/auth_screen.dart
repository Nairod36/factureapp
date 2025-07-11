import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../models/user.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({Key? key}) : super(key: key);

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with TickerProviderStateMixin {
  late TabController _tabController;

  // Contrôleurs pour les formulaires
  final _addressController = TextEditingController();
  final _emailLoginController = TextEditingController();
  final _passwordLoginController = TextEditingController();
  final _emailRegisterController = TextEditingController();
  final _passwordRegisterController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();

  // État de chargement
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _addressController.dispose();
    _emailLoginController.dispose();
    _passwordLoginController.dispose();
    _emailRegisterController.dispose();
    _passwordRegisterController.dispose();
    _confirmPasswordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loginWithAddress() async {
    if (_addressController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Veuillez entrer une adresse Ethereum');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = await ApiService.getUserByAddress(_addressController.text.trim());
      if (user != null) {
        if (mounted) {
          Provider.of<UserState>(context, listen: false).setUser(user);
        }
      } else {
        setState(() => _errorMessage = 'Utilisateur non trouvé avec cette adresse');
      }
    } catch (e) {
      setState(() => _errorMessage = 'Erreur: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loginWithEmail() async {
    if (_emailLoginController.text.trim().isEmpty || _passwordLoginController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Veuillez remplir tous les champs');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = await ApiService.authenticateUser(
        email: _emailLoginController.text.trim(),
        password: _passwordLoginController.text.trim(),
      );
      if (mounted) {
        Provider.of<UserState>(context, listen: false).setUser(user);
      }
    } catch (e) {
      setState(() => _errorMessage = 'Erreur: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _register() async {
    if (_emailRegisterController.text.trim().isEmpty || 
        _passwordRegisterController.text.trim().isEmpty ||
        _confirmPasswordController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Veuillez remplir tous les champs obligatoires');
      return;
    }

    if (_passwordRegisterController.text != _confirmPasswordController.text) {
      setState(() => _errorMessage = 'Les mots de passe ne correspondent pas');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = await ApiService.createUser(
        email: _emailRegisterController.text.trim(),
        password: _passwordRegisterController.text.trim(),
        firstName: _firstNameController.text.trim().isNotEmpty ? _firstNameController.text.trim() : null,
        lastName: _lastNameController.text.trim().isNotEmpty ? _lastNameController.text.trim() : null,
        phone: _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : null,
      );
      if (mounted) {
        Provider.of<UserState>(context, listen: false).setUser(user);
      }
    } catch (e) {
      setState(() => _errorMessage = 'Erreur: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connexion'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Adresse ETH'),
            Tab(text: 'Email'),
            Tab(text: 'Inscription'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAddressLoginTab(),
          _buildEmailLoginTab(),
          _buildRegisterTab(),
        ],
      ),
    );
  }

  Widget _buildAddressLoginTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Connexion avec Adresse Ethereum',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          TextFormField(
            controller: _addressController,
            decoration: const InputDecoration(
              labelText: 'Adresse Ethereum',
              prefixIcon: Icon(Icons.account_balance_wallet),
              border: OutlineInputBorder(),
            ),
            onFieldSubmitted: (_) => _loginWithAddress(),
          ),
          const SizedBox(height: 24),
          if (_errorMessage != null)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                border: Border.all(color: Colors.red.shade200),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _errorMessage!,
                style: TextStyle(color: Colors.red.shade700),
              ),
            ),
          ElevatedButton(
            onPressed: _isLoading ? null : _loginWithAddress,
            child: _isLoading 
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('Se connecter'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailLoginTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Connexion avec Email',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          TextFormField(
            controller: _emailLoginController,
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.email),
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _passwordLoginController,
            decoration: const InputDecoration(
              labelText: 'Mot de passe',
              prefixIcon: Icon(Icons.lock),
              border: OutlineInputBorder(),
            ),
            obscureText: true,
            onFieldSubmitted: (_) => _loginWithEmail(),
          ),
          const SizedBox(height: 24),
          if (_errorMessage != null)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                border: Border.all(color: Colors.red.shade200),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _errorMessage!,
                style: TextStyle(color: Colors.red.shade700),
              ),
            ),
          ElevatedButton(
            onPressed: _isLoading ? null : _loginWithEmail,
            child: _isLoading 
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('Se connecter'),
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Créer un compte',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          TextFormField(
            controller: _emailRegisterController,
            decoration: const InputDecoration(
              labelText: 'Email *',
              prefixIcon: Icon(Icons.email),
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _passwordRegisterController,
            decoration: const InputDecoration(
              labelText: 'Mot de passe *',
              prefixIcon: Icon(Icons.lock),
              border: OutlineInputBorder(),
            ),
            obscureText: true,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _confirmPasswordController,
            decoration: const InputDecoration(
              labelText: 'Confirmer le mot de passe *',
              prefixIcon: Icon(Icons.lock_outline),
              border: OutlineInputBorder(),
            ),
            obscureText: true,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _firstNameController,
            decoration: const InputDecoration(
              labelText: 'Prénom',
              prefixIcon: Icon(Icons.person),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _lastNameController,
            decoration: const InputDecoration(
              labelText: 'Nom',
              prefixIcon: Icon(Icons.person_outline),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _phoneController,
            decoration: const InputDecoration(
              labelText: 'Téléphone',
              prefixIcon: Icon(Icons.phone),
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 24),
          if (_errorMessage != null)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                border: Border.all(color: Colors.red.shade200),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _errorMessage!,
                style: TextStyle(color: Colors.red.shade700),
              ),
            ),
          ElevatedButton(
            onPressed: _isLoading ? null : _register,
            child: _isLoading 
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('Créer le compte'),
          ),
        ],
      ),
    );
  }
}