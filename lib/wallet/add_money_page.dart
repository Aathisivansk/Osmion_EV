import 'package:flutter/material.dart';

class AddMoneyPage extends StatelessWidget {
  const AddMoneyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Money'),
      ),
      body: const Center(
        child: Text(
          'Add Money Page - Coming Soon!',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}