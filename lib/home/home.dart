import 'dart:async'; // Import the async library for the Timer
import 'package:flutter/material.dart';
import 'package:osmion/explore/map_screen.dart';
import 'package:osmion/hosting//t_and_c_check.dart';
import 'package:osmion/profile/profile_page.dart';

import '../community/community_feed_screen.dart';

// FIX: Converted HomePage to a StatefulWidget to manage the banner's state
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // --- STATE VARIABLES FOR DYNAMIC BANNER ---

  // 1. Controller to manage the pages (banners)
  final PageController _pageController = PageController();

  // 2. List of your banner images
  // IMPORTANT: Make sure you have these images in an 'assets' folder
  // and have declared it in your pubspec.yaml file.
  final List<String> _bannerImages = [
    'assets/banner1.jpg', // Replace with your first image
    'assets/banner2.jpg', // Replace with your second image
    'assets/banner3.jpg', // Replace with your third image
    'assets/banner4.png', // Replace with your fourth image
  ];

  // 3. To keep track of the current page for the indicator dots
  int _currentPage = 0;

  // 4. Timer for auto-scrolling
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Start the auto-scrolling timer when the page is created
    _startBannerTimer();
  }

  @override
  void dispose() {
    // Stop the timer and dispose the controller when the page is closed to prevent memory leaks
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startBannerTimer() {
    // Create a timer that fires every 3 seconds
    _timer = Timer.periodic(const Duration(seconds: 2), (Timer timer) {
      if (_currentPage < _bannerImages.length - 1) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }

      // Animate to the next page
      _pageController.animateToPage(
        _currentPage,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeIn,
      );
    });
  }

  // --- UI WIDGETS ---

  @override
  Widget build(BuildContext context) {
    void navigateToMapScreen() {
      Navigator.push(context, MaterialPageRoute(builder: (context) => const MapScreen()));
    }

    void navigateToHostTandC() {
      Navigator.push(context, MaterialPageRoute(builder: (context) => const HostingTandC()));
    }

    void navigateToProfileScreen() {
      Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfilePage()));
    }

    void navigateToCommunityTab() {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const CommunityFeedScreen()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFE9FBEF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFBFF5C8),
        elevation: 0,
        title: Row(
          children: [
            GestureDetector(
              onTap: navigateToProfileScreen,
              child: const Icon(Icons.account_circle, size: 32, color: Colors.black),
            ),
            const SizedBox(width: 8),
            const Text("OSMION", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.black)),
            const Spacer(),
            IconButton(icon: const Icon(Icons.notifications, color: Colors.black), onPressed: () {}),
            IconButton(icon: const Icon(Icons.menu, color: Colors.black), onPressed: () {}),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // --- FIX: Replaced the static Container with our new dynamic banner ---
            _buildDynamicBanner(),
            const SizedBox(height: 20),
            Expanded(
              child: ListView(
                children: [
                  _buildFeatureCard(Icons.card_giftcard, "Reward"),
                  const SizedBox(height: 15),
                  _buildFeatureCard(Icons.flight_takeoff, "Plan a trip"),
                  const SizedBox(height: 15),
                  GestureDetector(
                    onTap: navigateToHostTandC, // Navigate to CommunityFeedScreen
                    child: _buildFeatureCard(Icons.public, "Host"),
                  ),
                  const SizedBox(height: 15),
                  _buildFeatureCard(Icons.event_available, "Book a slot"),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFFBFF5C8),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.black54,
        onTap: (index) {
          if (index == 0) navigateToMapScreen();
          if (index == 2) navigateToCommunityTab();
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

  // --- HELPER WIDGETS ---

  // New widget to build the dynamic banner
  Widget _buildDynamicBanner() {
    return SizedBox(
      height: 120,
      child: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: _bannerImages.length,
              onPageChanged: (int page) {
                setState(() {
                  _currentPage = page;
                });
              },
              itemBuilder: (context, index) {
                return Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    image: DecorationImage(
                      image: AssetImage(_bannerImages[index]),
                      fit: BoxFit.cover,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          // Widget for the page indicator dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_bannerImages.length, (index) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                margin: const EdgeInsets.symmetric(horizontal: 4.0),
                height: 8.0,
                width: _currentPage == index ? 24.0 : 8.0,
                decoration: BoxDecoration(
                  color: _currentPage == index ? Colors.black54 : Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(12),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

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
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

}