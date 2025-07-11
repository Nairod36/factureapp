class Invoice {
  final int id;
  final String merchant;
  final String client;
  final double amount;
  final String description;
  final bool isPaid;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? paidAt;

  Invoice({
    required this.id,
    required this.merchant,
    required this.client,
    required this.amount,
    required this.description,
    required this.isPaid,
    required this.createdAt,
    required this.updatedAt,
    this.paidAt,
  });

  factory Invoice.fromJson(Map<String, dynamic> json) {
    // Fonction pour parser les dates de différents formats
    DateTime parseDate(dynamic dateValue) {
      if (dateValue == null) return DateTime.now();
      if (dateValue is DateTime) return dateValue;
      
      String dateStr = dateValue.toString();
      try {
        // Essai format ISO standard
        return DateTime.parse(dateStr);
      } catch (e) {
        try {
          // Essai format SQL : "2025-07-10 20:26:34"
          return DateTime.parse(dateStr.replaceAll(' ', 'T'));
        } catch (e2) {
          print('❌ Erreur parsing date: $dateStr');
          return DateTime.now();
        }
      }
    }

    return Invoice(
      id: json['id'] ?? 0,
      merchant: json['merchant_address'] ?? json['merchant'] ?? '',
      client: json['client_address'] ?? json['client'] ?? '',
      amount: (json['amount'] ?? json['montant'] ?? 0).toDouble(),
      description: json['description'] ?? '',
      isPaid: json['status'] == 'paid' || json['payee'] == true || json['payee'] == 1,
      createdAt: json['created_at'] != null ? parseDate(json['created_at']) : DateTime.now(),
      updatedAt: json['updated_at'] != null ? parseDate(json['updated_at']) : DateTime.now(),
      paidAt: json['paid_at'] != null ? parseDate(json['paid_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'merchant': merchant,
      'client': client,
      'montant': amount,
      'description': description,
      'payee': isPaid,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'paid_at': paidAt?.toIso8601String(),
    };
  }

  String get formattedAmount {
    return '${amount.toStringAsFixed(2)} USDC';
  }

  String get statusText {
    return isPaid ? 'Payée' : 'En attente';
  }

  String get shortId {
    return '#${id.toString().padLeft(4, '0')}';
  }
}
