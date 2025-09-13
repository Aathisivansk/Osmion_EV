import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  // Updated to use a super parameter for the key.
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isChecked = false;
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _showTermsDialog() {
    // Define the colors from the image
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
              'Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. '
              'Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. '
              'Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.',
              style: TextStyle(color: Colors.black87),
            ),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: <Widget>[
            // Deny Button
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
            // Accept Button
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

  @override
  Widget build(BuildContext context) {
    // Define the colors from the image
    const Color primaryTextColor = Color(0xFF0A4F37);
    const Color secondaryColor = Color(0xFFDDFCDA);
    const Color accentColor = Color(0xFF8B5CF6); // Purple for the underline

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            // The top wave-like container
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
                    // Welcome Text
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
                    // Thin divider line
                    Container(
                      width: 150,
                      height: 1,
                      color: primaryTextColor,
                    ),
                    const SizedBox(height: 60),

                    // Email Label
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

                    // Email Text Field
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
                        // Standard email validation regex
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

                    // Terms and Conditions
                    InkWell(
                      onTap: _showTermsDialog,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: <Widget>[
                          SizedBox(
                            height: 24.0,
                            width: 24.0,
                            child: Checkbox(
                              value: _isChecked,
                              // Checkbox is now non-interactive, controlled by the dialog
                              onChanged: (bool? value) {},
                              activeColor: primaryTextColor,
                              checkColor: Colors.white,
                              side: const BorderSide(
                                  color: primaryTextColor, width: 1.5),
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text.rich(
                              TextSpan(
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.black54,
                                  fontFamily: 'Inter',
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

                    // Continue Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          // Validate form before proceeding
                          if (_formKey.currentState!.validate()) {
                            if (_isChecked) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Login Successful!')),
                              );
                              // TODO: Navigate to the next page here
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        'Please agree to the terms & conditions.')),
                              );
                            }
                          }
                        },
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
                        child: const Text(
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
}

// CustomClipper for the wave effect
class WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height - 50); // Start from the bottom-left

    // First curve
    var firstControlPoint = Offset(size.width / 4, size.height);
    var firstEndPoint = Offset(size.width / 2.25, size.height - 30.0);
    path.quadraticBezierTo(firstControlPoint.dx, firstControlPoint.dy,
        firstEndPoint.dx, firstEndPoint.dy);

    // Second curve
    var secondControlPoint =
        Offset(size.width - (size.width / 3.25), size.height - 65);
    var secondEndPoint = Offset(size.width, size.height - 40);
    path.quadraticBezierTo(secondControlPoint.dx, secondControlPoint.dy,
        secondEndPoint.dx, secondEndPoint.dy);

    path.lineTo(size.width, 0); // Line to top-right
    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) {
    return false;
  }
}

