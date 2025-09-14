import 'package:flutter/material.dart';

class HelpAndSupportPage extends StatelessWidget {
  const HelpAndSupportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Support'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Text(
            'Frequently Asked Questions',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildFaqItem(
            question: 'How do I start a charge?',
            answer: 'To start a charge, simply locate a charger on the map, connect your vehicle, and tap the "Start Charging" button in the app.',
          ),
          _buildFaqItem(
            question: 'What payment methods are accepted?',
            answer: 'We accept all major credit cards, debit cards, and payments through the in-app wallet.',
          ),
          _buildFaqItem(
            question: 'My charging session failed. What should I do?',
            answer: 'Please ensure your vehicle is properly connected. If the issue persists, please contact our support team using the details below.',
          ),
          const Divider(height: 40),
          const Text(
            'Contact Us',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const ListTile(
            leading: Icon(Icons.email_outlined),
            title: Text('support@evchargeapp.com'),
          ),
          const ListTile(
            leading: Icon(Icons.phone_outlined),
            title: Text('+91-123-456-7890'),
          ),
        ],
      ),
    );
  }

  Widget _buildFaqItem({required String question, required String answer}) {
    return ExpansionTile(
      title: Text(question, style: const TextStyle(fontWeight: FontWeight.w500)),
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(answer),
        ),
      ],
    );
  }
}
