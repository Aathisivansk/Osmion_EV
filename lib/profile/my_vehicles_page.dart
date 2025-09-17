import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class Vehicle {
  final String id;
  final String model;
  final String connectorType;
  final String registrationNumber;
  final double? capacity; // Now includes capacity

  Vehicle({
    required this.id,
    required this.model,
    required this.connectorType,
    required this.registrationNumber,
    this.capacity,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      id: json['_id'] ?? '',
      model: json['model'] ?? 'Unknown Model',
      connectorType: json['connectorType'] ?? 'N/A',
      registrationNumber: json['registrationNumber'] ?? 'N/A',
      capacity: (json['capacity'] as num?)?.toDouble(), // Parse capacity
    );
  }
}

class MyVehiclesPage extends StatefulWidget {
  const MyVehiclesPage({super.key});

  @override
  State<MyVehiclesPage> createState() => _MyVehiclesPageState();
}

class _MyVehiclesPageState extends State<MyVehiclesPage> {
  List<Vehicle> _vehicles = [];
  bool _isLoading = true;
  String? _errorMessage;

  final String baseUrl = "http://10.62.58.114:5000";

  @override
  void initState() {
    super.initState();
    _loadVehicles();
  }

  Future<void> _loadVehicles() async {
    final prefs = await SharedPreferences.getInstance();
    final userEmail = prefs.getString('user_email');

    if (userEmail == null) {
      setState(() {
        _errorMessage = "Could not find user email. Please log in again.";
        _isLoading = false;
      });
      return;
    }

    try {
      final response = await http.get(Uri.parse('$baseUrl/api/vehicles/$userEmail'));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse['success'] == true) {
          final List<dynamic> vehiclesData = jsonResponse['data'];
          setState(() {
            _vehicles = vehiclesData.map((data) => Vehicle.fromJson(data)).toList();
            _isLoading = false;
          });
        } else {
          throw Exception(jsonResponse['message']);
        }
      } else {
        throw Exception('Failed to load vehicles from server.');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _navigateToAddVehicle() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Add vehicle page will be implemented by the team'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Vehicles'),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddVehicle,
        child: const Icon(Icons.add),
        tooltip: 'Add Vehicle',
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(child: Text('Error: $_errorMessage'))
          : _vehicles.isEmpty
          ? _buildEmptyState()
          : _buildVehiclesList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.directions_car_outlined, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('No vehicles added yet', style: TextStyle(fontSize: 18, color: Colors.grey)),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _navigateToAddVehicle,
            child: const Text('Add Your First Vehicle'),
          ),
        ],
      ),
    );
  }

  Widget _buildVehiclesList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _vehicles.length,
      itemBuilder: (context, index) {
        final vehicle = _vehicles[index];
        return _buildVehicleCard(vehicle);
      },
    );
  }

  Widget _buildVehicleCard(Vehicle vehicle) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  vehicle.model,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildVehicleDetail('Connector', vehicle.connectorType),
            _buildVehicleDetail('Registration Number', vehicle.registrationNumber),
            if (vehicle.capacity != null) // Display capacity if it exists
              _buildVehicleDetail('Battery Capacity', '${vehicle.capacity} kWh'),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value, style: TextStyle(color: Colors.grey[700])),
        ],
      ),
    );
  }
}