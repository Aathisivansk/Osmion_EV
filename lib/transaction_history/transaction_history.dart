import 'package:flutter/material.dart';

class TransactionHistoryPage extends StatelessWidget {
  const TransactionHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    const Color primaryTextColor = Color(0xFF0A4F37);
    const Color secondaryColor = Color(0xFFDDFCDA);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Transaction History',
          style: TextStyle(color: primaryTextColor, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: primaryTextColor),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildHistorySection(secondaryColor, primaryTextColor),
        ],
      ),
    );
  }

  Widget _buildHistorySection(Color secondaryColor, Color primaryTextColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            color: secondaryColor.withOpacity(0.5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'September 2025',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: primaryTextColor,
            ),
          ),
        ),
        const SizedBox(height: 8),
        _buildTransactionItem(
          station: 'Hydra charging station',
          date: 'Paid Yesterday, 05:15 PM',
          amount: '- ₹ 1000',
          method: 'From Wallet',
        ),
        _buildTransactionItem(
          station: 'Ather charging station',
          date: 'Paid two days ago, 07:30PM',
          amount: '- ₹ 500',
          method: 'From UPI',
        ),
        _buildTransactionItem(
          station: 'Statiq charging station',
          date: 'Paid 5 September, 05:15 PM',
          amount: '- ₹ 2200.5',
          method: 'From UPI',
        ),
      ],
    );
  }

  Widget _buildTransactionItem({
    required String station,
    required String date,
    required String amount,
    required String method,
  }) {
    return Card(
      elevation: 0,
      color: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
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