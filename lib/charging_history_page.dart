import 'package:flutter/material.dart';

// NOTE: This is a temporary placeholder for your teammate's page.
class ChargingHistoryPage extends StatelessWidget {
  const ChargingHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Charging History'),
      ),
      body: const Center(
        child: Text(
          'Charging History Page',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}