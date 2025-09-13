import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package.geolocator/geolocator.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  final StreamController<double?> _centerOnLocationUpdateController = StreamController<double?>();

  bool _isMapReady = false;
  LatLng? _initialCenter;

  @override
  void initState() {
    super.initState();
    _initializeLocationAndMap();
  }

  Future<void> _initializeLocationAndMap() async {
    // 1. Check for and request location permissions
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
    }

    // 2. Fetch the initial location
    try {
      // Use the stream's first value to get a high-accuracy position
      Position position = await Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 1,
        ),
      ).first;

      // 3. Update the state to build the map
      setState(() {
        _initialCenter = LatLng(position.latitude, position.longitude);
        _isMapReady = true;
      });
    } catch (e) {
      // If fetching fails, fall back to a default location (Bangalore, India)
      print("Error fetching initial location: $e");
      setState(() {
        _initialCenter = LatLng(12.9716, 77.5946);
        _isMapReady = true;
      });
    }
  }

  @override
  void dispose() {
    _centerOnLocationUpdateController.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: !_isMapReady
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                // Layer 1: The Map
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _initialCenter!,
                    initialZoom: 17.0,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.osmion', // Replace with your package name
                    ),
                    CurrentLocationLayer(
                      // Use the correct parameter for the latest package version
                      centerOnLocationUpdate: _centerOnLocationUpdateController.stream,
                      alignDirectionOnUpdate: AlignOnUpdate.never,
                      style: LocationMarkerStyle(
                        marker: DefaultLocationMarker(
                          color: const Color.fromARGB(255, 2, 83, 30), // Dark green circle
                          child: const Icon(
                            Icons.navigation,
                            color: Color.fromARGB(255, 199, 245, 200), // Light green arrow
                          ),
                        ),
                        markerSize: const Size(40, 40),
                        markerDirection: MarkerDirection.heading,
                        // Styled accuracy and heading indicators
                        accuracyCircleColor: const Color.fromARGB(255, 64, 124, 65).withOpacity(0.3),
                        headingSectorColor: const Color.fromARGB(255, 199, 245, 200).withOpacity(0.5),
                        headingSectorRadius: 60,
                      ),
                    ),
                  ],
                ),
                
                // Layer 2: Floating Search Bar and Buttons
                Positioned(
                  top: 40,
                  left: 15,
                  right: 15,
                  child: SafeArea(
                    child: Card(
                      elevation: 4.0,
                      color: const Color.fromARGB(255, 199, 245, 200),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                          Expanded(
                            child: TextField(
                              cursorColor: const Color.fromARGB(136, 0, 0, 0),
                              decoration: InputDecoration(
                                hintText: 'Search station...',
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(vertical: 12),
                              ),
                              onSubmitted: (value) {
                                // TODO: Implement search logic
                              },
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.tune),
                            onPressed: () {
                              // TODO: Implement filter logic
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                // Layer 3: Floating "My Location" Button
                Positioned(
                  bottom: 30,
                  right: 20,
                  child: FloatingActionButton(
                    backgroundColor: const Color.fromARGB(255, 199, 245, 200),
                    child: const Icon(Icons.my_location, color: Color.fromARGB(255, 2, 83, 30)),
                    onPressed: () {
                      // Send an event to re-center the map with a zoom level of 17
                      _centerOnLocationUpdateController.add(17.0);
                    },
                  ),
                ),
              ],
            ),
    );
  }
}