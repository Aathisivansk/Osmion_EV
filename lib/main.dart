import 'package:flutter/material.dart';
import 'package:osmion/slot_booking/stations.dart';
// Import your station details page

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // --- UPDATED SAMPLE DATA ---
    // Now includes an 'isAvailable' flag for each charger.
    final sampleStation = StationDetails(
      name: 'IOCL Shanthi Social Services Charging Station',
      address: '128, 2247, Trichy Rd, Krishnapuram Medu, Singanallur',
      rating: 4.7,
      isOpen: true,
      distanceInKm: 3.4,
      timing: '12:00 AM - 11:59 PM',
      chargers: [
        Charger(
          name: 'Charger A',
          type: 'CCS-2',
          tariff: '₹180.00/15 mins',
          rating: 5,
          isAvailable: false, // This charger is now occupied
        ),
        Charger(
          name: 'Charger B',
          type: 'CCS-2',
          tariff: '₹180.00/15 mins',
          rating: 3,
          isAvailable: true, // This charger is available
        ),
      ],
    );

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
      title: 'Osmion EV Station Details',
      theme: ThemeData(
        primarySwatch: primaryThemeColor,
        fontFamily: 'Inter',
        scaffoldBackgroundColor: Colors.white,
      ),
      // Set the StationDetailsPage as the home screen, passing the sample data
      home: StationDetailsPage(station: sampleStation),
    );
  }
}

