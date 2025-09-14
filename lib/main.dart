// lib/community_feed_screen.dart

import 'package:flutter/material.dart';
import 'become_host_screen.dart';
// Define the CommunityFeedScreen widget
class CommunityFeedScreen extends StatefulWidget {
  const CommunityFeedScreen({Key? key}) : super(key: key);

  @override
  _CommunityFeedScreenState createState() => _CommunityFeedScreenState();
}

class _CommunityFeedScreenState extends State<CommunityFeedScreen> {
  bool _switchValue = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('EV Community Forum 🚗'),
        actions: [
          Switch(
            value: _switchValue,
            onChanged: (bool value) {
              setState(() {
                _switchValue = value;
              });
              if (value) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const BecomeHostScreen(),
                  ),
                );
              }
            },
          ),
        ],
      ),
      // You can add body or other widgets as needed
    );
  }
}

// ... your existing PostCard widget

void main() {
  runApp(const MaterialApp(
    home: CommunityFeedScreen(),
  ));
}