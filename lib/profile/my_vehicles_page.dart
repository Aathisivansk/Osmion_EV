import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class Vehicle {
  final String id;
  final String model;
  final String connectorType;
  final String chargerType;
  final String registrationNumber;

  Vehicle({
    required this.id,
    required this.model,
    required this.connectorType,
    required this.chargerType,
    required this.registrationNumber,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      id: json['_id'] ?? json['id'] ?? '',
      model: json['model'] ?? '',
      connectorType: json['connectorType'] ?? '',
      chargerType: json['chargerType'] ?? '',
      registrationNumber: json['registrationNumber'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'model': model,
      'connectorType': connectorType,
      'chargerType': chargerType,
      'registrationNumber': registrationNumber,
    };
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
  final String baseUrl = "http://10.0.2.2:5001";

  @override
  void initState() {
    super.initState();
    print('🔄 MyVehiclesPage initState called');
    _loadVehicles();
  }

  Future<void> _loadVehicles() async {
    print('🌐 Loading vehicles from backend...');

    // For now, use test data since backend isn't ready
    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      _vehicles = [
        Vehicle(
          id: '1',
          model: 'Mahendra BE 6',
          connectorType: 'CCS-2',
          chargerType: 'AC Type-2',
          registrationNumber: 'TN5865000',
        ),
      ];
      _isLoading = false;
    });
    print('✅ Loaded ${_vehicles.length} vehicles');
  }

  void _navigateToAddVehicle() {
    print('➕ Add vehicle button pressed - navigating to add vehicle page');
    // This will navigate to the page your teammates are creating
    // For now, show a message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Add vehicle page will be implemented by the team'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _deleteVehicle(String vehicleId) async {
    print('🗑️ Delete vehicle: $vehicleId');
    setState(() {
      _vehicles.removeWhere((vehicle) => vehicle.id == vehicleId);
    });
    print('✅ Vehicle deleted');

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Vehicle deleted'),
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
          const Text(
            'No vehicles added yet',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
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
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                  onPressed: () => _deleteVehicle(vehicle.id),
                  tooltip: 'Delete Vehicle',
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildVehicleDetail('Connector', vehicle.connectorType),
            _buildVehicleDetail('Charger Type', vehicle.chargerType),
            _buildVehicleDetail('Registration Number', vehicle.registrationNumber),
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
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Text(
            value,
            style: TextStyle(color: Colors.grey[700]),
          ),
        ],
      ),
    );
  }
}