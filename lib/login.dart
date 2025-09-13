import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}
class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Login UI',
      theme: ThemeData(
        primarySwatch: Color.fromARGB(255,221,252,218),
        fontFamily: 'Inter', // A clean, modern font
      ),
      home: const LoginScreen(),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isChecked = false;
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Define the colors from the image
    const Color primaryTextColor = Color(0xFF0A4F37);
    const Color secondaryColor = Color(0xFFD9F2D3);
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
                color: secondaryColor.withOpacity(0.7),
                height: 250,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0),
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
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.email_outlined, color: primaryTextColor),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: accentColor, width: 2.0),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: accentColor, width: 2.5),
                      ),
                    ),
                    cursorColor: primaryTextColor,
                    style: const TextStyle(color: Colors.black87),
                  ),
                  const SizedBox(height: 30),

                  // Terms and Conditions Checkbox
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: <Widget>[
                      SizedBox(
                        height: 24.0,
                        width: 24.0,
                        child: Checkbox(
                          value: _isChecked,
                          onChanged: (bool? value) {
                            setState(() {
                              _isChecked = value!;
                            });
                          },
                          activeColor: primaryTextColor,
                          checkColor: Colors.white,
                          side: const BorderSide(color: primaryTextColor, width: 1.5),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
                              fontFamily: 'Inter',
                            ),
                            children: [
                              const TextSpan(text: 'I agree to the '),
                              TextSpan(
                                text: 'terms & conditions',
                                style: const TextStyle(
                                  color: primaryTextColor,
                                  fontWeight: FontWeight.bold,
                                  decoration: TextDecoration.underline,
                                ),
                                // Add a recognizer for tap events
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {
                                    // Handle tap on "terms & conditions"
                                    // e.g., show a dialog or navigate to another screen
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text('Navigating to Terms & Conditions...')),
                                    );
                                  },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 50),

                  // Continue Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        // Handle continue button press
                         if (_emailController.text.isNotEmpty && _isChecked) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Login Successful!')),
                            );
                          } else if (_emailController.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please enter your email.')),
                            );
                          } else {
                             ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please agree to the terms & conditions.')),
                            );
                          }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: secondaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0, // No shadow
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
