import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  // Use a MapController to programmatically control the map
  final MapController _mapController = MapController();

  // A variable to hold the user's current location
  LatLng? _currentPosition;
  bool _isLoading = true; // To show a loading indicator

  @override
  void initState() {
    super.initState();
    // Fetch the user's location when the widget is initialized
    _getCurrentLocation();
  }

  // Method to get the current location
  Future<void> _getCurrentLocation() async {
    // Check for location permission
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      // Request permission if it's denied
      permission = await Geolocator.requestPermission();
    }

    // If permission is granted, get the current position
    if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
      try {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );

        // Update the state with the new position
        setState(() {
          _currentPosition = LatLng(position.latitude, position.longitude);
          _isLoading = false;
        });

        // Move the map camera to the new position
        _mapController.move(_currentPosition!, 15.0);
      } catch (e) {
        // Handle any errors here
        print("Error getting location: $e");
        setState(() {
          _isLoading = false;
          // You could set a default location here if fetching fails
        });
      }
    } else {
      // Handle the case where permission is not granted
      print("Location permission not granted.");
      setState(() {
        _isLoading = false;
        // You could set a default location here as well
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Map Screen'),
        backgroundColor: Colors.blueAccent,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator()) // Show loader while waiting
          : FlutterMap(
        mapController: _mapController, // Assign the controller
        options: MapOptions(
          // Set an initial center; it will be updated once location is fetched
          initialCenter: _currentPosition ?? LatLng(51.509865, -0.118092), // Default to London if location is null
          initialZoom: 15.0,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.osmion', // Replace with your app's package name
          ),
          // Only build the marker layer if we have the user's position
          if (_currentPosition != null)
            MarkerLayer(
              markers: [
                Marker(
                  point: _currentPosition!,
                  child: const Icon(
                    Icons.person_pin_circle,
                    color: Colors.blue,
                    size: 40.0,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}