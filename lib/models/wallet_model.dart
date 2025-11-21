/// Wallet Model
/// 
/// Represents customer wallet information
class WalletModel {
  final String id;
  final double balance;
  final String currency;

  WalletModel({
    required this.id,
    required this.balance,
    required this.currency,
  });

  factory WalletModel.fromJson(Map<String, dynamic> json) {
    return WalletModel(
      id: json['id'] as String,
      balance: (json['balance'] as num).toDouble(),
      currency: json['currency'] as String? ?? 'INR',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'balance': balance,
      'currency': currency,
    };
  }
}

/// Wallet Transaction Model
class WalletTransactionModel {
  final String id;
  final double amount;
  final String transactionType; // 'credit' or 'debit'
  final String description;
  final DateTime createdOn;

  WalletTransactionModel({
    required this.id,
    required this.amount,
    required this.transactionType,
    required this.description,
    required this.createdOn,
  });

  factory WalletTransactionModel.fromJson(Map<String, dynamic> json) {
    return WalletTransactionModel(
      id: json['id'] as String,
      amount: (json['amount'] as num).toDouble(),
      transactionType: json['transaction_type'] as String,
      description: json['description'] as String? ?? '',
      createdOn: DateTime.parse(json['created_on'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'transaction_type': transactionType,
      'description': description,
      'created_on': createdOn.toIso8601String(),
    };
  }

  bool get isCredit => transactionType.toLowerCase() == 'credit';
}

