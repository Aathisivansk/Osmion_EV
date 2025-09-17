import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'stations_detail.dart';

class BookingDetails {
  final String stationName;
  final String stationAddress;
  final Charger charger;
  final double capacity;
  final DateTime startTime;
  final DateTime endTime;
  final double bookingFee;

  BookingDetails({
    required this.stationName,
    required this.stationAddress,
    required this.charger,
    required this.capacity,
    required this.startTime,
    required this.endTime,
    required this.bookingFee,
  });
}

class InvoicePage extends StatefulWidget {
  final BookingDetails details;

  const InvoicePage({super.key, required this.details});

  @override
  State<InvoicePage> createState() => _InvoicePageState();
}

class _InvoicePageState extends State<InvoicePage> {
  double? _walletBalance;
  bool _isLoadingBalance = true;
  bool _isBooking = false;

  @override
  void initState() {
    super.initState();
    _fetchWalletBalance();
  }

  Future<void> _fetchWalletBalance() async {
    final prefs = await SharedPreferences.getInstance();
    final userEmail = prefs.getString('user_email');
    if (userEmail == null) {
      if (mounted) {
        setState(() {
          _isLoadingBalance = false;
          _walletBalance = 0;
        });
      }
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('http://10.62.58.114:5000/api/profile/$userEmail'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] && mounted) {
          setState(() {
            _walletBalance = (data['data']['walletBalance'] as num).toDouble();
            _isLoadingBalance = false;
          });
        }
      } else if (mounted) {
        setState(() => _isLoadingBalance = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingBalance = false);
      print("Failed to fetch balance: $e");
    }
  }

  Future<void> _confirmAndPayBooking() async {
    setState(() => _isBooking = true);

    final prefs = await SharedPreferences.getInstance();
    final userEmail = prefs.getString('user_email');
    if (userEmail == null) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("User not found")));
      setState(() => _isBooking = false);
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('http://10.62.58.114:5000/api/bookings/create'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_email': userEmail,
          'station_name': widget.details.stationName,
          'charger_name': widget.details.charger.name,
          'start_time': widget.details.startTime.toIso8601String(),
          'end_time': widget.details.endTime.toIso8601String(),
          'booking_fee': widget.details.bookingFee,
        }),
      );

      final data = json.decode(response.body);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message']),
            backgroundColor: response.statusCode == 201 ? Colors.green : Colors.red,
          ),
        );
        if (response.statusCode == 201) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('An error occurred: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isBooking = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF0A4F37);
    final Color headerColor = Colors.blue.shade700;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: headerColor,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.details.stationName, overflow: TextOverflow.ellipsis),
            Text(
              widget.details.stationAddress,
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
            _buildWalletCard(primaryColor),
            _buildDetailsCard(context),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(primaryColor),
    );
  }

  Widget _buildHeader(Color headerColor) {
    return Container(
      color: headerColor,
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Column(
        children: [
          Chip(
            label: Text('${widget.details.charger.name} | Charging Point 1'),
            backgroundColor: Colors.white.withOpacity(0.15),
            labelStyle: const TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 16),
          const Icon(Icons.electrical_services, color: Colors.white, size: 50),
          const SizedBox(height: 8),
          Text(
            widget.details.charger.type,
            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Vehicle Capacity: ${widget.details.capacity}kWh',
            style: TextStyle(color: Colors.white.withOpacity(0.8)),
          ),
          const SizedBox(height: 4),
          Text(
            widget.details.charger.tariff,
            style: TextStyle(color: Colors.white.withOpacity(0.8)),
          ),
        ],
      ),
    );
  }

  Widget _buildWalletCard(Color primaryColor) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Wallet',
                style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              _isLoadingBalance
                  ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator())
                  : Text(
                '₹ ${_walletBalance?.toStringAsFixed(2) ?? '0.00'}',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primaryColor),
              ),
            ],
          ),
          const Icon(Icons.arrow_drop_down, color: Colors.grey),
        ],
      ),
    );
  }

  Widget _buildDetailsCard(BuildContext context) {
    final int duration = widget.details.endTime.difference(widget.details.startTime).inMinutes;
    final double totalAmount = widget.details.bookingFee;

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
          _buildDetailRow('Booking fee', '₹ ${widget.details.bookingFee.toStringAsFixed(2)}'),
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
            _buildTimelinePoint(context, widget.details.startTime),
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
            _buildTimelinePoint(context, widget.details.endTime),
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
          onPressed: _isBooking ? null : _confirmAndPayBooking,
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            minimumSize: const Size(double.infinity, 50),
          ),
          child: _isBooking
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text('Confirm Booking'),
        ),
      ),
    );
  }

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

}