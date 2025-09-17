import 'package:flutter/material.dart';
import 'package:osmion/auth/login.dart';
import 'my_account_screen.dart';
import 'terms_and_conditions_page.dart';
import 'help_and_support_page.dart';
import 'my_vehicles_page.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'manage_well_wishers_page.dart';

// This UserData class is the blueprint for the user's information.
class UserData {
  String name;
  String email;
  String mobileNumber;
  String? pinCode;
  String? address;
  String? profileImageUrl;

  UserData({
    required this.name,
    required this.email,
    required this.mobileNumber,
    this.pinCode,
    this.address,
    this.profileImageUrl,
  });

  factory UserData.fromJson(Map<String, dynamic> json) {
    return UserData(
      name: json['name'] ?? 'Guest',
      email: json['email'] ?? 'No email found',
      mobileNumber: json['mobileNumber'] ?? 'No mobile found',
      pinCode: json['pinCode'],
      address: json['address'],
      profileImageUrl: json['profileImageUrl'],
    );
  }
}

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  UserData? _userData;
  bool _isLoading = true;
  String? _errorMessage;
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  final String baseUrl = "http://10.62.58.114:5000";

  @override
  void initState() {
    super.initState();
    _fetchAccountDetails();
  }

  Future<void> _fetchAccountDetails() async {
    final prefs = await SharedPreferences.getInstance();
    final userEmail = prefs.getString('user_email');

    if (userEmail == null) {
      setState(() {
        _errorMessage = "You are not logged in.";
        _isLoading = false;
      });
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/profile/$userEmail'),
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
          throw Exception(
              jsonResponse['message'] ?? 'Failed to load user data.');
        }
      } else {
        throw Exception('Failed to connect to the server.');
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
      _loadFallbackData();
    }
  }

  void _loadFallbackData() {
    SharedPreferences.getInstance().then((prefs) {
      final fallbackName = prefs.getString('userName') ?? "Guest";
      final fallbackEmail = prefs.getString('user_email') ?? "Not logged in";
      setState(() {
        _userData = UserData(
          name: fallbackName,
          email: fallbackEmail,
          mobileNumber: "8XXXXXXXX",
        );
      });
    });
  }

  // --- THIS IS THE CORRECTED UPLOAD FUNCTION ---
  Future<void> _pickAndUploadImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
    if (pickedFile == null) return;

    setState(() {
      _imageFile = File(pickedFile.path);
    });

    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('user_email');
    if (email == null) return;

    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/api/profile/image'),
    );

    request.fields['email'] = email;
    request.files.add(
      await http.MultipartFile.fromPath(
        'profile_image',
        pickedFile.path,
      ),
    );

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 && mounted) {
        final data = json.decode(response.body);
        final newImageUrl = data['imageUrl'];

        // --- NEW: Save the new URL to SharedPreferences ---
        await prefs.setString('profileImageUrl', newImageUrl);

        setState(() {
          _userData?.profileImageUrl = newImageUrl;
          _imageFile = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile picture updated!')));
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Upload failed: ${response.body}')));
        }
      }
    } catch(e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('An error occurred: $e')));
      }
    }
  }

  Future<void> _navigateToMyAccount() async {
    if (_userData == null) return;
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
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.clear();
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
          : _errorMessage != null
          ? Center(child: Text('Error: $_errorMessage'))
          : Column(
        children: [
          _buildHeader(context, _userData?.name ?? 'Guest',
              _userData?.email ?? '...'),
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
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                const MyVehiclesPage()));
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildMenuCard(
                  context,
                  title: 'Safety',
                  children: [
                    _buildMenuListItem(
                      icon: Icons.sos,
                      title: 'SOS - Well Wishers',
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                const ManageWellWishersPage()));
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
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                const HelpAndSupportPage()));
                      },
                    ),
                    _buildMenuListItem(
                      icon: Icons.description_outlined,
                      title: 'Terms & Conditions',
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                const TermsAndConditionsPage()));
                      },
                    ),
                    _buildMenuListItem(
                      icon: Icons.logout,
                      title: 'Logout',
                      textColor: Colors.red.shade700,
                      hideDivider: true,
                      onTap: () =>
                          _showLogoutConfirmationDialog(context),
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

  Widget _buildHeader(BuildContext context, String userName, String userEmail) {
    ImageProvider<Object> backgroundImage;
    if (_imageFile != null) {
      backgroundImage = FileImage(_imageFile!);
    } else if (_userData?.profileImageUrl != null &&
        _userData!.profileImageUrl!.isNotEmpty) {
      backgroundImage = NetworkImage(_userData!.profileImageUrl!);
    } else {
      backgroundImage = const AssetImage('assets/default_profile.png');
    }

    return Container(
      width: double.infinity,
      color: Colors.green,
      padding: const EdgeInsets.only(top: 50, bottom: 20),
      child: Column(
        children: [
          GestureDetector(
            onTap: _pickAndUploadImage,
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 45,
                  backgroundImage: backgroundImage,
                  backgroundColor: Colors.white,
                  onBackgroundImageError: (exception, stackTrace) {
                    // This will catch errors if the network image fails to load
                    setState(() {
                      _userData?.profileImageUrl = null;
                    });
                  },
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child:
                    const Icon(Icons.edit, size: 20, color: Colors.green),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            userName,
            style: const TextStyle(
                fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
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

  Widget _buildMenuCard(BuildContext context,
      {required String title, required List<Widget> children}) {
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

  Widget _buildMenuListItem(
      {required IconData icon,
        required String title,
        VoidCallback? onTap,
        Color? textColor,
        bool hideDivider = false}) {
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
                    style: TextStyle(
                        color: textColor ?? Colors.black87,
                        fontSize: 16,
                        fontWeight: FontWeight.w500),
                  ),
                ),
                if (onTap != null)
                  Icon(Icons.arrow_forward_ios,
                      size: 16, color: Colors.grey.shade400),
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