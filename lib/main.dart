import 'package:flutter/material.dart';
import 'slot_booking/booking_confirmation_page.dart';
import 'slot_booking/stations_detail.dart'; // Needed for the StationDetails and Charger models

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // --- Create Sample Data to pass to the Station Details Page ---
    // In a real app, this data would come from the station details page.
    final sampleCharger = Charger(
      name: 'Charger B',
      type: 'CCS-2',
      tariff: '₹180.00 / 15 mins (Estimated)',
      rating: 4,
      isAvailable: true,
    );

    final sampleStation = StationDetails(
      name: 'IOCL Shanthi Social Services Station',
      address: '123, Trichy Rd, Singanallur',
      rating: 4.7,
      isOpen: true,
      distanceInKm: 3.4,
      timing: '24 Hours',
      chargers: [
        Charger(name: 'Charger A', type: 'CCS-2', tariff: '₹180/15mins', rating: 5, isAvailable: false),
        sampleCharger,
      ],
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Osmion EV Booking',
      theme: ThemeData(
        primaryColor: const Color(0xFF0A4F37),
        fontFamily: 'Inter',
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0A4F37)),
        useMaterial3: true,
      ),
      // Set the StationDetailsPage as the home screen, passing the sample data
      home: StationDetailsPage(
        station: sampleStation,
      ),
    );
  }
}

