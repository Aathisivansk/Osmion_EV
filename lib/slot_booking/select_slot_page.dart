import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'invoice.dart'; // Import the invoice page

// A data model to represent a time slot
class TimeSlot {
  final String time; // e.g., "22:15"
  final String status; // "available", "occupied"
  bool isSelected;

  TimeSlot({required this.time, required this.status, this.isSelected = false});
}

class SelectSlotPage extends StatefulWidget {
  // In a real app, you would pass the specific charger ID and station info
  const SelectSlotPage({super.key});

  @override
  State<SelectSlotPage> createState() => _SelectSlotPageState();
}

class _SelectSlotPageState extends State<SelectSlotPage> {
  DateTime _selectedDate = DateTime.now();
  List<TimeSlot> _timeSlots = [];
  bool _isLoading = true;

  // State for the user's selection
  TimeSlot? _startSlot;
  TimeSlot? _endSlot;

  @override
  void initState() {
    super.initState();
    _fetchSlotsForDate(_selectedDate);
  }

  // This function simulates fetching slot data from your server.
  Future<void> _fetchSlotsForDate(DateTime date) async {
    setState(() => _isLoading = true);
    
    // This is a placeholder for your API call.
    await Future.delayed(const Duration(seconds: 1)); 

    // Sample data based on your screenshot and server logic
    final sampleSlots = List.generate(24 * 4, (index) {
      final hour = index ~/ 4;
      final minute = (index % 4) * 15;
      final time = "${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}";
      String status = "available";
      if (hour == 22 && minute == 0) status = "occupied";
      if ((hour == 10 || hour == 11) && (minute == 0 || minute == 45)) status = "occupied";
      return TimeSlot(time: time, status: status);
    });

    setState(() {
      _timeSlots = sampleSlots;
      _isLoading = false;
      _clearSelection();
    });
  }
  
  void _onDateSelected(DateTime date) {
    setState(() {
      _selectedDate = date;
    });
    _fetchSlotsForDate(date);
  }

  void _onSlotSelected(TimeSlot selectedSlot) {
    if (selectedSlot.status == 'occupied') return;
    setState(() {
      if (_startSlot == null) {
        _startSlot = selectedSlot;
        selectedSlot.isSelected = true;
      } else if (_startSlot == selectedSlot) {
        _clearSelection();
      } else {
        _endSlot = selectedSlot;
        _selectSlotRange();
      }
    });
  }

