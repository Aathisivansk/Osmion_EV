import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class WalletPage extends StatelessWidget {
  const WalletPage({super.key});

  // --- NEW: Function to show the top-up dialog ---
  void _showTopUpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // We use a StatefulWidget here to manage the selected UPI app and amount
        return const _TopUpDialog();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryTextColor = Color(0xFF0A4F37);
    const Color secondaryColor = Color(0xFFDDFCDA);
    const Color lightGreyColor = Color(0xFFF5F5F5);

    return Scaffold(
      backgroundColor: lightGreyColor,
      appBar: AppBar(
        title: const Text(
          'Wallet',
          style: TextStyle(color: primaryTextColor, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: primaryTextColor),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildBalanceCard(primaryTextColor, context),
          const SizedBox(height: 24),
          const Text(
            'History',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: primaryTextColor,
            ),
          ),
          const SizedBox(height: 16),
          _buildHistorySection(secondaryColor, primaryTextColor),
        ],
      ),
    );
  }

  // Widget for the top balance card
  Widget _buildBalanceCard(Color primaryTextColor, BuildContext context) {
    return Card(
      elevation: 4,
      // ignore: deprecated_member_use
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'OSMION',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: primaryTextColor,
                    letterSpacing: 1.5,
                  ),
                ),
                Row(
                  children: [
                    Icon(Icons.wallet, color: primaryTextColor, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Wallet',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: primaryTextColor,
                      ),
                    ),
                  ],
                )
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              '₹ 0.00',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Available Balance',
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
                // --- MODIFIED: Made this button interactive ---
                InkWell(
                  onTap: () => _showTopUpDialog(context),
                  child: Text(
                    '+Top-up Account',
                    style: TextStyle(
                      color: primaryTextColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 32),
            Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Default Payment method',
                  style: TextStyle(fontSize: 16, color: Colors.black54),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Widget for the transaction history section
  Widget _buildHistorySection(Color secondaryColor, Color primaryTextColor) {
    // ... (History section remains the same)
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            // ignore: deprecated_member_use
            color: secondaryColor.withOpacity(0.5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'September 2025',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: primaryTextColor,
            ),
          ),
        ),
        const SizedBox(height: 8),
        _buildTransactionItem(
          station: 'Hydra charging station',
          date: 'Paid Yesterday, 05:15 PM',
          amount: '- ₹ 1000',
          method: 'From Wallet',
        ),
        _buildTransactionItem(
          station: 'Ather charging station',
          date: 'Paid two days ago, 07:30PM',
          amount: '- ₹ 500',
          method: 'From UPI',
        ),
        _buildTransactionItem(
          station: 'Statiq charging station',
          date: 'Paid 5 September, 05:15 PM',
          amount: '- ₹ 2200.5',
          method: 'From UPI',
        ),
      ],
    );
  }

  // Helper widget for a single transaction item
  Widget _buildTransactionItem({
    required String station,
    required String date,
    required String amount,
    required String method,
  }) {
    // ... (Transaction item remains the same)
    return Card(
      elevation: 0,
      color: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  station,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  date,
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  amount,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  method,
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}


// --- NEW: A StatefulWidget for the Dialog Box ---
class _TopUpDialog extends StatefulWidget {
  const _TopUpDialog();

  @override
  __TopUpDialogState createState() => __TopUpDialogState();
}

class __TopUpDialogState extends State<_TopUpDialog> {
  final _amountController = TextEditingController();
  String? _selectedUpiApp;

  // This is where you would trigger the UPI payment
  void _proceedToPayment() {
    if (_amountController.text.isEmpty || _selectedUpiApp == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an amount and select a UPI app.')),
      );
      return;
    }

    //
    // --- UPI PAYMENT LOGIC GOES HERE ---
    // Example using a package like 'upi_india':
    //
    // final UpiIndia upiIndia = UpiIndia();
    // upiIndia.startTransaction(
    //   app: _selectedUpiApp == 'GPay' ? UpiApp.googlePay : (_selectedUpiApp == 'Paytm' ? UpiApp.paytm : UpiApp.phonePe),
    //   receiverUpiId: "your-upi-id@okhdfcbank",
    //   receiverName: 'Osmion EV',
    //   transactionRefId: 'TestingUpiIndiaPlugin',
    //   transactionNote: 'Wallet Top-up',
    //   amount: double.parse(_amountController.text),
    // ).then((response) {
    //    // Handle the response from the UPI app
    //    Navigator.of(context).pop(); // Close the dialog
    // }).catchError((error) {
    //    // Handle errors
    // });
    
    print('Proceeding with amount: ${_amountController.text} via $_selectedUpiApp');
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryTextColor = Color(0xFF0A4F37);
    const Color secondaryColor = Color(0xFFDDFCDA);
    
    return AlertDialog(
      title: const Text('Top-up Wallet', style: TextStyle(color: primaryTextColor)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
            decoration: const InputDecoration(
              labelText: 'Enter Amount',
              prefixText: '₹ ',
            ),
          ),
          const SizedBox(height: 20),
          const Text('Select UPI App', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildUpiOption('GPay', 'assets/gpay.png'),
              _buildUpiOption('Paytm', 'assets/paytm.png'),
              _buildUpiOption('PhonePe', 'assets/phonepe.png'),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _proceedToPayment,
          style: ElevatedButton.styleFrom(
            backgroundColor: secondaryColor,
            foregroundColor: primaryTextColor,
          ),
          child: const Text('Proceed'),
        ),
      ],
    );
  }

  Widget _buildUpiOption(String appName, String assetPath) {
    final bool isSelected = _selectedUpiApp == appName;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedUpiApp = appName;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Theme.of(context).primaryColor : Colors.grey,
            width: isSelected ? 2 : 1,
          ),
        ),
        // NOTE: You would need to add image assets for these logos,
        // for now, we'll just use text.
        child: Text(appName, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      ),
    );
  }
}

