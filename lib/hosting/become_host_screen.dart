// lib/become_host_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'hosting_session.dart';
import 'host_api_services.dart';

class BecomeHostScreen extends StatefulWidget {
  const BecomeHostScreen({super.key});

  @override
  State<BecomeHostScreen> createState() => _BecomeHostScreenState();
}

class _BecomeHostScreenState extends State<BecomeHostScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isHosting = false;
  bool _isLoading = false;
  bool _detailsSaved = false;
  String? _selectedSocketType;

  // Form controllers
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
  final _durationController = TextEditingController();
  final _priceController = TextEditingController();
  final _contactController = TextEditingController();

  final HostApiService _apiService = HostApiService();

  @override
  void dispose() {
    _latitudeController.dispose();
    _longitudeController.dispose();
    _durationController.dispose();
    _priceController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  Future<void> _saveHostingDetails() async {
    if (_selectedSocketType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a charging socket type.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final durationHours = int.parse(_durationController.text);
        final availableUntil =
        DateTime.now().add(Duration(hours: durationHours));

        final String locationString =
            '${_latitudeController.text}, ${_longitudeController.text}';

        final session = HostingSession(
          isHosting: _isHosting, // Sends the current toggle state
          location: locationString,
          socketType: _selectedSocketType!,
          availableUntil: availableUntil,
          pricePerHour: double.parse(_priceController.text),
          contactDetails: _contactController.text,
        );

        await _apiService.createHostingSession(session);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Success! Details saved. You can now go live.'),
            backgroundColor: Colors.green,
          ),
        );

        setState(() {
          _detailsSaved = true;
          // MODIFIED: No longer automatically turning the toggle on.
          // _isHosting = true; // This line was removed.
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An error occurred: $e'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  // NEW: Function to update hosting status when toggle is flipped
  Future<void> _updateHostingStatus(bool newStatus) async {

    setState(() {
      _isHosting = newStatus;

    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Become a Charging Host'),
        backgroundColor: Colors.deepPurple,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                elevation: 2,
                child: SwitchListTile(
                  title: Text(
                    _isHosting ? 'Hosting is ON' : 'Hosting is OFF',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _detailsSaved && _isHosting
                          ? Colors.green
                          : Colors.grey,
                    ),
                  ),
                  subtitle: Text(
                    _detailsSaved
                        ? 'Toggle to make your charging point public'
                        : 'Please save details below to enable hosting',
                  ),
                  value: _isHosting,
                  onChanged: _detailsSaved
                      ? (bool value) {
                    _updateHostingStatus(value);
                  }
                      : null,
                  activeColor: Colors.green,
                ),
              ),
              const SizedBox(height: 24),
              Text('Hosting Details',
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _latitudeController,
                      decoration: const InputDecoration(
                        labelText: 'Latitude',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true, signed: true),
                      validator: (value) =>
                      value!.isEmpty ? 'Enter latitude' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _longitudeController,
                      decoration: const InputDecoration(
                        labelText: 'Longitude',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true, signed: true),
                      validator: (value) =>
                      value!.isEmpty ? 'Enter longitude' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text('Charging Socket Type',
                  style: TextStyle(fontSize: 16)),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('Type 2'),
                      value: 'Type 2',
                      groupValue: _selectedSocketType,
                      onChanged: (value) =>
                          setState(() => _selectedSocketType = value),
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('CCS'),
                      value: 'CCS',
                      groupValue: _selectedSocketType,
                      onChanged: (value) =>
                          setState(() => _selectedSocketType = value),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _durationController,
                decoration: const InputDecoration(
                    labelText: 'Availability (in hours from now)',
                    border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) =>
                value!.isEmpty ? 'Please enter a duration' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(
                    labelText: 'Price per Hour (₹)',
                    border: OutlineInputBorder()),
                keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
                validator: (value) =>
                value!.isEmpty ? 'Please enter a price' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _contactController,
                decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    border: OutlineInputBorder()),
                keyboardType: TextInputType.phone,
                validator: (value) =>
                value!.isEmpty ? 'Please enter contact details' : null,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed:
                  _isLoading || _detailsSaved ? null : _saveHostingDetails,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    disabledBackgroundColor: Colors.grey.shade400,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                  // MODIFIED: Changed button text
                      : Text(_detailsSaved ? 'Details Saved' : 'Save Details'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}