  void _selectSlotRange() {
    final startIndex = _timeSlots.indexOf(_startSlot!);
    final endIndex = _timeSlots.indexOf(_endSlot!);

    final int minIndex = startIndex < endIndex ? startIndex : endIndex;
    final int maxIndex = startIndex > endIndex ? startIndex : endIndex;

    for (var slot in _timeSlots) { slot.isSelected = false; }

    bool rangeIsValid = true;
    for (int i = minIndex; i <= maxIndex; i++) {
      if (_timeSlots[i].status == 'occupied') {
        rangeIsValid = false;
        break;
      }
    }

    if (rangeIsValid) {
      for (int i = minIndex; i <= maxIndex; i++) {
        _timeSlots[i].isSelected = true;
      }
      _startSlot = _timeSlots[minIndex];
      _endSlot = _timeSlots[maxIndex];
    } else {
      _clearSelection();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot select a range that includes an occupied slot.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _clearSelection() {
    for (var slot in _timeSlots) {
      slot.isSelected = false;
    }
    _startSlot = null;
    _endSlot = null;
  }
  
  void _proceedToInvoice() {
    if (_startSlot == null) return;

    final startTimeParts = _startSlot!.time.split(':');
    final startDateTime = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, int.parse(startTimeParts[0]), int.parse(startTimeParts[1]));
    
    int duration = 15;
    DateTime endDateTime;

    if (_endSlot != null) {
      final start = int.parse(_startSlot!.time.split(':')[0]) * 60 + int.parse(_startSlot!.time.split(':')[1]);
      final end = int.parse(_endSlot!.time.split(':')[0]) * 60 + int.parse(_endSlot!.time.split(':')[1]);
      duration = end - start + 15;
    }
    endDateTime = startDateTime.add(Duration(minutes: duration));
    
    final bookingFee = (duration*15);
    final sessionCharges = bookingFee * 5.25; // Example calculation (315 / 60)
    final totalAmount = sessionCharges;

    final bookingDetails = BookingDetails(
      stationName: 'Zone by The Park, Avinashi Rd',
      stationAddress: 'No. 33/3, Avinashi Rd, Coimbatore',
      chargerName: 'Charger A',
      chargerType: 'CCS-2',
      capacity: 30,
      tariff: '₹157.50/15 mins (Estimated*)',
      startTime: startDateTime,
      endTime: endDateTime,
      sessionCharges: sessionCharges,
      bookingFee: bookingFee.toDouble(),
      totalAmount: totalAmount
    );

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => InvoicePage(details: bookingDetails)),
    );
  }
  
  Map<int, List<TimeSlot>> _groupSlotsByHour() {
    final Map<int, List<TimeSlot>> grouped = {};
    for (var slot in _timeSlots) {
      final hour = int.parse(slot.time.split(':')[0]);
      if (grouped[hour] == null) { grouped[hour] = []; }
      grouped[hour]!.add(slot);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF0A4F37);
    final groupedSlots = _groupSlotsByHour();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Book a Session', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFDDFCDA),
        iconTheme: const IconThemeData(color: primaryColor),
        elevation: 1,
        actions: [IconButton(icon: const Icon(Icons.info_outline), onPressed: () {})],
      ),
      body: Column(
        children: [
          _buildDateSelector(),
          _buildLegend(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: primaryColor))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: groupedSlots.length,
                    itemBuilder: (context, index) {
                      final hour = groupedSlots.keys.elementAt(index);
                      final slots = groupedSlots[hour]!;
                      String amPm = hour < 12 ? 'AM' : 'PM';
                      int displayHour = hour % 12;
                      if (displayHour == 0) displayHour = 12;

                      return _buildTimeRow(displayHour, amPm, slots);
                    },
                  ),
          ),
        ],
      ),
      bottomNavigationBar: _startSlot != null ? _buildBottomSummaryBar(primaryColor) : null,
    );
  }

  // --- UI Helper Widgets ---
  
  Widget _buildDateSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      color: Colors.white,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(7, (index) {
            final date = DateTime.now().add(Duration(days: index));
            final isSelected = date.day == _selectedDate.day && date.month == _selectedDate.month;
            return GestureDetector(
              onTap: () => _onDateSelected(date),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isSelected ? Theme.of(context).primaryColor : Colors.transparent,
                      width: 3,
                    ),
                  ),
                ),
                child: Text(
                  DateFormat('d MMM yyyy').format(date),
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? Theme.of(context).primaryColor : Colors.grey[600],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _legendItem(Colors.grey[300]!, 'Occupied'),
          const SizedBox(width: 20),
          _legendItem(Colors.white, 'Available', border: Colors.grey),
          const SizedBox(width: 20),
          _legendItem(Colors.green, 'Selected'),
        ],
      ),
    );
  }

  Widget _legendItem(Color color, String text, {Color? border}) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            border: border != null ? Border.all(color: border) : null,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(text),
      ],
    );
  }
  
  Widget _buildTimeRow(int hour, String amPm, List<TimeSlot> slots) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 60,
            child: Text('$hour $amPm', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          Expanded(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: slots.map((slot) => _buildSlotChip(slot)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlotChip(TimeSlot slot) {
    Color backgroundColor = Colors.white;
    Color textColor = Colors.black;
    Border? border = Border.all(color: Colors.grey.shade300);

    if (slot.status == 'occupied') {
      backgroundColor = Colors.grey.shade200;
      textColor = Colors.grey.shade400;
      border = null;
    } else if (slot.isSelected) {
      backgroundColor = Colors.green;
      textColor = Colors.white;
      border = null;
    }

    final startTime = TimeOfDay(hour: int.parse(slot.time.split(':')[0]), minute: int.parse(slot.time.split(':')[1]));
    final endTime = TimeOfDay(hour: startTime.hour, minute: startTime.minute + 15);

    return GestureDetector(
      onTap: () => _onSlotSelected(slot),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8),
          border: border,
        ),
        child: Text(
          '${startTime.format(context)} - ${endTime.format(context)}',
          textAlign: TextAlign.center,
          style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }

  Widget _buildBottomSummaryBar(Color primaryColor) {
    if (_startSlot == null) return const SizedBox.shrink();

    String startTimeStr = _startSlot!.time;
    String endTimeStr;
    int duration = 15;

    if (_endSlot != null) {
      final start = int.parse(_startSlot!.time.split(':')[0]) * 60 + int.parse(_startSlot!.time.split(':')[1]);
      final end = int.parse(_endSlot!.time.split(':')[0]) * 60 + int.parse(_endSlot!.time.split(':')[1]);
      duration = end - start + 15;
      
      final endHour = (end + 15) ~/ 60 % 24;
      final endMinute = (end + 15) % 60;
      endTimeStr = "${endHour.toString().padLeft(2, '0')}:${endMinute.toString().padLeft(2, '0')}";
    } else {
       final start = int.parse(_startSlot!.time.split(':')[0]) * 60 + int.parse(_startSlot!.time.split(':')[1]);
       final endHour = (start + 15) ~/ 60 % 24;
       final endMinute = (start + 15) % 60;
       endTimeStr = "${endHour.toString().padLeft(2, '0')}:${endMinute.toString().padLeft(2, '0')}";
    }
    
    final bookingFee = (duration / 15) * 60.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20))
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Selected session', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildTimelinePoint(startTimeStr, DateFormat('d MMM yyyy').format(_selectedDate)),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Column(
                    children: [
                      Text('$duration Mins', style: const TextStyle(fontWeight: FontWeight.bold)),
                      const Divider(),
                    ],
                  ),
                ),
              ),
              _buildTimelinePoint(endTimeStr, DateFormat('d MMM yyyy').format(_selectedDate)),
            ],
          ),
          const SizedBox(height: 16),
          Text.rich(
            TextSpan(
              children: [
                const TextSpan(text: 'Booking fee (Non refundable) : '),
                TextSpan(
                  text: '₹${bookingFee.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold)
                ),
              ]
            )
          ),
          const SizedBox(height: 4),
          const Text(
            '*Booking fee will be adjusted in the final invoice',
            style: TextStyle(color: Colors.orange, fontSize: 12),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _proceedToInvoice,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))
              ),
              child: const Text('Proceed'),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildTimelinePoint(String time, String date) {
    final tod = TimeOfDay(hour: int.parse(time.split(':')[0]), minute: int.parse(time.split(':')[1]));
    return Column(
      children: [
        Icon(Icons.circle, color: Theme.of(context).primaryColor, size: 16),
        const SizedBox(height: 4),
        Text(tod.format(context), style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(date, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }
}

