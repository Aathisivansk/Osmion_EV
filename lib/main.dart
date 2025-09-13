import 'package:flutter/material.dart';
import 'login.dart'; // Make sure this file exists in the lib folder';
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  // Updated to use a super parameter for the key.
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Login UI',
      theme: ThemeData(
        primarySwatch: Colors.green,
        fontFamily: 'Inter',
      ),
      // Corrected to use the actual class name: LoginScreen
      home: const LoginScreen(),
    );
  }
}

