import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class UserRegisterPage extends StatefulWidget {
  final String email;
  const UserRegisterPage({super.key, required this.email});

  @override
  State<UserRegisterPage> createState() => _UserRegisterPageState();
}

class _UserRegisterPageState extends State<UserRegisterPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _emailController;
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _mobileController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.email);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _nameController.dispose();
    _addressController.dispose();
    _pincodeController.dispose();
    _mobileController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryTextColor = Color(0xFF0A4F37);
    const Color secondaryColor = Color(0xFFDDFCDA);
    const Color labelColor = Colors.grey;

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: secondaryColor,
            expandedHeight: 120.0,
            pinned: true,
            automaticallyImplyLeading: true,
            iconTheme: const IconThemeData(color: primaryTextColor),
            flexibleSpace: const FlexibleSpaceBar(
              title: Text(
                'New User Registration',
                style: TextStyle(
                  color: primaryTextColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              titlePadding: EdgeInsets.only(left: 16.0, bottom: 16.0),
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
                    const Text(
                      'Personal Info',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: primaryTextColor,
                      ),
                    ),
                    const Divider(
                      color: Colors.grey,
                      thickness: 1,
                      height: 20,
                    ),
                    const SizedBox(height: 20),
                    _buildTextField(
                      controller: _nameController,
                      label: 'Name*',
                      labelColor: labelColor,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    _buildTextField(
                        controller: _emailController,
                        label: 'Mail*',
                        labelColor: labelColor,
                        readOnly: true, // Mail is pre-filled and not editable
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Email cannot be empty';
                          }
                          // Standard email validation regex
                          final bool emailValid = RegExp(
                                  r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
                              .hasMatch(value);
                          if (!emailValid) {
                            return 'Please enter a valid email';
                          }
                          return null;
                        }),
                    const SizedBox(height: 20),
                    _buildTextField(
                      controller: _addressController,
                      label: 'Address*',
                      labelColor: labelColor,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your address';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    _buildTextField(
                      controller: _pincodeController,
                      label: 'Pincode*',
                      labelColor: labelColor,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(6)
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your pincode';
                        }
                        if (value.length != 6) {
                          return 'Pincode must be 6 digits';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    _buildTextField(
                      controller: _mobileController,
                      label: 'Mobile no*',
                      labelColor: labelColor,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10)
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your mobile number';
                        }
                        if (value.length != 10) {
                          return 'Mobile number must be 10 digits';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          // This will now only run if all validators pass
                          if (_formKey.currentState!.validate()) {
                            // TODO: Implement registration logic and navigate to next page
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Registration Successful!')),
                            );
                            // Example of navigating to a new page after success
                            // Navigator.push(context, MaterialPageRoute(builder: (context) => HomePage()));
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: secondaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Register',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: primaryTextColor,
                          ),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required Color labelColor,
    bool readOnly = false,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: labelColor, fontSize: 16),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.grey),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF0A4F37), width: 2),
        ),
      ),
    );
  }
}


