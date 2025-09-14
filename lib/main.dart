// lib/main.dart

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'become_host_screen.dart';

// Define the CommunityFeedScreen widget
class CommunityFeedScreen extends StatefulWidget {
  const CommunityFeedScreen({Key? key}) : super(key: key);

  @override
  _CommunityFeedScreenState createState() => _CommunityFeedScreenState();
}

class _CommunityFeedScreenState extends State<CommunityFeedScreen> {
  bool _termsAccepted = false;

  void _navigateToHostScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const BecomeHostScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('EV Community Forum 🚗'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Image.asset(
              'assets/community_image.png',
              height: 250,
            ),
            const SizedBox(height: 40),

            CheckboxListTile(
              value: _termsAccepted,
              // MODIFIED: This is the corrected line
              onChanged: (bool? value) {
                setState(() {
                  _termsAccepted = value ?? false;
                });
              },
              title: RichText(
                text: TextSpan(
                  style: Theme.of(context).textTheme.bodyMedium,
                  children: [
                    const TextSpan(text: 'I have read and agree to the '),
                    TextSpan(
                      text: 'Terms and Conditions',
                      style: const TextStyle(
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () {
                          print('Navigate to Terms and Conditions page');
                        },
                    ),
                  ],
                ),
              ),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: _termsAccepted ? _navigateToHostScreen : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              child: const Text('Agree & Continue'),
            ),
          ],
        ),
      ),
    );
  }
}

void main() {
  runApp(const MaterialApp(
    home: CommunityFeedScreen(),
  ));
}