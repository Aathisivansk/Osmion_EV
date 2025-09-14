import 'package:flutter/material.dart';
import 'auth/login.dart'; // Make sure this file exists in the lib folder';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'OSMION',
      theme: ThemeData(
        primarySwatch: Colors.green,
        fontFamily: 'Inter',
      ),
      // Corrected to use the actual class name: LoginScreen
      home: const LoginScreen(),
    );
  }
}
