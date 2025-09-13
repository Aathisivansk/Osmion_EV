import 'package:flutter/material.dart';

class CarDetailsPage extends StatefulWidget {
  const CarDetailsPage({super.key});

  @override
  State<CarDetailsPage> createState() => _CarDetailsPageState();
}

class _CarDetailsPageState extends State<CarDetailsPage> {
  final _formKey = GlobalKey<FormState>();
  final _registerNoController = TextEditingController();

  // Placeholder data for dropdowns - you will replace this from your database
  final List<String> _makes = ['Tata', 'Mahindra', 'Hyundai', 'MG', 'BYD'];
  final List<String> _models = ['Nexon EV', 'Tiago EV', 'XUV400', 'Kona Electric', 'ZS EV'];
  final List<String> _connectorTypes = ['CCS 2', 'CHAdeMO', 'Type 2 AC', 'GB/T'];

  String? _selectedMake;
  String? _selectedModel;
  String? _selectedConnector;

  @override
  void dispose() {
    _registerNoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryTextColor = Color(0xFF0A4F37);
    const Color secondaryColor = Color(0xFFDDFCDA);
    const Color labelColor = Colors.grey;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: primaryTextColor),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Vehicle Info',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: primaryTextColor,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Please provide your vehicle information',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 40),
              _buildDropdown(
                value: _selectedMake,
                items: _makes,
                label: 'Make*',
                labelColor: labelColor,
                onChanged: (value) {
                  setState(() {
                    _selectedMake = value;
                  });
                },
                validator: (value) =>
                    value == null ? 'Please select a make' : null,
              ),
              const SizedBox(height: 20),
              _buildDropdown(
                value: _selectedModel,
                items: _models,
                label: 'Model*',
                labelColor: labelColor,
                onChanged: (value) {
                  setState(() {
                    _selectedModel = value;
                  });
                },
                validator: (value) =>
                    value == null ? 'Please select a model' : null,
              ),
              const SizedBox(height: 20),
              _buildTextField(
                controller: _registerNoController,
                label: 'Register no*',
                labelColor: labelColor,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your register number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              _buildDropdown(
                value: _selectedConnector,
                items: _connectorTypes,
                label: 'Type of connector*',
                labelColor: labelColor,
                onChanged: (value) {
                  setState(() {
                    _selectedConnector = value;
                  });
                },
                validator: (value) =>
                    value == null ? 'Please select a connector type' : null,
              ),
              const SizedBox(height: 50),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Vehicle Details Saved!')),
                      );
                       // Example: Navigate to the home page
                       // Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => HomePage()), (route) => false);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: secondaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Continue',
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
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required Color labelColor,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: labelColor, fontSize: 16),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.grey),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF0A4F37), width: 2),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String? value,
    required List<String> items,
    required String label,
    required Color labelColor,
    required void Function(String?) onChanged,
    String? Function(String?)? validator,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      items: items.map((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
      onChanged: onChanged,
      validator: validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: labelColor, fontSize: 16),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.grey),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF0A4F37), width: 2),
        ),
      ),
    );
  }
}
