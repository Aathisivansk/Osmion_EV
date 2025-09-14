import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'become_host_screen.dart';

// Define the CommunityFeedScreen widget
class HostingTandC extends StatefulWidget {
  const HostingTandC({Key? key}) : super(key: key);

  @override
  _HostingTandCState createState() => _HostingTandCState();
}

class _HostingTandCState extends State<HostingTandC> {
  bool _termsAccepted = false;
  final ScrollController _scrollController = ScrollController();
  bool _isScrolledToEnd = false;

  void _navigateToHostScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const BecomeHostScreen(),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
          _scrollController.position.maxScrollExtent) {
        setState(() {
          _isScrolledToEnd = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms and Conditions'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Replace Image.asset with a scrollable Text widget for Terms and Conditions
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                child: Text(
                  '''
 Welcome to OSMION!
 Before you register your home charger as a station and share it with others, please read and agree to the following terms and conditions carefully.

 1. ✅ Eligibility

        You must be the owner or authorized user of the charger you are registering.

      The charger must be in safe and working condition.

      You agree to share the charger responsibly and in compliance with local laws and safety regulations.


 2. ✅ Registration

        By registering, you confirm that the information you provide is accurate and up to date.

      You agree to allow OSMION to verify your charger details if required.

      You must maintain the charger properly and ensure it is available during the scheduled time slots.


 3. ✅ User Safety

      You are responsible for ensuring that users access and use the charger safely.

        OSMION is not liable for any damage, injury, or loss resulting from misuse or unsafe handling of the charger.

        You must ensure compatibility of the charger with users’ vehicles before approving bookings.


 4. ✅ Pricing and Payments

      You can set your own pricing within the guidelines provided by OSMION.

      OSMION will process payments on your behalf and may deduct applicable service fees.

      You agree to resolve any payment disputes in good faith.


 5. ✅ Availability and Booking

      You agree to honor confirmed bookings unless extraordinary circumstances prevent you from doing so.

        You may cancel bookings if required, but repeated cancellations without valid reasons may lead to restrictions or removal from the platform.

      Users’ personal information will be handled in accordance with our privacy policy.


 6. ✅ Prohibited Activities

      You must not:

      Register a charger that you do not own or have permission to share.

        Share chargers that are faulty, damaged, or unsafe.

        Engage in fraudulent activities, false claims, or unauthorized transactions.

      Use the platform for commercial exploitation beyond the permitted scope.


 7. ✅ Privacy & Data Usage

        Your personal data, charger information, and transaction details will be used as per our Privacy Policy.

        OSMION may use aggregated data for improving services and reporting usage trends.


 8. ✅ Liability

      OSMION acts as a platform connecting users and hosts; it is not responsible for third-party actions or any incidents arising from charger usage.

      Hosts agree to indemnify and hold OSMION harmless from any claims arising due to negligence or violation of these terms.


 9. ✅ Termination

      OSMION reserves the right to suspend or remove hosts who violate these terms, engage in unsafe practices, or misuse the platform.

      Hosts may deactivate their charger listing at any time by contacting support.


 10. ✅ Changes to Terms

      OSMION may update these terms from time to time. You will be notified, and continued use of the platform implies acceptance of the updated terms.
                  ''',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
            const SizedBox(height: 40),

            CheckboxListTile(
              value: _termsAccepted && _isScrolledToEnd,
              // MODIFIED: This is the corrected line
              onChanged: (bool? value) {
                if (_isScrolledToEnd) {
                  setState(() {
                    _termsAccepted = value ?? false;
                  });
                }
              },
              title: RichText(
                text: TextSpan(
                  style: Theme.of(context).textTheme.bodyMedium,
                  children: [
                    const TextSpan(text: 'I have read and agree to the '),
                    TextSpan(
                      text: 'Terms and Conditions',
                      style: const TextStyle(
                        color: Colors.green,
                        decoration: TextDecoration.underline,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () {
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
              onPressed: _termsAccepted && _isScrolledToEnd ? _navigateToHostScreen : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color.fromARGB(255, 33, 182, 64),
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
    home: HostingTandC(),
  ));
}