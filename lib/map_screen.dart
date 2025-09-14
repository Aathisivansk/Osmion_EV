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
    final url = Uri.parse('http://127.0.0.1:5000/api/stations');
    try {
      final response = await http.get(url);
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _allStations = List<Map<String, dynamic>>.from(data);
        _buildMarkers();
      }
    } catch (e) {
      debugPrint('Error fetching stations: $e');
    }
  }

  Color _getColorForChargerType(String chargerType) {
    switch (chargerType.toLowerCase()) {
      case 'ac': return _acColor;
      case 'dc': return _dcColor;
      case 'both': return _bothColor;
      default: return Colors.grey;
    }
  }

  void _buildMarkers() {
    final List<Marker> loadedMarkers = [];
    for (var station in _allStations) {
      final color = _getColorForChargerType(station['chargerType'] ?? 'unknown');
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
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (ctx) => StationDetailsSheet(station: station, distanceInMeters: distanceInMeters),
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

// The separate widget for the bottom sheet UI
class StationDetailsSheet extends StatelessWidget {
  final Map<String, dynamic> station;
  final double? distanceInMeters;

  const StationDetailsSheet({
    super.key,
    required this.station,
    this.distanceInMeters,
  });

  @override
  Widget build(BuildContext context) {
    // ... (This widget remains unchanged)
    final distanceInKm = distanceInMeters != null ? (distanceInMeters! / 1000).toStringAsFixed(1) : null;
    final rating = station['rating']?.toString() ?? 'N/A';
    final sockets = List<String>.from(station['sockets'] ?? []);
    final amenities = List<String>.from(station['amenities'] ?? []);

    return DraggableScrollableSheet(
      initialChildSize: 0.6, minChildSize: 0.3, maxChildSize: 0.9,
      builder: (_, controller) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: ListView(
            controller: controller,
            padding: const EdgeInsets.all(16),
            children: [
              Text(station['stationName'], style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(12)),
                  child: Row(children: [
                    const Icon(Icons.star, color: Colors.white, size: 16),
                    const SizedBox(width: 4),
                    Text(rating, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ]),
                ),
                const SizedBox(width: 12),
                Container(
                  ),
                  ]),
              if (distanceInKm != null) ...[
                const SizedBox(height: 8),
                Text('Distance: $distanceInKm km away', style: Theme.of(context).textTheme.bodyLarge),
              ],
              const Divider(height: 24),
              const Text('Sockets', style: TextStyle(fontWeight: FontWeight.bold)),
              Wrap(spacing: 8, children: sockets.map((socket) => Chip(label: Text(socket))).toList()),
              const Divider(height: 24),
              const Text('Amenities', style: TextStyle(fontWeight: FontWeight.bold)),
              Wrap(spacing: 8, children: amenities.map((amenity) => Chip(label: Text(amenity))).toList()),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue, foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Book Now'),
              ),
            ],
          ),
        );
      },
    );
  }
}