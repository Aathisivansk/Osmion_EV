import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:osmion/api_service.dart';
import 'package:osmion/home/home.dart';
import 'login_userreg.dart'; // Import the new registration page

class LoginVerifyPage extends StatefulWidget {
  final String email;
  final bool isNewUser; // Add this line

  const LoginVerifyPage({
    super.key,
    required this.email,
    required this.isNewUser, // Add this line
  });

  @override
  State<LoginVerifyPage> createState() => _LoginVerifyPageState();
}

class _LoginVerifyPageState extends State<LoginVerifyPage> {
  final _formKey = GlobalKey<FormState>();
  final List<TextEditingController> _otpControllers =
  List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(4, (_) => FocusNode());
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _sendOtp(); // Send OTP when the page loads
  }

  @override
  void dispose() {
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var focusNode in _otpFocusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  void _onOtpChanged(String value, int index) {
    if (value.length == 1 && index < 3) {
      _otpFocusNodes[index + 1].requestFocus();
    }
    if (value.isEmpty && index > 0) {
      _otpFocusNodes[index - 1].requestFocus();
    }
  }

  Future<void> _sendOtp() async {
    final response = await ApiService.sendOtp(widget.email);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response['body']['message'])),
      );
    }
  }

  Future<void> _verifyOtp() async {
    final otp = _otpControllers.map((c) => c.text).join();
    if (otp.length != 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the full OTP.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final response = await ApiService.verifyOtp(widget.email, otp);

    setState(() {
      _isLoading = false;
    });

    if (mounted) {
      if (response['statusCode'] == 200) {
        // --- THIS IS THE UPDATED NAVIGATION LOGIC ---
        if (widget.isNewUser) {
          // If the user is new, go to the registration page
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('OTP Verified! Proceeding to registration...')),
          );
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => UserRegisterPage(email: widget.email),
            ),
          );
        } else {
          // If the user already exists, log them in and go to the home page
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Login Successful!')),
          );
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const HomePage()),
                (Route<dynamic> route) => false,
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${response['body']['message']}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryTextColor = Color(0xFF0A4F37);
    const Color secondaryColor = Color(0xFFDDFCDA);
    const Color errorColor = Color(0xFFD32F2F);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: secondaryColor.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.mail_outline,
                    size: 60,
                    color: primaryTextColor,
                  ),
                ),
                const SizedBox(height: 30),
                const Text(
                  'Type Your OTP',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'An OTP has been sent to ${widget.email}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 40),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(4, (index) {
                    return _buildOtpTextField(index);
                  }),
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: _sendOtp,
                  child: const Text(
                    'Resend OTP',
                    style: TextStyle(
                      color: errorColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _verifyOtp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: secondaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(
                      valueColor:
                      AlwaysStoppedAnimation<Color>(primaryTextColor),
                    )
                        : const Text(
                      'Verify',
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
    );
  }

  Widget _buildOtpTextField(int index) {
    return SizedBox(
      height: 60,
      width: 50,
      child: TextFormField(
        controller: _otpControllers[index],
        focusNode: _otpFocusNodes[index],
        autofocus: index == 0,
        onChanged: (value) => _onOtpChanged(value, index),
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        keyboardType: TextInputType.number,
        maxLength: 1,
        decoration: const InputDecoration(
          counterText: "",
          border: UnderlineInputBorder(),
        ),
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
        ],
      ),
    );
  }
}