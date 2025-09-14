// lib/login.dart
import 'package:flutter/material.dart';
import 'package:osmion/api_service.dart';
import 'login_verify.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isChecked = false;
  bool _isLoading = false; // To show a loading indicator

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  // This new function handles the logic for the "Continue" button
  Future<void> _handleContinue() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (!_isChecked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please agree to the terms & conditions.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Check if the email exists on the server
    final response = await ApiService.checkEmailExists(_emailController.text);

    setState(() {
      _isLoading = false;
    });

    if (mounted) {
      if (response['statusCode'] == 200) {
        final bool isNewUser = !response['body']['exists'];
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LoginVerifyPage(
              email: _emailController.text,
              isNewUser: isNewUser, // Pass the user status to the next screen
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${response['body']['message']}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // The rest of your LoginScreen code for the UI...
  // (build method, WaveClipper, _showTermsDialog, etc.)
  // Just make sure to update the onPressed callback for the "Continue" button:

  @override
  Widget build(BuildContext context) {
    const Color primaryTextColor = Color(0xFF0A4F37);
    const Color secondaryColor = Color(0xFFDDFCDA);
    const Color accentColor = Color(0xFF8B5CF6);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            ClipPath(
              clipper: WaveClipper(),
              child: Container(
                color: secondaryColor.withAlpha(179),
                height: 250,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    const SizedBox(height: 20),
                    const Text(
                      'WELCOME',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: primaryTextColor,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: 150,
                      height: 1,
                      color: primaryTextColor,
                    ),
                    const SizedBox(height: 60),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Email',
                        style: TextStyle(
                          color: primaryTextColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      decoration: const InputDecoration(
                        prefixIcon:
                        Icon(Icons.email_outlined, color: primaryTextColor),
                        enabledBorder: UnderlineInputBorder(
                          borderSide:
                          BorderSide(color: accentColor, width: 2.0),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide:
                          BorderSide(color: accentColor, width: 2.5),
                        ),
                        errorStyle: TextStyle(color: Colors.redAccent),
                      ),
                      cursorColor: primaryTextColor,
                      style: const TextStyle(color: Colors.black87),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email.';
                        }
                        final bool emailValid = RegExp(
                            r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
                            .hasMatch(value);
                        if (!emailValid) {
                          return 'This is an invalid mail.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 30),
                    InkWell(
                      onTap: _showTermsDialog,
                      child: Row(
                        children: <Widget>[
                          Icon(
                            _isChecked
                                ? Icons.check_circle
                                : Icons.radio_button_unchecked_outlined,
                            color: primaryTextColor,
                            size: 24.0,
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text.rich(
                              TextSpan(
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.black54,
                                ),
                                children: [
                                  TextSpan(text: 'I agree to the '),
                                  TextSpan(
                                    text: 'terms & conditions',
                                    style: TextStyle(
                                      color: primaryTextColor,
                                      fontWeight: FontWeight.bold,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 50),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleContinue, // Updated
                        style: ButtonStyle(
                          backgroundColor:
                          WidgetStateProperty.all<Color>(secondaryColor),
                          padding:
                          WidgetStateProperty.all<EdgeInsetsGeometry>(
                            const EdgeInsets.symmetric(vertical: 16),
                          ),
                          shape: WidgetStateProperty.all<
                              RoundedRectangleBorder>(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          elevation: WidgetStateProperty.all<double>(0),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(
                          color: primaryTextColor,
                        )
                            : const Text(
                          'Continue',
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
          ],
        ),
      ),
    );
  }

  void _showTermsDialog() {
    const Color primaryTextColor = Color(0xFF0A4F37);
    const Color secondaryColor = Color(0xFFDDFCDA);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          title: const Text(
            'Terms & Conditions',
            style: TextStyle(
              color: primaryTextColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const SingleChildScrollView(
            child: Text(
              'Please read these terms and conditions carefully before using Our Service.\n\n'
                  'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. '
                  'Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.',
              style: TextStyle(color: Colors.black87),
            ),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: <Widget>[
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: primaryTextColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Deny', style: TextStyle(color: primaryTextColor)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: secondaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child:
              const Text('Accept', style: TextStyle(color: primaryTextColor)),
              onPressed: () {
                setState(() {
                  _isChecked = true;
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}

class WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height - 50);
    var firstControlPoint = Offset(size.width / 4, size.height);
    var firstEndPoint = Offset(size.width / 2.25, size.height - 30.0);
    path.quadraticBezierTo(firstControlPoint.dx, firstControlPoint.dy,
        firstEndPoint.dx, firstEndPoint.dy);
    var secondControlPoint =
    Offset(size.width - (size.width / 3.25), size.height - 65);
    var secondEndPoint = Offset(size.width, size.height - 40);
    path.quadraticBezierTo(secondControlPoint.dx, secondControlPoint.dy,
        secondEndPoint.dx, secondEndPoint.dy);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) {
    return false;
  }
}