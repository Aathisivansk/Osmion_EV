import 'package:flutter/material.dart';
import 'package:osmion/auth/login.dart';
import 'my_account_screen.dart';
import 'terms_and_conditions_page.dart';
import 'help_and_support_page.dart';
import 'my_vehicles_page.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// This UserData class is the blueprint for the user's information.
class UserData {
  String name;
  String email;
  String mobileNumber;
  String? pinCode;
  String? address;

  UserData({
    required this.name,
    required this.email,
    required this.mobileNumber,
    this.pinCode,
    this.address,
  });

  factory UserData.fromJson(Map<String, dynamic> json) {
    return UserData(
      name: json['name'],
      email: json['email'],
      mobileNumber: json['mobileNumber'],
      pinCode: json['pinCode'],
      address: json['address'],
    );
  }
}

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // This is the "memory" where the user's data is stored.
  UserData? _userData;
  bool _isLoading = true;

  // ADD THESE VARIABLES FOR BACKEND
  final String baseUrl = "http://10.62.58.114:5000";

  @override
  void initState() {
    super.initState();
    _fetchAccountDetails();
  }

  // This function fetches the initial data when the page loads.
  Future<void> _fetchAccountDetails() async {
    final prefs = await SharedPreferences.getInstance();
    final userEmail = prefs.getString('userEmail');
    print(userEmail);

    if (userEmail == null) {
      _loadFallbackData(); // Or handle missing email appropriately
      return;
    }
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/profile/$userEmail'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse['success'] == true) {
          setState(() {
            _userData = UserData.fromJson(jsonResponse['data']);
            _isLoading = false;
          });
        } else {
          _loadFallbackData();
        }
      } else {
        _loadFallbackData();
      }
    } catch (e) {
      _loadFallbackData();
    }
  }

  // ADD THIS FUNCTION FOR FALLBACK DATA
  void _loadFallbackData() {
    SharedPreferences.getInstance().then((prefs) {
      final fallbackName = prefs.getString('userName') ?? "Name";
      final fallbackEmail = prefs.getString('userEmail') ?? "small@gmail.com";
      // Fallback to local data if server is unavailable
      setState(() {
        _userData = UserData(
          name: fallbackName,
          email: fallbackEmail,
          mobileNumber: "8XXXXXXXX",
        );
        _isLoading = false;
      });
    });
  }

  // This function navigates to the MyAccountScreen and handles the updated data.
  Future<void> _navigateToMyAccount() async {
    final updatedUserData = await Navigator.push<UserData>(
      context,
      MaterialPageRoute(
        builder: (context) => MyAccountScreen(userData: _userData!),
      ),
    );

    if (updatedUserData != null && mounted) {
      setState(() {
        _userData = updatedUserData;
      });
    }
  }

  Future<void> _showLogoutConfirmationDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Logout'),
          content: const Text('Are you sure you want to log out?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Logout'),
              onPressed: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                      (route) => false,
                );
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          _buildHeader(context, _userData?.name ?? 'Guest', _userData?.email ?? '...'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                _buildMenuCard(
                  context,
                  title: 'Account & Settings',
                  children: [
                    _buildMenuListItem(
                      icon: Icons.person_outline,
                      title: 'My Account',
                      onTap: _navigateToMyAccount,
                    ),
                    _buildMenuListItem(
                      icon: Icons.directions_car_outlined,
                      title: 'My Vehicles',
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const MyVehiclesPage()));
                      },
                    ),

                  ],
                ),
                const SizedBox(height: 20),
                _buildMenuCard(
                  context,
                  title: 'Support & Legal',
                  children: [
                    _buildMenuListItem(
                      icon: Icons.help_outline,
                      title: 'Help & Support',
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpAndSupportPage()));
                      },
                    ),
                    _buildMenuListItem(
                      icon: Icons.description_outlined,
                      title: 'Terms & Conditions',
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const TermsAndConditionsPage()));
                      },
                    ),
                    _buildMenuListItem(
                      icon: Icons.logout,
                      title: 'Logout',
                      textColor: Colors.red.shade700,
                      hideDivider: true,
                      onTap: () => _showLogoutConfirmationDialog(context),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- HELPER WIDGETS ---
  Widget _buildHeader(BuildContext context, String userName, String userEmail) {
    return Container(
      width: double.infinity,
      color: Theme.of(context).primaryColor,
      padding: const EdgeInsets.only(top: 50, bottom: 20),
      child: Column(
        children: [
          const CircleAvatar(
            radius: 45,
            backgroundColor: Colors.white,
            child: Icon(Icons.person, size: 50, color: Color(0xFF2E7D32)),
          ),
          const SizedBox(height: 12),
          Text(
            userName,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 4),
          Text(
            userEmail,
            style: TextStyle(fontSize: 16, color: Colors.white.withOpacity(0.8)),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard(BuildContext context, {required String title, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }

  Widget _buildMenuListItem({required IconData icon, required String title, VoidCallback? onTap, Color? textColor, bool hideDivider = false}) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: Row(
              children: [
                Icon(icon, color: Colors.grey.shade600, size: 22),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(color: textColor ?? Colors.black87, fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ),
                if (onTap != null)
                  Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade400),
              ],
            ),
          ),
          if (!hideDivider)
            Divider(height: 1, color: Colors.grey.shade200, indent: 40),
        ],
      ),
    );
  }
}