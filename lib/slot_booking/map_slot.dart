import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

// A data model to represent a charging station for better code structure
class ChargingStation {
  final String name;
  final LatLng position;
  final List<String> sockets;
  final double rating;

  ChargingStation({
    required this.name,
    required this.position,
    required this.sockets,
    required this.rating,
  });

  // A factory constructor to create a ChargingStation from the JSON data from your server
  factory ChargingStation.fromJson(Map<String, dynamic> json) {
    return ChargingStation(
      name: json['stationName'] ?? 'Unknown Station',
      position: LatLng(
        (json['latitude'] as num).toDouble(),
        (json['longitude'] as num).toDouble(),
      ),
      sockets: List<String>.from(json['sockets'] ?? []),
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
    );
  }
}


class SlotBookingPage extends StatefulWidget {
  const SlotBookingPage({super.key, required String userVehicleConnector});

  @override
  State<SlotBookingPage> createState() => _SlotBookingPageState();
}

class _SlotBookingPageState extends State<SlotBookingPage> {
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  // Default to a central location in Coimbatore
  LatLng _initialCameraPosition = const LatLng(11.0168, 76.9558); 
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _determinePositionAndFetchStations();
  }

  // This function gets the user's current location and then fetches the stations
  Future<void> _determinePositionAndFetchStations() async {
    // Check for location permissions
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    
    // If permission is granted, get the user's current location
    if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
      try {
        Position position = await Geolocator.getCurrentPosition();
        setState(() {
          _initialCameraPosition = LatLng(position.latitude, position.longitude);
        });
      } catch (e) {
        debugPrint("Error getting location: $e");
      }
    }
    
    // Fetch the charging station data from the server
    _fetchChargingStations();
  }

  // This function sends a request to your Python server
  Future<void> _fetchChargingStations() async {
    // --- IMPORTANT: This is the line you MUST change ---
    // Replace '192.168.1.5' with your computer's actual IP address.
    const String serverUrl = ' 10.128.93.91';
    
    try {
      final response = await http.get(Uri.parse(serverUrl));

      if (response.statusCode == 200) {
        // If the server responds successfully, parse the JSON data
        final List<dynamic> stationData = json.decode(response.body);
        final List<ChargingStation> stations = stationData.map((data) => ChargingStation.fromJson(data)).toList();
        
        // Create map markers for each station
        setState(() {
          _markers.clear();
          for (final station in stations) {
            _markers.add(
              Marker(
                markerId: MarkerId(station.name),
                position: station.position,
                infoWindow: InfoWindow(
                  title: station.name,
                  snippet: 'Rating: ${station.rating} ⭐',
                ),
                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
              ),
            );
          }
          _isLoading = false;
        });
      } else {
        debugPrint('Server error: ${response.statusCode} - ${response.body}');
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint("Error fetching stations: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryTextColor = Color(0xFF0A4F37);
    const Color secondaryColor = Color(0xFFDDFCDA);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Book a Charging Slot',
          style: TextStyle(color: primaryTextColor, fontWeight: FontWeight.bold),
        ),
        backgroundColor: secondaryColor,
        elevation: 1,
        iconTheme: const IconThemeData(color: primaryTextColor),
      ),
      // Show a loading circle while fetching data, otherwise show the map
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryTextColor))
          : GoogleMap(
              onMapCreated: (controller) => _mapController = controller,
              initialCameraPosition: CameraPosition(
                target: _initialCameraPosition,
                zoom: 12.0,
              ),
              markers: _markers,
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
            ),
    );
  }
}



        


