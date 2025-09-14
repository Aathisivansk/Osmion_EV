import 'package:flutter/material.dart';
import 'edit_detail_page.dart';
import 'profile_page.dart'; // This import is crucial. It tells this file where to find UserData.
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class MyAccountScreen extends StatefulWidget {
  final UserData userData;

  const MyAccountScreen({super.key, required this.userData});

  @override
  State<MyAccountScreen> createState() => _MyAccountScreenState();
}

class _MyAccountScreenState extends State<MyAccountScreen> {
  late UserData _editableUserData;
  bool _isSaving = false;

  final String baseUrl = "http://10.62.58.114:5000";

  @override
  void initState() {
    super.initState();
    _editableUserData = UserData.fromJson({
      "name": widget.userData.name,
      "email": widget.userData.email,
      "mobileNumber": widget.userData.mobileNumber,
      "pinCode": widget.userData.pinCode,
      "address": widget.userData.address,
    });
  }

  Future<void> _updateProfileOnServer() async {
    setState(() {
      _isSaving = true;
    });
    final prefs = await SharedPreferences.getInstance();
    final userEmail = prefs.getString('user_email');

    try {
      // FIX 2: Added the "/api" prefix to the endpoint to match your server routes.
      final Uri requestUri = Uri.parse('$baseUrl/api/profile/$userEmail');

      // For debugging: print the exact URL you are calling
      print('Attempting to PUT to: $requestUri');

      final response = await http.put(
        requestUri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'name': _editableUserData.name,
          'mobileNumber': _editableUserData.mobileNumber,
          'pinCode': _editableUserData.pinCode,
          'address': _editableUserData.address,
        }),
      );

      // For debugging: print the server's response
      print('Response Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (!mounted) return;

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to update: ${jsonResponse['message']}')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Server error: ${response.statusCode}')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Network error: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _navigateToEditPage(String field) async {
    String currentValue = '';
    switch (field) {
      case 'Name':
        currentValue = _editableUserData.name;
        break;
      case 'Mobile Number':
        currentValue = _editableUserData.mobileNumber;
        break;
      case 'PIN Code':
        currentValue = _editableUserData.pinCode ?? '';
        break;
      case 'Address':
        currentValue = _editableUserData.address ?? '';
        break;
    }

    final newValue = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => EditDetailPage(title: field, currentValue: currentValue)),
    );

    if (newValue != null && newValue.isNotEmpty && mounted) {
      setState(() {
        switch (field) {
          case 'Name':
            _editableUserData.name = newValue;
            break;
          case 'Mobile Number':
            _editableUserData.mobileNumber = newValue;
            break;
          case 'PIN Code':
            _editableUserData.pinCode = newValue;
            break;
          case 'Address':
            _editableUserData.address = newValue;
            break;
        }
      });
      _updateProfileOnServer();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        Navigator.of(context).pop(_editableUserData);
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Account'),
          centerTitle: true,
          actions: [
            if (_isSaving)
              const Padding(
                padding: EdgeInsets.only(right: 16.0),
                child: Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                  ),
                ),
              ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Personal Info', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  _buildInfoRow(
                    title: 'Name',
                    value: _editableUserData.name,
                    onTap: () => _navigateToEditPage('Name'),
                  ),
                  _buildInfoRow(
                    title: 'Email ID',
                    value: _editableUserData.email,
                  ),
                  _buildInfoRow(
                    title: 'Mobile Number',
                    value: _editableUserData.mobileNumber,
                    onTap: () => _navigateToEditPage('Mobile Number'),
                  ),
                  _buildInfoRow(
                    title: 'PIN Code',
                    value: _editableUserData.pinCode,
                    onTap: () => _navigateToEditPage('PIN Code'),
                  ),
                  _buildInfoRow(
                    title: 'Address',
                    value: _editableUserData.address,
                    onTap: () => _navigateToEditPage('Address'),
                    hideDivider: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required String title,
    String? value,
    VoidCallback? onTap,
    bool hideDivider = false,
  }) {
    final bool hasValue = value != null && value.isNotEmpty;
    return InkWell(
      onTap: _isSaving ? null : onTap, // Disable taps while saving
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14.0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
                      const SizedBox(height: 4),
                      Text(
                        hasValue ? value! : 'Tap to add',
                        style: TextStyle(
                          color: hasValue ? const Color(0xFF333333) : Theme.of(context).primaryColor,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                if (onTap != null)
                  Icon(Icons.arrow_forward_ios, color: Colors.grey.shade400, size: 16),
              ],
            ),
          ),
          if (!hideDivider) Divider(height: 1, color: Colors.grey.shade200),
        ],
      ),
    );
  }
}