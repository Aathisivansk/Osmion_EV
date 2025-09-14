// lib/hosting_session.dart
import 'package:shared_preferences/shared_preferences.dart';

class HostingSession {
  final bool isHosting;
  final String location;
  final String socketType;
  final DateTime availableUntil;
  final double pricePerHour;
  final String contactDetails;

  HostingSession({
    required this.isHosting,
    required this.location,
    required this.socketType,
    required this.availableUntil,
    required this.pricePerHour,
    required this.contactDetails,
  });

  // Method to convert our object to a JSON map
  Future<Map<String, dynamic>> toJson() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'isHosting': isHosting,
      'location': location,
      'socketType': socketType,
      'availableUntil': availableUntil.toIso8601String(), // Convert DateTime to a standard string
      'pricePerHour': pricePerHour,
      'contactDetails': contactDetails,
      'userId': prefs.getString('userName'), // In a real app, you'd get this from your auth system
    };
  }
}