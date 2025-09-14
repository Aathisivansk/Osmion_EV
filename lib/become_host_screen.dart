// lib/become_host_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'hosting_session.dart';
import 'host_api_service.dart';

class BecomeHostScreen extends StatefulWidget {
  const BecomeHostScreen({super.key});

  @override
  State<BecomeHostScreen> createState() => _BecomeHostScreenState();
}

class _BecomeHostScreenState extends State<BecomeHostScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isHosting = false;
  bool _isLoading = false;

  // Form controllers
  final _locationController = TextEditingController();
  final _socketTypeController = TextEditingController();
  final _durationController = TextEditingController();
  final _priceController = TextEditingController();
  final _contactController = TextEditingController();

  final HostApiService _apiService = HostApiService();

  @override
  void dispose() {
    // Clean up controllers
    _locationController.dispose();
    _socketTypeController.dispose();
    _durationController.dispose();
    _priceController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  Future<void> _submitHostingDetails() async {
    // Only submit if the user is hosting and the form is valid
    if (_isHosting && _formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final durationHours = int.parse(_durationController.text);
        final availableUntil = DateTime.now().add(Duration(hours: durationHours));
        
        final session = HostingSession(
          isHosting: _isHosting,
          location: _locationController.text,
          socketType: _socketTypeController.text,
          availableUntil: availableUntil,
          pricePerHour: double.parse(_priceController.text),
          contactDetails: _contactController.text,
        );

        await _apiService.createHostingSession(session);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Success! You are now a host.'),
            backgroundColor: Colors.green,
          ),
        );
        // Optionally, navigate away or clear the form
        Navigator.of(context).pop();

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
    } else if (!_isHosting) {
       ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enable the hosting switch first.'),
            backgroundColor: Colors.orange,
          ),
        );
    }
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
              // --- The Hosting Toggle Switch ---
              Card(
                elevation: 2,
                child: SwitchListTile(
                  title: Text(
                    _isHosting ? 'Hosting is ON' : 'Hosting is OFF',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _isHosting ? Colors.green : Colors.grey,
                    ),
                  ),
                  subtitle: const Text('Toggle to make your charging point public'),
                  value: _isHosting,
                  onChanged: (bool value) {
                    setState(() {
                      _isHosting = value;
                    });
                  },
                  activeColor: Colors.green,
                ),
              ),
              const SizedBox(height: 24),

              // --- Conditional Form ---
              if (_isHosting) ...[
                Text('Hosting Details', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _locationController,
                  decoration: const InputDecoration(labelText: 'Location (e.g., Address or Landmark)', border: OutlineInputBorder()),
                  validator: (value) => value!.isEmpty ? 'Please enter a location' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _socketTypeController,
                  decoration: const InputDecoration(labelText: 'Charging Socket Type (e.g., Type 2, CCS)', border: OutlineInputBorder()),
                   validator: (value) => value!.isEmpty ? 'Please enter a socket type' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _durationController,
                  decoration: const InputDecoration(labelText: 'Availability (in hours from now)', border: OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                   validator: (value) => value!.isEmpty ? 'Please enter a duration' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _priceController,
                  decoration: const InputDecoration(labelText: 'Price per Hour (₹)', border: OutlineInputBorder()),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (value) => value!.isEmpty ? 'Please enter a price' : null,
                ),
                 const SizedBox(height: 16),
                TextFormField(
                  controller: _contactController,
                  decoration: const InputDecoration(labelText: 'Contact Details (e.g., Phone Number)', border: OutlineInputBorder()),
                  keyboardType: TextInputType.phone,
                  validator: (value) => value!.isEmpty ? 'Please enter contact details' : null,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitHostingDetails,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(fontSize: 18)
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Go Live'),
                  ),
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }
}