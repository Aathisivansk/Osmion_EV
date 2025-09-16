import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'stations_detail.dart'; // To access the Charger and StationDetails models
import 'select_slot_page.dart';   // Import the new slot selection page

class BookingConfirmationPage extends StatefulWidget {
  final StationDetails station;
  final Charger charger;

  const BookingConfirmationPage({
    super.key,
    required this.station,
    required this.charger,
  });

  @override
  State<BookingConfirmationPage> createState() => _BookingConfirmationPageState();
}

class _BookingConfirmationPageState extends State<BookingConfirmationPage> {
  // To manage the 'Amount' vs 'Units' toggle
  bool _isAmountSelected = true;
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _unitsController = TextEditingController();

  // A sample price per unit (kWh) for calculation.
  final double _pricePerKwh = 18.00;
  final double _userWalletBalance = 500.00; // Sample wallet balance

  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _amountController.addListener(_calculateUnits);
    _unitsController.addListener(_calculateAmount);
  }

  void _calculateUnits() {
    if (_isUpdating) return;
    _isUpdating = true;
    final amount = double.tryParse(_amountController.text);
    if (amount != null && _pricePerKwh > 0) {
      final units = amount / _pricePerKwh;
      _unitsController.text = units.toStringAsFixed(2);
    } else {
      _unitsController.clear();
    }
    _isUpdating = false;
  }

  void _calculateAmount() {
    if (_isUpdating) return;
    _isUpdating = true;
    final units = double.tryParse(_unitsController.text);
    if (units != null) {
      final amount = units * _pricePerKwh;
      _amountController.text = amount.toStringAsFixed(2);
    } else {
      _amountController.clear();
    }
    _isUpdating = false;
  }

  @override
  void dispose() {
    _amountController.removeListener(_calculateUnits);
    _unitsController.removeListener(_calculateAmount);
    _amountController.dispose();
    _unitsController.dispose();
    super.dispose();
  }
  
  // --- UPDATED: This function now navigates to the slot selection page ---
  void _handleBooking() {
     Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SelectSlotPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF0A4F37);
    const Color headerColor = Color(0xFF0A4F37);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: headerColor,
        foregroundColor: Colors.white,
        title: Text(widget.station.name, overflow: TextOverflow.ellipsis),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(headerColor),
            _buildWalletCard(),
            _buildChargingBasisCard(primaryColor),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(primaryColor),
    );
  }

  // --- UI Helper Widgets ---

  Widget _buildHeader(Color headerColor) {
    return Container(
      color: headerColor,
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Column(
        children: [
          Chip(
            label: Text('${widget.charger.name} | Charging Point 1'),
            backgroundColor: Colors.white.withOpacity(0.15),
            labelStyle: const TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 16),
          const Icon(Icons.electrical_services, color: Colors.white, size: 50),
          const SizedBox(height: 8),
          Text(
            widget.charger.type,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Capacity: 30kW (Estimated)',
            style: TextStyle(color: Colors.white.withOpacity(0.8)),
          ),
          const SizedBox(height: 4),
          Text(
            widget.charger.tariff,
            style: TextStyle(color: Colors.white.withOpacity(0.8)),
          ),
        ],
      ),
    );
  }

  Widget _buildWalletCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [ BoxShadow( color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4),) ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Tata EZ Power Charge', style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('₹ ${_userWalletBalance.toStringAsFixed(2)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ],
          ),
          const Icon(Icons.arrow_drop_down, color: Colors.grey),
        ],
      ),
    );
  }

  Widget _buildChargingBasisCard(Color primaryColor) {
    return Container(
      margin: const EdgeInsets.all(16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration( color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('I want to charge on the basis of', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildToggleButtons(primaryColor),
          const SizedBox(height: 20),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _isAmountSelected ? _buildAmountInput() : _buildUnitsInput(),
          )
        ],
      ),
    );
  }

  Widget _buildToggleButtons(Color primaryColor) {
    return Container(
      decoration: BoxDecoration( color: Colors.grey[200], borderRadius: BorderRadius.circular(8)),
      child: ToggleButtons(
        isSelected: [_isAmountSelected, !_isAmountSelected],
        onPressed: (index) {
          setState(() {
            _isAmountSelected = index == 0;
            _amountController.clear();
            _unitsController.clear();
          });
        },
        borderRadius: BorderRadius.circular(8),
        selectedColor: Colors.white,
        color: primaryColor,
        fillColor: primaryColor,
        renderBorder: false,
        constraints: BoxConstraints(minWidth: (MediaQuery.of(context).size.width - 80) / 2, minHeight: 40),
        children: const [
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [ Icon(Icons.currency_rupee, size: 16), SizedBox(width: 4), Text('Amount'),]),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [ Icon(Icons.flash_on, size: 16), SizedBox(width: 4), Text('Units'),]),
        ],
      ),
    );
  }

  Widget _buildAmountInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Amount', style: TextStyle(color: Colors.grey)),
        TextFormField(
          controller: _amountController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(prefixText: '₹ ', hintText: '0.00'),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildPresetButton('₹ 100', () => _amountController.text = '100'),
            _buildPresetButton('₹ 200', () => _amountController.text = '200'),
            _buildPresetButton('₹ 300', () => _amountController.text = '300'),
            _buildPresetButton('₹ 400', () => _amountController.text = '400'),
          ],
        )
      ],
    );
  }

  Widget _buildUnitsInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Units (kWh)', style: TextStyle(color: Colors.grey)),
        TextFormField(
          controller: _unitsController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(suffixText: 'kWh', hintText: '0.00'),
        ),
      ],
    );
  }

  Widget _buildPresetButton(String text, VoidCallback onPressed) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF0A4F37),
        side: BorderSide(color: Colors.grey.shade300)
      ),
      child: Text(text),
    );
  }

  Widget _buildBottomBar(Color primaryColor) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [ BoxShadow( color: Colors.black12, blurRadius: 10, offset: Offset(0, -2),) ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: _amountController,
            builder: (context, value, child) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Amount to Pay'),
                  Text('₹ ${value.text.isEmpty ? '0.00' : value.text}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                ],
              );
            }
          ),
          ElevatedButton(
            onPressed: _handleBooking,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
              shape: RoundedRectangleBorder( borderRadius: BorderRadius.circular(30)),
            ),
            child: const Text('Book'),
          ),
        ],
      ),
    );
  }
}

