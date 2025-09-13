// lib/main.dart
import 'package:flutter/material.dart';
import 'login.dart'; // Import your login page

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const LoginScreen(), // Set your login screen as the home
      debugShowCheckedModeBanner: false, // Removes debug banner
    );
  }
}
