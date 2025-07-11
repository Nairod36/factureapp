import 'package:flutter/foundation.dart';

class User {
  final int id;
  final String? ethereumAddress;
  final String? email;
  final String? firstName;
  final String? lastName;
  final String? phone;
  final DateTime createdAt;
  final DateTime updatedAt;

  User({
    required this.id,
    this.ethereumAddress,
    this.email,
    this.firstName,
    this.lastName,
    this.phone,
    required this.createdAt,
    required this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      ethereumAddress: json['ethereum_address'],
      email: json['email'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      phone: json['phone'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ethereum_address': ethereumAddress,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'phone': phone,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  String get displayName {
    if (firstName != null && lastName != null) {
      return '$firstName $lastName';
    }
    if (firstName != null) return firstName!;
    if (lastName != null) return lastName!;
    if (email != null) return email!;
    if (ethereumAddress != null) {
      return '${ethereumAddress!.substring(0, 6)}...${ethereumAddress!.substring(ethereumAddress!.length - 4)}';
    }
    return 'Utilisateur #$id';
  }

  String get identifier {
    return ethereumAddress ?? email ?? 'user_$id';
  }
}

class UserState extends ChangeNotifier {
  User? _currentUser;
  bool _isAuthenticated = false;

  User? get currentUser => _currentUser;
  bool get isAuthenticated => _isAuthenticated;

  void setUser(User user) {
    _currentUser = user;
    _isAuthenticated = true;
    notifyListeners();
  }

  void logout() {
    _currentUser = null;
    _isAuthenticated = false;
    notifyListeners();
  }

  void updateUser(User user) {
    _currentUser = user;
    notifyListeners();
  }
}
