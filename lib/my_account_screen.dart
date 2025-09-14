import 'package:flutter/material.dart';
import 'edit_detail_page.dart';
import 'profile_page.dart'; // This import is crucial. It tells this file where to find UserData.
import 'package:http/http.dart' as http; // ADD THIS IMPORT
import 'dart:convert'; // ADD THIS IMPORT

class MyAccountScreen extends StatefulWidget {
  final UserData userData;

  const MyAccountScreen({super.key, required this.userData});

  @override
  State<MyAccountScreen> createState() => _MyAccountScreenState();
}

class _MyAccountScreenState extends State<MyAccountScreen> {
  // This is a local copy of the user data that we can safely edit.
  late UserData _editableUserData;
  
  // ADD THIS VARIABLE FOR BACKEND
  final String baseUrl = "http://localhost:5001"; // For Android emulator - CHANGED TO 5001
  // final String baseUrl = "http://localhost:5001"; // For iOS simulator - CHANGED TO 5001

  @override
  void initState() {
    super.initState();
    print('🔄 MyAccountScreen initState called'); // DEBUG
    print('👤 Original user data: ${widget.userData.name}, ${widget.userData.email}'); // DEBUG
    // When the screen starts, we make a local, editable copy of the data.
    _editableUserData = UserData.fromJson({
      "name": widget.userData.name,
      "email": widget.userData.email,
      "mobileNumber": widget.userData.mobileNumber,
      "pinCode": widget.userData.pinCode,
      "address": widget.userData.address,
    });
    print('📝 Editable user data created'); // DEBUG
  }

  // ADD THIS METHOD TO UPDATE PROFILE ON SERVER
  Future<void> _updateProfileOnServer() async {
    print('🌐 Attempting to update profile on server...'); // DEBUG
    print('📧 Updating user: ${widget.userData.email}'); // DEBUG
    print('📊 Data to update: name=${_editableUserData.name}, mobile=${_editableUserData.mobileNumber}'); // DEBUG
    
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/profile/${widget.userData.email}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'name': _editableUserData.name,
          'mobileNumber': _editableUserData.mobileNumber,
          'pinCode': _editableUserData.pinCode,
          'address': _editableUserData.address,
        }),
      );

      print('📡 HTTP Status Code: ${response.statusCode}'); // DEBUG
      print('📦 Response Body: ${response.body}'); // DEBUG

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse['success'] == true) {
          print('✅ Profile updated successfully on server'); // DEBUG
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully!')),
          );
        } else {
          print('❌ Failed to update profile: ${jsonResponse['message']}'); // DEBUG
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to update: ${jsonResponse['message']}')),
          );
        }
      } else {
        print('❌ Server error: ${response.statusCode}'); // DEBUG
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Server error, please try again')),
        );
      }
    } catch (e) {
      print('❌ Network error: $e'); // DEBUG
      print('💡 Make sure Flask server is running on port 5001'); // DEBUG
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Network error, please check your connection')),
      );
    }
  }

  // This function handles navigating to the edit page and updating the state
  Future<void> _navigateToEditPage(String field) async {
    print('✏️ Edit button pressed for: $field'); // DEBUG
    
    String currentValue = '';
    switch (field) {
      case 'Name': 
        currentValue = _editableUserData.name; 
        print('📝 Current name: $currentValue'); // DEBUG
        break;
      case 'Mobile Number': 
        currentValue = _editableUserData.mobileNumber; 
        print('📱 Current mobile: $currentValue'); // DEBUG
        break;
      case 'PIN Code': 
        currentValue = _editableUserData.pinCode ?? ''; 
        print('📍 Current PIN: $currentValue'); // DEBUG
        break;
      case 'Address': 
        currentValue = _editableUserData.address ?? ''; 
        print('🏠 Current address: $currentValue'); // DEBUG
        break;
    }

    final newValue = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => EditDetailPage(title: field, currentValue: currentValue)),
    );

    if (newValue != null && newValue.isNotEmpty && mounted) {
      print('🔄 Received new value for $field: $newValue'); // DEBUG
      setState(() {
        switch (field) {
          case 'Name': 
            _editableUserData.name = newValue; 
            print('✅ Updated name to: $newValue'); // DEBUG
            break;
          case 'Mobile Number': 
            _editableUserData.mobileNumber = newValue; 
            print('✅ Updated mobile to: $newValue'); // DEBUG
            break;
          case 'PIN Code': 
            _editableUserData.pinCode = newValue; 
            print('✅ Updated PIN to: $newValue'); // DEBUG
            break;
          case 'Address': 
            _editableUserData.address = newValue; 
            print('✅ Updated address to: $newValue'); // DEBUG
            break;
        }
      });
      
      // ADD THIS LINE TO SAVE CHANGES TO SERVER
      print('💾 Saving changes to server...'); // DEBUG
      _updateProfileOnServer();
    } else {
      print('❌ No changes made or empty value received'); // DEBUG
    }
  }

  @override
  Widget build(BuildContext context) {
    print('🏗️ Building MyAccountScreen UI'); // DEBUG
    // This widget intercepts the back button press to return the updated data.
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        print('🔙 Back button pressed, returning updated data'); // DEBUG
        Navigator.of(context).pop(_editableUserData);
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Account'),
          centerTitle: true,
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

  // This helper widget builds a single row of information.
  Widget _buildInfoRow({
    required String title,
    String? value,
    VoidCallback? onTap,
    bool hideDivider = false,
  }) {
    final bool hasValue = value != null && value.isNotEmpty;
    print('📋 Building info row: $title, hasValue: $hasValue'); // DEBUG
    return InkWell(
      onTap: onTap,
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