// lib/transaction_history/transaction_model.dart

class Transaction {
  final String stationName;
  final double amount;
  final String paymentMethod;
  final DateTime timestamp;

  Transaction({
    required this.stationName,
    required this.amount,
    required this.paymentMethod,
    required this.timestamp,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      stationName: json['station_name'] ?? 'Unknown Station',
      // Ensure amount is parsed correctly, defaulting to 0.0 if null or invalid
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: json['payment_method'] ?? 'N/A',
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}