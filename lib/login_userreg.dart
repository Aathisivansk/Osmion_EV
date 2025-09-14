import 'package:flutter/material.dart';
import 'package:osmion/api_service.dart';
// 1. Import the new API service file
import 'login_cardet.dart'; // Import the car details page

class UserRegisterPage extends StatefulWidget {
  final String email;
  const UserRegisterPage({super.key, required this.email});

  @override
  State<UserRegisterPage> createState() => _UserRegisterPageState();
}

class _UserRegisterPageState extends State<UserRegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _mobileController = TextEditingController();
  bool _isLoading = false; // To show a loading indicator

  @override
  void initState() {
    super.initState();
    // Pre-fill the email from the previous page
    _emailController.text = widget.email;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _pincodeController.dispose();
    _mobileController.dispose();
    super.dispose();
  }

  // --- THIS IS THE NEW REGISTRATION LOGIC ---
  Future<void> _registerUser() async {
    // First, validate the form inputs
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Show a loading circle
    setState(() {
      _isLoading = true;
    });

    // Call the API service to register the user
    final response = await ApiService.registerUser(
      name: _nameController.text,
      email: _emailController.text,
      address: _addressController.text,
      pincode: _pincodeController.text,
      mobile: _mobileController.text,
    );
    
    // Hide the loading circle
    setState(() {
      _isLoading = false;
    });

    // Handle the server's response
    if (response['statusCode'] == 201) { // 201 means "Created" successfully
      // Navigate to the next page on success
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CarDetailsPage()),
        );
      }
    } else {
      // Show an error message if something went wrong
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${response['body']['message']}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryTextColor = Color(0xFF0A4F37);
    const Color secondaryColor = Color(0xFFDDFCDA);

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: secondaryColor,
            expandedHeight: 120.0,
            pinned: true,
            flexibleSpace: const FlexibleSpaceBar(
              title: Text(
                'New User Registration',
                style: TextStyle(color: primaryTextColor),
              ),
              centerTitle: true,
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Personal Info', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primaryTextColor)),
                    const Divider(color: Colors.grey),
                    const SizedBox(height: 20),
                    _buildTextField(label: 'Name*', controller: _nameController, validator: (value) => value!.isEmpty ? 'Please enter your name' : null),
                    const SizedBox(height: 20),
                    _buildTextField(label: 'Mail*', controller: _emailController, validator: (value) { if (value == null || value.isEmpty) { return 'Please enter your email'; } if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) { return 'Please enter a valid email'; } return null; }),
                    const SizedBox(height: 20),
                    _buildTextField(label: 'Address*', controller: _addressController, validator: (value) => value!.isEmpty ? 'Please enter your address' : null),
                    const SizedBox(height: 20),
                    _buildTextField(label: 'Pincode*', controller: _pincodeController, keyboardType: TextInputType.number, validator: (value) { if (value == null || value.isEmpty) { return 'Please enter your pincode'; } if (value.length != 6) { return 'Pincode must be 6 digits'; } return null; }),
                    const SizedBox(height: 20),
                    _buildTextField(label: 'Mobile no*', controller: _mobileController, keyboardType: TextInputType.number, validator: (value) { if (value == null || value.isEmpty) { return 'Please enter your mobile number'; } if (value.length != 10) { return 'Mobile number must be 10 digits'; } return null; }),
                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        // 2. The button now calls the new _registerUser function
                        onPressed: _isLoading ? null : _registerUser, // Disable button when loading
                        style: ElevatedButton.styleFrom(
                          backgroundColor: secondaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(color: primaryTextColor)
                            : const Text(
                                'Register',
                                style: TextStyle(fontSize: 18, color: primaryTextColor),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({required String label, required TextEditingController controller, TextInputType? keyboardType, String? Function(String?)? validator}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey[600]),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF0A4F37)),
        ),
      ),
    );
  }
}

