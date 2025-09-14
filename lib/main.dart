import 'package:flutter/material.dart';
import 'profile_page.dart'; // We will create this file next

void main() => runApp(const EVProfileApp());

class EVProfileApp extends StatelessWidget {
  const EVProfileApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EV Charge Profile',
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: const Color(0xFF2E7D32),
        scaffoldBackgroundColor: const Color(0xFFF5F7F9),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF2E7D32),
          elevation: 0,
          titleTextStyle: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          iconTheme: IconThemeData(color: Colors.white),
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Color(0xFF333333)),
          bodyMedium: TextStyle(color: Colors.black54),
        ),
      ),
      home: const ProfilePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

