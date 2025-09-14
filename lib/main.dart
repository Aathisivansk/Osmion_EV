import 'package:flutter/material.dart';
import 'wallet.dart'; // Import the wallet page file

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // This title is for the app itself, not visible on the page
      title: 'Osmion Wallet',
      // This removes the "debug" banner from the top right
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Inter', // Optional: sets a default font
      ),
      // This is the most important line:
      // It sets your WalletPage as the first and only screen.
      home: WalletPage(),
    );
  }
}