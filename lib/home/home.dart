import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:osmion/explore/map_screen.dart';
import 'package:osmion/profile/profile_page.dart';
import 'package:osmion/community/community_feed_screen.dart';
import 'package:osmion/transaction_history/transaction_history.dart';
import 'package:osmion/rewards/rewards_page.dart';
import 'package:osmion/wallet/add_money_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const HomePage(),
    const MapScreen(),
    const CommunityFeedScreen(),
    const TransactionHistoryPage(),
  ];

  void _onNavBarTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFFBFF5C8),
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.black54,
        onTap: _onNavBarTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(
              icon: Icon(Icons.location_pin), label: "Location"),
          BottomNavigationBarItem(icon: Icon(Icons.group), label: "Community"),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: "History"),
        ],
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final PageController _pageController = PageController();
  final List<String> _bannerImages = [
    'assets/banner1.jpg',
    'assets/banner2.jpg',
    'assets/banner3.jpg',
    'assets/banner4.png',
  ];
  int _currentPage = 0;
  Timer? _timer;

  // --- NEW: State variables for wallet balance ---
  double? _walletBalance;
  bool _isLoadingBalance = true;
  final String baseUrl = "http://10.62.58.114:5000";


  @override
  void initState() {
    super.initState();
    _startBannerTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startBannerTimer() {
    _timer = Timer.periodic(const Duration(seconds: 3), (Timer timer) {
      if (!mounted) return;
      int nextPage = _currentPage + 1;
      if (nextPage >= _bannerImages.length) {
        nextPage = 0;
      }
      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeIn,
      );
    });
  }

  Future<void> _fetchWalletBalance() async {
    final prefs = await SharedPreferences.getInstance();
    final userEmail = prefs.getString('user_email');
    if (userEmail == null) {
      setState(() {
        _isLoadingBalance = false;
        _walletBalance = 0;
      });
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/profile/$userEmail'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          setState(() {
            // Ensure the balance is treated as a number
            _walletBalance = (data['data']['walletBalance'] as num).toDouble();
            _isLoadingBalance = false;
          });
        }
      } else {
        setState(() => _isLoadingBalance = false);
      }
    } catch (e) {
      setState(() => _isLoadingBalance = false);
      print("Failed to fetch balance: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE9FBEF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFBFF5C8),
        elevation: 0,
        title: Row(
          children: [
            GestureDetector(
              onTap: () async {
                await Navigator.push(context,
                    MaterialPageRoute(builder: (context) => const ProfilePage()));
                // Refresh balance when returning from profile page
                _fetchWalletBalance();
              },
              child:
              const Icon(Icons.account_circle, size: 32, color: Colors.black),
            ),
            const SizedBox(width: 8),
            const Text("OSMION",
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Colors.black)),
            const Spacer(),
            IconButton(
                icon: const Icon(Icons.notifications, color: Colors.black),
                onPressed: () {}),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchWalletBalance,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              _buildDynamicBanner(),
              const SizedBox(height: 20),
              _buildWalletContainer(),
              const SizedBox(height: 20),
              _buildFeatureCard(
                  icon: Icons.card_giftcard,
                  title: "Reward",
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const RewardsPage()))),
              const SizedBox(height: 15),
              _buildFeatureCard(
                  icon: Icons.flight_takeoff, title: "Plan a trip", onTap: () {}),
              const SizedBox(height: 15),
              _buildFeatureCard(
                  icon: Icons.event_available, title: "Book a slot", onTap: () {}),
            ],
          ),
        ),
      ),
    );
  }

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
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_bannerImages.length, (index) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                margin: const EdgeInsets.symmetric(horizontal: 4.0),
                height: 8.0,
                width: _currentPage == index ? 24.0 : 8.0,
                decoration: BoxDecoration(
                  color: _currentPage == index
                      ? Colors.black54
                      : Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(12),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildWalletContainer() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        gradient: const LinearGradient(
          colors: [Color(0xFF6A82FB), Color(0xFFFC5C7D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Balance',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 4),
              _isLoadingBalance
                  ? const SizedBox(
                height: 28,
                width: 28,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
              )
                  : Text(
                '₹ ${_walletBalance?.toStringAsFixed(2) ?? '0.00'}',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold),
              ),
            ],
          ),
          GestureDetector(
            onTap: () async {
              await Navigator.push(context,
                  MaterialPageRoute(builder: (context) => const AddMoneyPage()));
              // Refresh balance when returning from add money page
              _fetchWalletBalance();
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 24),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(
      {required IconData icon, required String title, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        color: const Color(0xFFD9FDE4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        elevation: 1,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
          child: Row(
            children: [
              Icon(icon, size: 28, color: Colors.black),
              const SizedBox(width: 20),
              Text(title,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }
}