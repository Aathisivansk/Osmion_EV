import 'package:flutter/material.dart';
import 'slot_booking/map_slot.dart'; // Make sure this file exists in your lib folder

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Define the primary color swatch for your app's theme
    const MaterialColor primaryThemeColor = MaterialColor(
      0xFF0A4F37,
      <int, Color>{
        50: Color(0xFFE1F0E7),
        100: Color(0xFFB5D9C4),
        200: Color(0xFF84BFA0),
        300: Color(0xFF53A57C),
        400: Color(0xFF2E915F),
        500: Color(0xFF0A7D42),
        600: Color(0xFF09753C),
        700: Color(0xFF076A34),
        800: Color(0xFF055F2D),
        900: Color(0xFF034C20),
      },
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Osmion EV Charging',
      theme: ThemeData(
        primarySwatch: primaryThemeColor,
        fontFamily: 'Inter', // Assuming you have this font configured
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 1,
          iconTheme: IconThemeData(color: Color(0xFF0A4F37)),
          titleTextStyle: TextStyle(
            color: Color(0xFF0A4F37),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      // Set the SlotBookingPage as the home screen
      home: const SlotBookingPage(),
    );
  }
}

