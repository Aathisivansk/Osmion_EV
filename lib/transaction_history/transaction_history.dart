// lib/transaction_history/transaction_history.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'transaction_model.dart';

class TransactionHistoryPage extends StatefulWidget {
  const TransactionHistoryPage({super.key});

  @override
  State<TransactionHistoryPage> createState() => _TransactionHistoryPageState();
}

class _TransactionHistoryPageState extends State<TransactionHistoryPage> {
  late Future<List<Transaction>> _transactionsFuture;
  final String baseUrl = "http://10.62.58.114:5000";

  @override
  void initState() {
    super.initState();
    _transactionsFuture = _fetchTransactions();
  }

  Future<List<Transaction>> _fetchTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final userEmail = prefs.getString('user_email');
    if (userEmail == null) {
      throw Exception('User not logged in');
    }

    final response = await http
        .get(Uri.parse('$baseUrl/api/transactions/$userEmail'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success']) {
        final List<dynamic> transactionsJson = data['transactions'];
        return transactionsJson
            .map((json) => Transaction.fromJson(json))
            .toList();
      } else {
        throw Exception('Failed to load transactions');
      }
    } else {
      throw Exception('Failed to connect to server');
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryTextColor = Color(0xFF0A4F37);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Transaction History',
          style:
          TextStyle(color: primaryTextColor, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: primaryTextColor),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _transactionsFuture = _fetchTransactions();
              });
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Transaction>>(
        future: _transactionsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No transactions found.'));
          }

          final transactions = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: transactions.length,
            itemBuilder: (context, index) {
              final transaction = transactions[index];
              return _buildTransactionItem(
                station: transaction.stationName,
                date: DateFormat.yMMMd().add_jm().format(transaction.timestamp.toLocal()),
                amount: '- ₹ ${transaction.amount.toStringAsFixed(2)}',
                method: transaction.paymentMethod,
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildTransactionItem({
    required String station,
    required String date,
    required String amount,
    required String method,
  }) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  station,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  date,
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  amount,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  method,
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}