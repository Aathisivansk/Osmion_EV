// lib/hosting_session.dart

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
  Map<String, dynamic> toJson() {
    return {
      'isHosting': isHosting,
      'location': location,
      'socketType': socketType,
      'availableUntil': availableUntil.toIso8601String(), // Convert DateTime to a standard string
      'pricePerHour': pricePerHour,
      'contactDetails': contactDetails,
      'userId': 'user123', // In a real app, you'd get this from your auth system
    };
  }
}