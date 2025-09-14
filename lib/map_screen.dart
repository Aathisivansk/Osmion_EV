import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();

  // Use a StreamController<double?> for alignPositionStream (zoom level optional)
  final StreamController<double?> _alignPositionStreamController =
      StreamController<double?>();

  bool _isMapReady = false;
  LatLng? _initialCenter;

  List<Map<String, dynamic>> _allStations = [];
  List<Marker> _stationMarkers = [];

  @override
  void initState() {
    super.initState();
    _initializeLocationAndMap().then((_) {
      if (mounted) {
        _fetchChargingStations();
      }
    });
  }

  Future<void> _initializeLocationAndMap() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
    }
    try {
      Position position = await Geolocator.getPositionStream(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 1),
      ).first;
      setState(() {
        _initialCenter = LatLng(position.latitude, position.longitude);
        _isMapReady = true;
      });
    } catch (e) {
      // fallback center (Bangalore)
      debugPrint("Error fetching initial location: $e");
      setState(() {
        _initialCenter = LatLng(12.9716, 77.5946);
        _isMapReady = true;
      });
    }
  }

  Future<void> _fetchChargingStations() async {
  // Make sure to use your actual server IP, 10.0.2.2 is for the Android Emulator
  final url = Uri.parse('http://10.62.58.114:5000/api/stations');

  try {
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      
      // DEBUG PRINT: Check if data is loaded and how many stations.
      print('--- API FETCH SUCCESS ---');
      print('Loaded ${data.length} stations from the API.');
      if (data.isNotEmpty) {
        // DEBUG PRINT: Check the raw name of the first station. Quotes will reveal whitespace.
        print('Raw name of first station: "${data[0]['stationName']}"');
      }
      print('--------------------------');

      _allStations = List<Map<String, dynamic>>.from(data);

      final List<Marker> loadedMarkers = [];
      for (var station in _allStations) {
        loadedMarkers.add(
          Marker(
            point: LatLng(station['latitude'], station['longitude']),
            width: 80,
            height: 80,
            child: GestureDetector(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text(station['stationName']),
                    content: Text('Coordinates: ${station['latitude']}, ${station['longitude']}'),
                    actions: [ TextButton(child: const Text('Close'), onPressed: () => Navigator.of(context).pop()) ],
                  ),
                );
              },
              child: const Icon(Icons.ev_station, color: Colors.purpleAccent, size: 40),
            ),
          ),
        );
      }
      setState(() {
        _stationMarkers = loadedMarkers;
      });
    }
  } catch (e) {
    // DEBUG PRINT: Show any error during the fetch.
    print('--- API FETCH ERROR ---');
    print('Error fetching stations: $e');
    print('-----------------------');
  }
}

  // NEW: A more robust search function
void _searchStation(String query) {
  // DEBUG PRINT: Show the original search term from the text field.
  print('\n--- STARTING SEARCH ---');
  print('Original search query: "$query"');

  if (query.isEmpty) {
    return;
  }

  String normalizeText(String text) {
    return text
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), ' ');
  }

  final normalizedQuery = normalizeText(query);
  Map<String, dynamic>? foundStation;
  
  // DEBUG PRINT: Show the cleaned-up search term.
  print('Normalized query: "$normalizedQuery"');
  print('--- Comparing against all ${_allStations.length} stations ---');

  for (var station in _allStations) {
    final stationName = normalizeText(station['stationName'].toString());

    // DEBUG PRINT: Show the comparison for EACH station in your list.
    print('Comparing WITH normalized station name: "$stationName"');
    
    bool isMatch = stationName.contains(normalizedQuery);
    // DEBUG PRINT: Show if the comparison resulted in a match.
    print(' -> Match found: $isMatch');

    if (isMatch) {
      foundStation = station;
      break;
    }
  }

  print('--- SEARCH FINISHED ---');
  // DEBUG PRINT: Announce the final result.
  print('Final result: ${foundStation != null ? 'Station Found!' : 'No Station Found.'}');


  if (foundStation != null) {
    _mapController.move(
      LatLng(foundStation['latitude'], foundStation['longitude']),
      18.0,
    );
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("No station found for '$query'"),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

  @override
  void dispose() {
    _alignPositionStreamController.close();
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
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.osmion',
                    ),

                    // FIXED: use alignPositionStream (Stream<double?>) and AlignOnUpdate
                    CurrentLocationLayer(
                      alignPositionStream: _alignPositionStreamController.stream,
                      alignPositionOnUpdate: AlignOnUpdate.never,
                      alignDirectionOnUpdate: AlignOnUpdate.never,
                      style: const LocationMarkerStyle(), // default style
                    ),

                    MarkerLayer(markers: _stationMarkers),
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
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
                                _searchStation(value);
                              },
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.tune),
                            onPressed: () {},
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
                    child: const Icon(Icons.my_location, color: Color.fromARGB(255, 2, 83, 30)),
                    // send a zoom level (double) or `null` to keep current zoom
                    onPressed: () => _alignPositionStreamController.add(17.0),
                  ),
                ),
              ],
            ),
    );
  }
}
