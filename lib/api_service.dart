import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // --- IMPORTANT ---
  // Replace this with the IP address of the computer running your Python server.
  static const String _baseUrl = 'http://192.168.1.5:5000'; // Example IP

  // Function to register a new user
  static Future<Map<String, dynamic>> registerUser({
    required String name,
    required String email,
    required String address,
    required String pincode,
    required String mobile,
  }) async {
    final url = Uri.parse('$_baseUrl/api/register');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'name': name,
          'email': email,
          'address': address,
          'pincode': pincode,
          'mobile': mobile,
        }),
      );

      return {
        'statusCode': response.statusCode,
        'body': jsonDecode(response.body),
      };
    } catch (e) {
      // Handle potential network errors, like if the server is offline
      return {
        'statusCode': 500, // Using 500 for network/client-side errors
        'body': {'message': 'Network error: ${e.toString()}'}
      };
    }
  }
}