import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:geolocator/geolocator.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  bool _isMapReady = false;
  LatLng? _initialCenter;
  StreamSubscription<Position>? _positionStreamSubscription;
  bool _followUser = false; // State to control follow behavior

  @override
  void initState() {
    super.initState();
    _initializeLocationAndMap();
  }

  Future<void> _initializeLocationAndMap() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        // Handle case where permission is still denied
        print("Location permission denied.");
        setState(() {
          _initialCenter = LatLng(12.9716, 77.5946); // Default to Bangalore
          _isMapReady = true;
        });
        return;
      }
    }

    try {
      Position position = await Geolocator.getCurrentPosition( // Get initial position once
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _initialCenter = LatLng(position.latitude, position.longitude);
        _isMapReady = true;
        _followUser = true; // Optionally start following by default
      });

      // Start listening to position updates for continuous tracking if _followUser is true
      _startFollowingUser();

    } catch (e) {
      print("Error fetching initial location: $e");
      setState(() {
        _initialCenter = LatLng(12.9716, 77.5946); // Bangalore
        _isMapReady = true;
      });
    }
  }

  void _startFollowingUser() {
    if (_followUser) {
      _positionStreamSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 1, // Update map on every 1 meter change for smoother follow
        ),
      ).listen((Position? position) {
        if (position != null && _isMapReady && _followUser) {
          _mapController.move(
            LatLng(position.latitude, position.longitude),
            _mapController.camera.zoom, // Keep current zoom when following
          );
        }
      });
    }
  }

  void _stopFollowingUser() {
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    _mapController.dispose(); // Dispose map controller
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: !_isMapReady
          ? const Center(child: CircularProgressIndicator())
          : Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _initialCenter!,
              initialZoom: 17.0,
              onPositionChanged: (MapCamera camera, bool hasGesture) {
                if (hasGesture && _followUser) {
                  // User interacted with the map, stop following
                  setState(() {
                    _followUser = false;
                  });
                  _stopFollowingUser();
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.osmion',
              ),
              CurrentLocationLayer(
                style: LocationMarkerStyle(
                  marker: DefaultLocationMarker(
                    color: const Color.fromARGB(255, 2, 83, 30),
                    child: const Icon(
                      Icons.navigation,
                      color: Color.fromARGB(255, 199, 245, 200),
                    ),
                  ),
                  markerSize: const Size(40, 40),
                  markerDirection: MarkerDirection.heading,
                  accuracyCircleColor: const Color.fromARGB(255, 64, 124, 65).withOpacity(0.3),
                  headingSectorColor: const Color.fromARGB(255, 199, 245, 200).withOpacity(0.5),
                  headingSectorRadius: 60,
                ),
              ),
            ],
          ),
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
                        decoration: const InputDecoration(
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
          Positioned(
            bottom: 30,
            right: 20,
            child: FloatingActionButton(
              backgroundColor: const Color.fromARGB(255, 199, 245, 200),
              onPressed: () async {
                if (!_followUser) {
                  // If not currently following, center and start following
                  setState(() {
                    _followUser = true;
                  });
                  _stopFollowingUser(); // Ensure any previous stream is cancelled
                  try {
                    Position position = await Geolocator.getCurrentPosition(
                        desiredAccuracy: LocationAccuracy.high);
                    _mapController.move(
                      LatLng(position.latitude, position.longitude),
                      17.0, // Zoom to desired level when FAB is pressed
                    );
                    _startFollowingUser(); // Start continuous following
                  } catch (e) {
                    print("Error getting current location for FAB: $e");
                    setState(() {
                      _followUser = false; // Revert state on error
                    });
                  }
                } else {
                  // If already following, pressing the button might just ensure centering
                  // Or you could make it toggle _followUser off
                  try {
                    Position position = await Geolocator.getCurrentPosition(
                        desiredAccuracy: LocationAccuracy.high);
                    _mapController.move(
                      LatLng(position.latitude, position.longitude),
                      17.0,
                    );
                  } catch (e) {
                    print("Error getting current location for FAB: $e");
                  }
                }
              },
              child: Icon(
                _followUser ? Icons.my_location : Icons.location_searching,
                color: const Color.fromARGB(255, 2, 83, 30),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
