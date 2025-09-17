import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

// Data model for a charging station for better type safety
class ChargingStation {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final List<String> sockets;
  final List<String> amenities;
  final double rating;

  ChargingStation({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.sockets,
    required this.amenities,
    required this.rating,
  });

  factory ChargingStation.fromJson(Map<String, dynamic> json) {
    // Handling MongoDB's ObjectId format which is often nested
    final idValue = json['_id'] is Map ? json['_id']['\$oid'] : json['_id'];
    return ChargingStation(
      id: idValue ?? '',
      name: json['stationName'] ?? 'Unknown Station',
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      sockets: List<String>.from(json['sockets'] ?? []),
      amenities: List<String>.from(json['amenities'] ?? []),
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class SlotBookingPage extends StatefulWidget {
  // This page accepts the user's vehicle connector type to filter stations
  final String userVehicleConnector;

  const SlotBookingPage({super.key, required this.userVehicleConnector});

  @override
  State<SlotBookingPage> createState() => _SlotBookingPageState();
}

class _SlotBookingPageState extends State<SlotBookingPage> {
  final MapController _mapController = MapController();

  bool _isMapReady = false;
  LatLng? _initialCenter;
  LatLng? _currentUserLocation;
  StreamSubscription<Position>? _positionStreamSubscription;

  List<ChargingStation> _allStations = [];
  List<Marker> _stationMarkers = [];

  // Consistent app styling colors
  static const Color _primaryColor = Color(0xFF0A4F37);
  static const Color _secondaryColor = Color(0xFFDDFCDA);
  static const Color _stationMarkerColor = Colors.blue; // Unified color for all stations

  @override
  void initState() {
    super.initState();
    _initializeLocationAndMap();
  }

  Future<void> _initializeLocationAndMap() async {
    // Check for location permissions
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          _initialCenter = const LatLng(11.0168, 76.9558); // Default to Coimbatore
          _isMapReady = true;
        });
        _fetchChargingStations();
        return;
      }
    }

    try {
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
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
        _initialCenter = const LatLng(11.0168, 76.9558); // Fallback to Coimbatore
        _isMapReady = true;
      });
      _fetchChargingStations();
    }
  }

  void _startListeningToLocation() {
    const LocationSettings locationSettings = LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 10);
    _positionStreamSubscription = Geolocator.getPositionStream(locationSettings: locationSettings).listen((Position position) {
      if (mounted) {
        setState(() {
          _currentUserLocation = LatLng(position.latitude, position.longitude);
        });
      }
    });
  }

  // This function sends the user's connector type to the server to get filtered results
  Future<void> _fetchChargingStations() async {
    final connector = widget.userVehicleConnector;

    // Build the URL with a query parameter to filter by connector
    // --- IMPORTANT: Replace with your computer's actual IP address ---
    final url = Uri.parse('http://192.168.1.5:5000/api/stations?connector=$connector');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _allStations = data.map((json) => ChargingStation.fromJson(json)).toList();
        _buildMarkers();
      } else {
        debugPrint("Server error: ${response.body}");
      }
    } catch (e) {
      debugPrint('Error fetching compatible stations: $e');
    }
  }

  // This function now uses a single unified blue color for all station markers
  void _buildMarkers() {
    final List<Marker> loadedMarkers = [];
    for (var station in _allStations) {
      loadedMarkers.add(
        Marker(
          point: LatLng(station.latitude, station.longitude),
          width: 80,
          height: 80,
          child: GestureDetector(
            onTap: () => _showStationDetails(station),
            child: const Icon(Icons.ev_station, color: _stationMarkerColor, size: 40),
          ),
        ),
      );
    }
    if(mounted) setState(() { _stationMarkers = loadedMarkers; });
  }

  void _showStationDetails(ChargingStation station) {
    double? distanceInMeters;
    if (_currentUserLocation != null) {
      distanceInMeters = Geolocator.distanceBetween(
        _currentUserLocation!.latitude, _currentUserLocation!.longitude,
        station.latitude, station.longitude,
      );
    }
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (ctx) => StationDetailsSheet(station: station, distanceInMeters: distanceInMeters),
    );
  }

  void _searchStation(String query) {
    String normalizeText(String text) => text.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
    final normalizedQuery = normalizeText(query);
    if (normalizedQuery.isEmpty) return;

    ChargingStation? foundStation;
    for (var station in _allStations) {
      if (normalizeText(station.name).contains(normalizedQuery)) {
        foundStation = station;
        break;
      }
    }

    if (foundStation != null) {
      _mapController.move(LatLng(foundStation.latitude, foundStation.longitude), 15.0);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("No station found for '$query'"),
        backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating,
      ));
    }
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: !_isMapReady
          ? const Center(child: CircularProgressIndicator(color: _primaryColor))
          : Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _initialCenter!,
              initialZoom: 14.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.osmion.ev',
              ),
              CurrentLocationLayer(),
              MarkerLayer(markers: _stationMarkers),
            ],
          ),
          _buildSearchBar(),
          _buildMyLocationButton(),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Positioned(
      top: 40, left: 15, right: 15,
      child: SafeArea(
        child: Card(
          elevation: 6.0,
          color: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.menu, color: _primaryColor),
                onPressed: () { /* TODO: Open a navigation drawer */ },
              ),
              Expanded(
                child: TextField(
                  cursorColor: _primaryColor,
                  decoration: const InputDecoration(
                    hintText: 'Search compatible stations...',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 15),
                  ),
                  onSubmitted: _searchStation,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMyLocationButton() {
    return Positioned(
      bottom: 30, right: 15,
      child: FloatingActionButton(
        backgroundColor: _secondaryColor,
        child: const Icon(Icons.my_location, color: _primaryColor),
        onPressed: () {
          if(_currentUserLocation != null) {
            _mapController.move(_currentUserLocation!, 15.0);
          }
        },
      ),
    );
  }
}

// The bottom sheet for showing station details
class StationDetailsSheet extends StatelessWidget {
  final ChargingStation station;
  final double? distanceInMeters;

  const StationDetailsSheet({
    super.key,
    required this.station,
    this.distanceInMeters,
  });

  @override
  Widget build(BuildContext context) {
    final distanceInKm = distanceInMeters != null ? (distanceInMeters! / 1000).toStringAsFixed(1) : null;
    return DraggableScrollableSheet(
      initialChildSize: 0.5, minChildSize: 0.3, maxChildSize: 0.9,
      builder: (_, controller) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: ListView(
            controller: controller,
            padding: const EdgeInsets.all(20),
            children: [
              Text(station.name, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(12)),
                  child: Row(children: [
                    const Icon(Icons.star, color: Colors.white, size: 16),
                    const SizedBox(width: 4),
                    Text(station.rating.toString(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ]),
                ),
                if (distanceInKm != null) ...[
                  const SizedBox(width: 12),
                  Text('$distanceInKm km away', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey[700])),
                ],
              ]),
              const Divider(height: 32),
              const Text('Available Sockets', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 8, children: station.sockets.map((socket) => Chip(label: Text(socket))).toList()),
              const Divider(height: 32),
              const Text('Amenities', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 8, children: station.amenities.map((amenity) => Chip(label: Text(amenity))).toList()),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  // TODO: Navigate to the full station details page
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0A4F37), foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                ),
                child: const Text('Book Slot', style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
        );
      },
    );
  }
}

