import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// --- DATA MODEL to hold all the necessary info for the invoice ---
class BookingDetails {
  final String stationName;
  final String stationAddress;
  final String chargerName;
  final String chargerType;
  final double capacity;
  final String tariff;
  final DateTime startTime;
  final DateTime endTime;
  // Note: These initial values are passed but will be recalculated in the UI
  // to ensure the new business logic is always applied.
  final double sessionCharges;
  final double bookingFee;
  final double totalAmount;

  BookingDetails({
    required this.stationName,
    required this.stationAddress,
    required this.chargerName,
    required this.chargerType,
    required this.capacity,
    required this.tariff,
    required this.startTime,
    required this.endTime,
    required this.sessionCharges,
    required this.bookingFee,
    required this.totalAmount,
  });
}

class InvoicePage extends StatelessWidget {
  final BookingDetails details;

  const InvoicePage({super.key, required this.details});

  // Function to show a styled Dialog Box for policy information
  void _showInfoDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0A4F37))),
          content: Text(message),
          actions: [
            TextButton(
              child: const Text('OK', style: TextStyle(color: Color(0xFF0A4F37), fontWeight: FontWeight.bold)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF0A4F37);
    final Color headerColor = Colors.blue.shade700;
    const double userWalletBalance = 0.00;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: headerColor,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(details.stationName, overflow: TextOverflow.ellipsis),
            Text(
              details.stationAddress,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(headerColor),
            _buildWalletCard(primaryColor, userWalletBalance, context),
            _buildDetailsCard(context),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(primaryColor),
    );
  }

  // --- UI HELPER WIDGETS ---

  Widget _buildHeader(Color headerColor) {
    return Container(
      color: headerColor,
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Column(
        children: [
          Chip(
            label: Text('${details.chargerName} | Charging Point 1'),
            backgroundColor: Colors.white.withOpacity(0.15),
            labelStyle: const TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 16),
          const Icon(Icons.electrical_services, color: Colors.white, size: 50),
          const SizedBox(height: 8),
          Text(
            details.chargerType,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Capacity: ${details.capacity}kW',
            style: TextStyle(color: Colors.white.withOpacity(0.8)),
          ),
          const SizedBox(height: 4),
          Text(
            details.tariff,
            style: TextStyle(color: Colors.white.withOpacity(0.8)),
          ),
        ],
      ),
    );
  }

  Widget _buildWalletCard(Color primaryColor, double balance, BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [ BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)) ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Osmion EV Charge Account',
                style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                '₹ ${balance.toStringAsFixed(2)}',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primaryColor),
              ),
            ],
          ),
          const Icon(Icons.arrow_drop_down, color: Colors.grey),
        ],
      ),
    );
  }

  // --- This widget now contains the updated calculation logic ---
  Widget _buildDetailsCard(BuildContext context) {
    final int duration = details.endTime.difference(details.startTime).inMinutes;

    // --- UPDATED CALCULATION LOGIC as per your request ---
    // Booking fee is now calculated at a rate of 120 per 30 mins (or 60 per 15 mins)
    final double bookingFee = (duration / 15) * 60.0;
    final double sessionCharges = (duration / 15) * 25.0;
    final double totalAmount = sessionCharges + bookingFee;

    return Container(
      margin: const EdgeInsets.all(16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSessionTimeline(context, duration),
          const SizedBox(height: 20),
          _buildDetailRow('Session charges (Estimated)', '₹ ${sessionCharges.toStringAsFixed(2)}'),
          const Divider(height: 24),
          _buildDetailRow('Booking fee', '₹ ${bookingFee.toStringAsFixed(2)}'),
          const SizedBox(height: 4),
          const Text(
            '(Non refundable)',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const Divider(height: 24),
          _buildDetailRow('Total amount to be paid', '₹ ${totalAmount.toStringAsFixed(2)}', isBold: true),
          const SizedBox(height: 24),
          _buildPolicyInfoSection(context),
        ],
      ),
    );
  }

  Widget _buildPolicyInfoSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          _buildClickableInfoText(
              context,
              'Cancellation charges will be applicable.',
              'Learn more',
              'Cancellation Policy',
              '100% of the Booking Fee shall be refunded if cancellation is done 72 to 12 hours prior to the booked slot start time.'
          ),
          const SizedBox(height: 8),
          _buildClickableInfoText(
              context,
              'Booking fee will be adjusted in the final invoice.',
              'Learn more',
              'Invoice Adjustment',
              'The initial booking fee will be deducted from your total session charges upon completion of charging.'
          ),
          const SizedBox(height: 8),
          _buildInfoText('Session charges are exclusive of discounts and taxes, they can vary as per the actual consumption.'),
          const SizedBox(height: 8),
          _buildInfoText('The last five minutes of your booked session is to remove the connector from your vehicle.'),
        ],
      ),
    );
  }

  Widget _buildSessionTimeline(BuildContext context, int duration) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Selected Session', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.edit, color: Colors.blue)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildTimelinePoint(context, details.startTime),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Column(
                  children: [
                    Text('$duration Mins', style: const TextStyle(fontWeight: FontWeight.bold)),
                    const Divider(),
                  ],
                ),
              ),
            ),
            _buildTimelinePoint(context, details.endTime),
          ],
        ),
      ],
    );
  }
  Widget _buildTimelinePoint(BuildContext context, DateTime time) {
    return Column(
      children: [
        Icon(Icons.circle, color: Theme.of(context).primaryColor, size: 16),
        const SizedBox(height: 4),
        Text(DateFormat('h:mm a').format(time), style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(DateFormat('d MMM yyyy').format(time), style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }

  Widget _buildDetailRow(String title, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: TextStyle(color: Colors.grey[600], fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: isBold ? 18 : 16)),
      ],
    );
  }

  Widget _buildClickableInfoText(BuildContext context, String text, String clickableText, String dialogTitle, String info) {
    return Text.rich(
        TextSpan(
            style: const TextStyle(color: Colors.orange, fontSize: 12, height: 1.5),
            children: [
              const TextSpan(text: '* '),
              TextSpan(text: text),
              const TextSpan(text: ' '),
              TextSpan(
                text: clickableText,
                style: const TextStyle(decoration: TextDecoration.underline, fontWeight: FontWeight.bold),
                recognizer: TapGestureRecognizer()..onTap = () {
                  _showInfoDialog(context, dialogTitle, info);
                },
              ),
            ]
        )
    );
  }

  Widget _buildInfoText(String text) {
    return Text.rich(
        TextSpan(
            style: const TextStyle(color: Colors.orange, fontSize: 12, height: 1.5),
            children: [
              const TextSpan(text: '* '),
              TextSpan(text: text),
            ]
        )
    );
  }

  Widget _buildBottomBar(Color primaryColor) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      color: Colors.white,
      child: SafeArea(
        child: ElevatedButton(
          onPressed: () {
            // TODO: Finalize booking and proceed to payment
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            minimumSize: const Size(double.infinity, 50),
          ),
          child: const Text('Confirm Booking'),
        ),
      ),
    );
  }
}

