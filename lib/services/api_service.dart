import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import '../models/invoice.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:3000/api';
  
  // ==========================================
  // GESTION DES UTILISATEURS
  // ==========================================
  
  /// Créer un nouvel utilisateur
  static Future<User> createUser({
    required String email,
    required String password,
    String? ethereumAddress,
    String? firstName,
    String? lastName,
    String? phone,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
          'ethereum_address': ethereumAddress,
          'first_name': firstName,
          'last_name': lastName,
          'phone': phone,
        }),
      );

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 201) {
        print('✅ Utilisateur créé: ${data['user']['email']}');
        return User.fromJson(data['user']);
      } else {
        print('❌ Erreur création utilisateur: ${data['error']}');
        throw Exception(data['error'] ?? 'Erreur lors de la création de l\'utilisateur');
      }
    } catch (e) {
      print('❌ Erreur réseau création utilisateur: $e');
      throw Exception('Erreur de connexion au serveur');
    }
  }

  /// Authentifier un utilisateur
  static Future<User> authenticateUser({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users/auth'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        print('✅ Authentification réussie: ${data['user']['email']}');
        return User.fromJson(data['user']);
      } else {
        print('❌ Erreur authentification: ${data['error']}');
        throw Exception(data['error'] ?? 'Email ou mot de passe incorrect');
      }
    } catch (e) {
      print('❌ Erreur réseau authentification: $e');
      throw Exception('Erreur de connexion au serveur');
    }
  }

  /// Récupérer un utilisateur par son adresse Ethereum
  static Future<User?> getUserByAddress(String address) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/address/$address'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        print('✅ Utilisateur récupéré: ${data['user']['email']}');
        return User.fromJson(data['user']);
      } else if (response.statusCode == 404) {
        print('⚠️ Utilisateur non trouvé pour l\'adresse: $address');
        return null;
      } else {
        print('❌ Erreur récupération utilisateur: ${data['error']}');
        throw Exception(data['error'] ?? 'Erreur lors de la récupération de l\'utilisateur');
      }
    } catch (e) {
      print('❌ Erreur réseau récupération utilisateur: $e');
      throw Exception('Erreur de connexion au serveur');
    }
  }

  /// Récupérer tous les utilisateurs
  static Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        print('✅ ${data['count']} utilisateurs récupérés');
        return List<Map<String, dynamic>>.from(data['users']);
      } else {
        print('❌ Erreur récupération utilisateurs: ${data['error']}');
        throw Exception(data['error'] ?? 'Erreur lors de la récupération des utilisateurs');
      }
    } catch (e) {
      print('❌ Erreur réseau récupération utilisateurs: $e');
      throw Exception('Erreur de connexion au serveur');
    }
  }

  /// Mettre à jour un utilisateur
  static Future<Map<String, dynamic>> updateUser({
    required int userId,
    String? email,
    String? password,
    String? ethereumAddress,
    String? firstName,
    String? lastName,
    String? phone,
  }) async {
    try {
      final Map<String, dynamic> updateData = {};
      
      if (email != null) updateData['email'] = email;
      if (password != null) updateData['password'] = password;
      if (ethereumAddress != null) updateData['ethereum_address'] = ethereumAddress;
      if (firstName != null) updateData['first_name'] = firstName;
      if (lastName != null) updateData['last_name'] = lastName;
      if (phone != null) updateData['phone'] = phone;

      final response = await http.put(
        Uri.parse('$baseUrl/users/$userId'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(updateData),
      );

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        print('✅ Utilisateur mis à jour: ID $userId');
        return data;
      } else {
        print('❌ Erreur mise à jour utilisateur: ${data['error']}');
        throw Exception(data['error'] ?? 'Erreur lors de la mise à jour de l\'utilisateur');
      }
    } catch (e) {
      print('❌ Erreur réseau mise à jour utilisateur: $e');
      throw Exception('Erreur de connexion au serveur');
    }
  }

  // ==========================================
  // GESTION DES FACTURES
  // ==========================================

  /// Créer une nouvelle facture
  static Future<Map<String, dynamic>> createInvoice({
    required String merchantAddress,
    required String clientAddress,
    required String description,
    required double amount,
    String? dueDate,
    int? blockchainInvoiceId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/invoices'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'merchant_address': merchantAddress,
          'client_address': clientAddress,
          'description': description,
          'amount': amount,
          'due_date': dueDate,
          'blockchain_invoice_id': blockchainInvoiceId,
        }),
      );

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 201) {
        print('✅ Facture créée: ID ${data['invoice']['id']}');
        return data;
      } else {
        print('❌ Erreur création facture: ${data['error']}');
        throw Exception(data['error'] ?? 'Erreur lors de la création de la facture');
      }
    } catch (e) {
      print('❌ Erreur réseau création facture: $e');
      throw Exception('Erreur de connexion au serveur');
    }
  }

  /// Récupérer les factures d'un marchand
  static Future<List<Map<String, dynamic>>> getMerchantInvoices(
    String merchantAddress, {
    String? status,
    int? limit,
    int? offset,
  }) async {
    try {
      String url = '$baseUrl/invoices/merchant/$merchantAddress';
      List<String> queryParams = [];
      
      if (status != null) queryParams.add('status=$status');
      if (limit != null) queryParams.add('limit=$limit');
      if (offset != null) queryParams.add('offset=$offset');
      
      if (queryParams.isNotEmpty) {
        url += '?${queryParams.join('&')}';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        print('✅ ${data['count']} factures récupérées pour le marchand $merchantAddress');
        return List<Map<String, dynamic>>.from(data['invoices']);
      } else {
        print('❌ Erreur récupération factures marchand: ${data['error']}');
        throw Exception(data['error'] ?? 'Erreur lors de la récupération des factures');
      }
    } catch (e) {
      print('❌ Erreur réseau récupération factures marchand: $e');
      throw Exception('Erreur de connexion au serveur');
    }
  }

  /// Récupérer les factures d'un client
  static Future<List<Map<String, dynamic>>> getClientInvoices(
    String clientAddress, {
    String? status,
    int? limit,
    int? offset,
  }) async {
    try {
      String url = '$baseUrl/invoices/client/$clientAddress';
      List<String> queryParams = [];
      
      if (status != null) queryParams.add('status=$status');
      if (limit != null) queryParams.add('limit=$limit');
      if (offset != null) queryParams.add('offset=$offset');
      
      if (queryParams.isNotEmpty) {
        url += '?${queryParams.join('&')}';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        print('✅ ${data['count']} factures récupérées pour le client $clientAddress');
        return List<Map<String, dynamic>>.from(data['invoices']);
      } else {
        print('❌ Erreur récupération factures client: ${data['error']}');
        throw Exception(data['error'] ?? 'Erreur lors de la récupération des factures');
      }
    } catch (e) {
      print('❌ Erreur réseau récupération factures client: $e');
      throw Exception('Erreur de connexion au serveur');
    }
  }

  /// Récupérer toutes les factures
  static Future<List<Map<String, dynamic>>> getAllInvoices({
    String? status,
    int? limit,
    int? offset,
  }) async {
    try {
      String url = '$baseUrl/invoices';
      List<String> queryParams = [];
      
      if (status != null) queryParams.add('status=$status');
      if (limit != null) queryParams.add('limit=$limit');
      if (offset != null) queryParams.add('offset=$offset');
      
      if (queryParams.isNotEmpty) {
        url += '?${queryParams.join('&')}';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        print('✅ ${data['count']} factures récupérées');
        return List<Map<String, dynamic>>.from(data['invoices']);
      } else {
        print('❌ Erreur récupération factures: ${data['error']}');
        throw Exception(data['error'] ?? 'Erreur lors de la récupération des factures');
      }
    } catch (e) {
      print('❌ Erreur réseau récupération factures: $e');
      throw Exception('Erreur de connexion au serveur');
    }
  }

  /// Mettre à jour une facture
  static Future<Map<String, dynamic>> updateInvoice({
    required int invoiceId,
    String? status,
    String? transactionHash,
    String? paidAt,
    String? dueDate,
  }) async {
    try {
      final Map<String, dynamic> updateData = {};
      
      if (status != null) updateData['status'] = status;
      if (transactionHash != null) updateData['transaction_hash'] = transactionHash;
      if (paidAt != null) updateData['paid_at'] = paidAt;
      if (dueDate != null) updateData['due_date'] = dueDate;

      final response = await http.put(
        Uri.parse('$baseUrl/invoices/$invoiceId'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(updateData),
      );

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        print('✅ Facture mise à jour: ID $invoiceId');
        return data;
      } else {
        print('❌ Erreur mise à jour facture: ${data['error']}');
        throw Exception(data['error'] ?? 'Erreur lors de la mise à jour de la facture');
      }
    } catch (e) {
      print('❌ Erreur réseau mise à jour facture: $e');
      throw Exception('Erreur de connexion au serveur');
    }
  }

  /// Récupérer les statistiques des factures
  static Future<Map<String, dynamic>> getInvoiceStats({
    String? merchantAddress,
    String? clientAddress,
  }) async {
    try {
      String url = '$baseUrl/invoices/stats/overview';
      List<String> queryParams = [];
      
      if (merchantAddress != null) queryParams.add('merchant_address=$merchantAddress');
      if (clientAddress != null) queryParams.add('client_address=$clientAddress');
      
      if (queryParams.isNotEmpty) {
        url += '?${queryParams.join('&')}';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        print('✅ Statistiques récupérées');
        return data['stats'];
      } else {
        print('❌ Erreur récupération statistiques: ${data['error']}');
        throw Exception(data['error'] ?? 'Erreur lors de la récupération des statistiques');
      }
    } catch (e) {
      print('❌ Erreur réseau récupération statistiques: $e');
      throw Exception('Erreur de connexion au serveur');
    }
  }

  /// Supprimer une facture
  static Future<Map<String, dynamic>> deleteInvoice(int invoiceId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/invoices/$invoiceId'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        print('✅ Facture supprimée: ID $invoiceId');
        return data;
      } else {
        print('❌ Erreur suppression facture: ${data['error']}');
        throw Exception(data['error'] ?? 'Erreur lors de la suppression de la facture');
      }
    } catch (e) {
      print('❌ Erreur réseau suppression facture: $e');
      throw Exception('Erreur de connexion au serveur');
    }
  }

  // ==========================================
  // MÉTHODES SIMPLIFIÉES POUR RÉCUPÉRER DES OBJETS INVOICE
  // ==========================================

  /// Récupérer les factures d'un marchand sous forme d'objets Invoice
  static Future<List<Invoice>> getInvoicesByMerchant(String merchantAddress) async {
    try {
      final invoicesData = await getMerchantInvoices(merchantAddress);
      print('🔍 Données brutes récupérées: ${invoicesData.length} factures');
      
      List<Invoice> invoices = [];
      for (int i = 0; i < invoicesData.length; i++) {
        try {
          final invoice = Invoice.fromJson(invoicesData[i]);
          invoices.add(invoice);
        } catch (e) {
          print('❌ Erreur conversion facture $i: $e');
          print('📄 Données de la facture: ${invoicesData[i]}');
        }
      }
      
      return invoices;
    } catch (e) {
      print('❌ Erreur récupération factures marchand: $e');
      return [];
    }
  }

  /// Récupérer les factures d'un client sous forme d'objets Invoice
  static Future<List<Invoice>> getInvoicesByClient(String clientAddress) async {
    try {
      final invoicesData = await getClientInvoices(clientAddress);
      print('🔍 Données brutes récupérées: ${invoicesData.length} factures');
      
      List<Invoice> invoices = [];
      for (int i = 0; i < invoicesData.length; i++) {
        try {
          final invoice = Invoice.fromJson(invoicesData[i]);
          invoices.add(invoice);
        } catch (e) {
          print('❌ Erreur conversion facture $i: $e');
          print('📄 Données de la facture: ${invoicesData[i]}');
        }
      }
      
      return invoices;
    } catch (e) {
      print('❌ Erreur récupération factures client: $e');
      return [];
    }
  }

  /// Créer une facture et retourner un objet Invoice
  static Future<Invoice> createInvoiceObject({
    required String merchantAddress,
    required String clientAddress,
    required String description,
    required double amount,
  }) async {
    try {
      final invoiceData = await createInvoice(
        merchantAddress: merchantAddress,
        clientAddress: clientAddress,
        description: description,
        amount: amount,
      );
      
      print('🔍 Données facture créée: ${invoiceData['invoice']}');
      return Invoice.fromJson(invoiceData['invoice']);
    } catch (e) {
      print('❌ Erreur création facture: $e');
      rethrow;
    }
  }

  // ==========================================
  // GESTION DES PAIEMENTS
  // ==========================================

  /// Marquer une facture comme payée
  static Future<bool> payInvoice(int invoiceId) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/invoices/$invoiceId/pay'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        print('✅ Facture $invoiceId marquée comme payée');
        return true;
      } else {
        print('❌ Erreur paiement facture: ${data['error']}');
        throw Exception(data['error'] ?? 'Erreur lors du paiement');
      }
    } catch (e) {
      print('❌ Erreur réseau paiement: $e');
      throw Exception('Erreur de connexion au serveur');
    }
  }

  // ==========================================
  // UTILITAIRES
  // ==========================================

  /// Vérifier la santé de l'API
  static Future<bool> checkApiHealth() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/health'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ API disponible: ${data['status']}');
        return true;
      } else {
        print('❌ API non disponible: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('❌ Erreur connexion API: $e');
      return false;
    }
  }
}
