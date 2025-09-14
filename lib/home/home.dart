import 'package:flutter/material.dart';
import 'package:osmion/explore/map_screen.dart';
import 'package:osmion/community/community_feed_screen.dart';
import 'package:osmion/profile/profile_page.dart';

void main() {
  runApp(const HomePage());
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});
  @override
  Widget build(BuildContext context) {
    // Function to navigate to MapScreen
    void navigateToMapScreen() {
      Navigator.push(
          context, MaterialPageRoute(builder: (context) => const MapScreen()));
    }

    // Function to navigate to CommunityFeedScreen
    void navigateToCommunityFeedScreen() {
      Navigator.push(context,
          MaterialPageRoute(builder: (context) => const CommunityFeedScreen()));
    }

    // Function to navigate to ProfileScreen
    void navigateToProfileScreen() {
      Navigator.push(context,
          MaterialPageRoute(builder: (context) => const ProfilePage()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFE9FBEF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFBFF5C8),
        elevation: 0,
        title: Row(
          children: [
            GestureDetector(
              onTap:
                  navigateToProfileScreen, // Navigate to ProfileScreen on tap
              child: const Icon(Icons.account_circle,
                  size: 32, color: Colors.black),
            ),
            const SizedBox(width: 8),
            const Text(
              "OSMION",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Colors.black,
              ),
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.notifications, color: Colors.black),
              onPressed: () {},
            ),
            IconButton(
              icon: const Icon(Icons.menu, color: Colors.black),
              onPressed: () {},
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Banner image
            Container(
              height: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                image: const DecorationImage(
                  image: AssetImage("assets/banner.png"), // <-- Add your banner image
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Features list
            Expanded(
              child: ListView(
                children: [
                  _buildFeatureCard(Icons.card_giftcard, "Reward"),
                  const SizedBox(height: 15),
                  _buildFeatureCard(Icons.flight_takeoff, "Plan a trip"),
                  const SizedBox(height: 15),
                  _buildFeatureCard(Icons.public, "Host"),
                  const SizedBox(height: 15),
                  _buildFeatureCard(Icons.event_available, "Book a slot"),
                ],
              ),
            ),
          ],
        ),
      ),

      // Bottom Navigation
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFFBFF5C8),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.black54,
        onTap: (index) {
          // Handle navigation on tap
          if (index == 0) {
            navigateToMapScreen(); // Navigate to MapScreen when location icon is tapped
          } else if (index == 2) {
            // Navigate to CommunityFeedScreen when community icon is tapped
            navigateToCommunityFeedScreen();
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.location_pin), label: "Location"),
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.group), label: "Community"),
          BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet), label: "Wallet"),
        ],
      ),
    );
  }

  // Feature Card Widget
  Widget _buildFeatureCard(IconData icon, String title) {
    return Card(
      color: const Color(0xFFD9FDE4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
        child: Row(
          children: [
            Icon(icon, size: 28, color: Colors.black),
            const SizedBox(width: 20),
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}