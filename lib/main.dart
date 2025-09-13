import 'package:flutter/material.dart';
import 'package:osmion/map_screen.dart'; // Make sure the import path is correct

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Osmion Map',
      theme: ThemeData(
        primarySwatch: Colors.green,
        useMaterial3: true,
      ),
      home: const HomeScreen(),
      // Remove the debug banner
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Map App Home'),
        backgroundColor: const Color.fromARGB(255, 199, 245, 200),
      ),
      body: Center(
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color.fromARGB(255, 2, 83, 30),
            foregroundColor: Colors.white,
          ),
          child: const Text('Open Map'),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const MapScreen()),
            );
          },
        ),
      ),
    );
  }
}