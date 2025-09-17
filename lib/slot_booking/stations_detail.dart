import 'package:flutter/material.dart';
import 'select_slot_page.dart'; // Import the new slot selection page

// --- DATA MODELS ---
// These data models structure the information for this page.
// In a real app, you might move these to a separate 'models' file.

class Charger {
  final String name;
  final String type;
  final String tariff;
  final double rating;
  final bool isAvailable;

  Charger({
    required this.name,
    required this.type,
    required this.tariff,
    required this.rating,
    required this.isAvailable,
  });
}

class StationDetails {
  final String name;
  final String address;
  final double rating;
  final bool isOpen;
  final double distanceInKm;
  final String timing;
  final List<Charger> chargers;

  StationDetails({
    required this.name,
    required this.address,
    required this.rating,
    required this.isOpen,
    required this.distanceInKm,
    required this.timing,
    required this.chargers,
  });
}

class StationDetailsPage extends StatelessWidget {
  final StationDetails station;

  const StationDetailsPage({super.key, required this.station});

  @override
  Widget build(BuildContext context) {
    const Color primaryTextColor = Color(0xFF0A4F37);
    const Color secondaryTextColor = Colors.black54;
    const Color openColor = Colors.green;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: primaryTextColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 8),
            Text(station.address, style: const TextStyle(color: secondaryTextColor, fontSize: 16)),
            const SizedBox(height: 16),
            _buildStatusRow(openColor),
            const SizedBox(height: 16),
            _buildInfoRow(context, primaryTextColor),
            const Divider(height: 32),
            _buildChargerSection(context, primaryTextColor),
          ],
        ),
      ),
    );
  }

  // Helper widget for the page header
  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            station.name,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ),
        Chip(
          label: const Text('Public', style: TextStyle(color: Colors.blue)),
          backgroundColor: Colors.blue.withOpacity(0.1),
        ),
      ],
    );
  }

  // Helper widget for the status and rating
  Widget _buildStatusRow(Color openColor) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(color: openColor, borderRadius: BorderRadius.circular(12)),
          child: Row(
            children: [
              const Icon(Icons.star, color: Colors.white, size: 16),
              const SizedBox(width: 4),
              Text(station.rating.toString(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Icon(Icons.circle, color: station.isOpen ? openColor : Colors.red, size: 12),
        const SizedBox(width: 6),
        Text(station.isOpen ? 'Open' : 'Closed', style: TextStyle(color: station.isOpen ? openColor : Colors.red, fontWeight: FontWeight.bold)),
      ],
    );
  }

  // Helper widget for distance and timing info
  Widget _buildInfoRow(BuildContext context, Color primaryColor) {
    return Row(
      children: [
        Icon(Icons.location_on, color: primaryColor, size: 18),
        const SizedBox(width: 4),
        Text('${station.distanceInKm} Km'),
        const SizedBox(width: 16),
        Icon(Icons.access_time_filled, color: primaryColor, size: 18),
        const SizedBox(width: 4),
        Text(station.timing),
      ],
    );
  }

  // Helper widget for the list of available chargers
  Widget _buildChargerSection(BuildContext context, Color primaryColor) {
    final availableChargers = station.chargers.where((c) => c.isAvailable).length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Available Connectors  $availableChargers/${station.chargers.length}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            OutlinedButton.icon(
              onPressed: () {
                // TODO: Add navigation logic using a package like 'url_launcher'
              },
              icon: const Icon(Icons.near_me),
              label: const Text('Navigate'),
              style: OutlinedButton.styleFrom(
                foregroundColor: primaryColor,
                side: BorderSide(color: primaryColor),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
            )
          ],
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.75,
          ),
          itemCount: station.chargers.length,
          itemBuilder: (context, index) {
            final charger = station.chargers[index];
            return _buildChargerCard(context, charger, primaryColor);
          },
        ),
      ],
    );
  }

  // Helper widget for a single charger card
  Widget _buildChargerCard(BuildContext context, Charger charger, Color primaryColor) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: charger.isAvailable ? Colors.green : Colors.grey.shade300)
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(charger.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                      color: charger.isAvailable ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8)
                  ),
                  child: Text(
                    charger.isAvailable ? 'Available' : 'Occupied',
                    style: TextStyle(
                      color: charger.isAvailable ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const Spacer(),
            Center(child: Icon(Icons.electrical_services, size: 40, color: primaryColor.withOpacity(0.8))),
            const SizedBox(height: 8),
            Center(child: Text(charger.type, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) => Icon(i < charger.rating ? Icons.star : Icons.star_border, color: Colors.amber, size: 20)),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(charger.tariff, style: const TextStyle(color: Colors.grey, fontSize: 14)),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                // Only enable the button if the charger is available
                onPressed: charger.isAvailable ? () {
                  // --- UPDATED: This now navigates to the slot selection page ---
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SelectSlotPage()),
                  );
                } : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade300,
                ),
                child: const Text('Book Now'),
              ),
            )
          ],
        ),
      ),
    );
  }
}

