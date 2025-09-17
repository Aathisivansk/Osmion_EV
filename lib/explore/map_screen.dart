import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:osmion/slot_booking/stations_detail.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  final StreamController<double?> _alignPositionStreamController = StreamController<double?>();

  bool _isMapReady = false;
  LatLng? _initialCenter;

  LatLng? _currentUserLocation;
  StreamSubscription<Position>? _positionStreamSubscription;
  List<Map<String, dynamic>> _allStations = [];
  List<Marker> _stationMarkers = [];

  static const Color _acColor = Colors.orange;
  static const Color _dcColor = Colors.blue;
  static const Color _bothColor = Colors.green;

  @override
  void initState() {
    super.initState();
    _initializeLocationAndMap();
  }

  Future<void> _initializeLocationAndMap() async {
    // ... permission checks ...
    try {
      Position position = await Geolocator.getPositionStream(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 10),
      ).first;
      setState(() {
        _initialCenter = LatLng(position.latitude, position.longitude);
        _currentUserLocation = _initialCenter;
        _isMapReady = true;
      });
      _startListeningToLocation();
      _fetchChargingStations();
    } catch (e) {
      debugPrint("Error fetching initial location: $e");
      setState(() {
        _initialCenter = LatLng(12.9716, 77.5946); // Bangalore
        _isMapReady = true;
      });
      _fetchChargingStations();
    }
  }

  void _startListeningToLocation() {
    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 10),
    ).listen((Position position) {
      if (mounted) {
        setState(() {
          _currentUserLocation = LatLng(position.latitude, position.longitude);
        });
      }
    });
  }

  Future<void> _fetchChargingStations() async {
    final url = Uri.parse('http://10.62.58.114:5000/api/stations');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _allStations = List<Map<String, dynamic>>.from(data);
        _buildMarkers();
      }
    } catch (e) {
      debugPrint('Error fetching stations: $e');
    }
  }

  Color _getColorForChargerType(List<dynamic> chargers) {
    Set<String> types = chargers.map((c) => (c['chargerType'] as String).toLowerCase()).toSet();
    if (types.contains('ac') && types.contains('dc')) {
      return _bothColor;
    } else if (types.contains('dc')) {
      return _dcColor;
    } else if (types.contains('ac')) {
      return _acColor;
    }
    return Colors.grey;
  }


  void _buildMarkers() {
    final List<Marker> loadedMarkers = [];
    for (var station in _allStations) {
      final color = _getColorForChargerType(station['chargers'] ?? []);
      loadedMarkers.add(
        Marker(
          point: LatLng(station['latitude'], station['longitude']),
          width: 80,
          height: 80,
          child: GestureDetector(
            onTap: () => _showStationDetails(station),
            child: Icon(Icons.ev_station, color: color, size: 40),
          ),
        ),
      );
    }
    setState(() { _stationMarkers = loadedMarkers; });
  }

  void _showStationDetails(Map<String, dynamic> station) {
    double? distanceInMeters;
    if (_currentUserLocation != null) {
      distanceInMeters = Geolocator.distanceBetween(
        _currentUserLocation!.latitude, _currentUserLocation!.longitude,
        station['latitude'], station['longitude'],
      );
    }

    // --- UPDATED: Navigate to the full details page ---
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StationDetailsPage(
          station: StationDetails(
            name: station['stationName'] ?? 'Unknown',
            address: station['address'] ?? 'No address',
            rating: (station['stationRating'] as num?)?.toDouble() ?? 0.0,
            isOpen: true, // Assuming it's open
            distanceInKm: distanceInMeters != null ? (distanceInMeters / 1000) : 0.0,
            timing: station['timing'] ?? 'N/A',
            chargers: (station['chargers'] as List<dynamic>).map((c) => Charger(
              name: c['chargerName'],
              type: c['chargerType'],
              tariff: c['tariff'],
              rating: (c['chargerRating'] as num?)?.toDouble() ?? 0.0,
              isAvailable: c['isAvailable'],
            )).toList(),
          ),
        ),
      ),
    );
  }


  void _searchStation(String query) {
    // ... search logic ...
    String normalizeText(String text) {
      return text.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
    }
    final normalizedQuery = normalizeText(query);
    if (normalizedQuery.isEmpty) return;

    Map<String, dynamic>? foundStation;
    for (var station in _allStations) {
      final stationName = normalizeText(station['stationName'].toString());
      if (stationName.contains(normalizedQuery)) {
        foundStation = station;
        break;
      }
    }

    if (foundStation != null) {
      _mapController.move(
          LatLng(foundStation['latitude'], foundStation['longitude']), 18.0);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("No station found for '$query'"),
        backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating,
      ));
    }
  }

  @override
  void dispose() {
    _alignPositionStreamController.close();
    _positionStreamSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: !_isMapReady
          ? const Center(child: CircularProgressIndicator())
          : Stack(
        children: [
          // --- Layer 1: The Map ---
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _initialCenter!,
              initialZoom: 14.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.osmion',
              ),
              CurrentLocationLayer(
                alignPositionStream: _alignPositionStreamController.stream,
                alignPositionOnUpdate: AlignOnUpdate.never,
                alignDirectionOnUpdate: AlignOnUpdate.never,
                style: const LocationMarkerStyle(),
              ),
              MarkerLayer(markers: _stationMarkers),
            ],
          ),

          // --- FIX: All UI elements are now direct children of the Stack ---

          // --- Layer 2: Search Bar ---
          _buildSearchBar(),

          // --- Layer 3: Map Legend ---
          _buildMapLegend(),

          // --- Layer 4: My Location Button ---
          _buildMyLocationButton(),
        ],
      ),
    );
  }

  // --- Helper Widget for Search Bar ---
  Widget _buildSearchBar() {
    return Positioned(
      top: 40, left: 15, right: 15,
      child: SafeArea(
        child: Card(
          elevation: 4.0,
          color: const Color.fromARGB(255, 199, 245, 200),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  cursorColor: const Color.fromARGB(136, 0, 0, 0),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 16), // Added horizontal padding
                    hintText: 'Search station...',
                    isCollapsed: true, // Centers the hint text vertically
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
    );
  }

  // --- Helper Widget for Map Legend ---
  Widget _buildMapLegend() {
    return Positioned(
      bottom: 30, left: 20,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Legend', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              _LegendItem(color: _acColor, text: 'AC Charger'),
              _LegendItem(color: _dcColor, text: 'DC Charger'),
              _LegendItem(color: _bothColor, text: 'AC / DC Charger'),
            ],
          ),
        ),
      ),
    );
  }

  // --- Helper Widget for My Location Button ---
  Widget _buildMyLocationButton() {
    return Positioned(
      bottom: 30, right: 20,
      child: FloatingActionButton(
        backgroundColor: const Color.fromARGB(255, 199, 245, 200),
        child: const Icon(Icons.my_location, color: Color.fromARGB(255, 2, 83, 30)),
        onPressed: () => _alignPositionStreamController.add(17.0),
      ),
    );
  }
}

// Helper widget for a single legend item
class _LegendItem extends StatelessWidget {
  final Color color;
  final String text;
  const _LegendItem({required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          Container(width: 12, height: 12, color: color),
          const SizedBox(width: 8),
          Text(text),
        ],
      ),
    );
  }
}