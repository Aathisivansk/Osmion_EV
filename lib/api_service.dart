import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // --- IMPORTANT ---
  // Replace this with the IP address of the computer running your Python server.
  static const String _baseUrl = 'http://192.168.1.5:5000'; // Example IP

  // NEW: Function to check if an email exists
  static Future<Map<String, dynamic>> checkEmailExists(String email) async {
    final url = Uri.parse('$_baseUrl/api/check_email');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );
      return {'statusCode': response.statusCode, 'body': jsonDecode(response.body)};
    } catch (e) {
      return {'statusCode': 500, 'body': {'message': 'Network error: ${e.toString()}'}};
    }
  }

  // UPDATED: Register function now includes a password
  static Future<Map<String, dynamic>> registerUser({
    required String name,
    required String email,
    required String address,
    required String pincode,
    required String mobile,
    required String password,
  }) async {
    final url = Uri.parse('$_baseUrl/api/register');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'email': email,
          'address': address,
          'pincode': pincode,
          'mobile': mobile,
          'password': password, // Send the password
        }),
      );
      return {'statusCode': response.statusCode, 'body': jsonDecode(response.body)};
    } catch (e) {
      return {'statusCode': 500, 'body': {'message': 'Network error: ${e.toString()}'}};
    }
  }

  // NEW: Function for user login
  static Future<Map<String, dynamic>> loginUser(String email, String password) async {
    final url = Uri.parse('$_baseUrl/api/login');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );
      return {'statusCode': response.statusCode, 'body': jsonDecode(response.body)};
    } catch (e) {
      return {'statusCode': 500, 'body': {'message': 'Network error: ${e.toString()}'}};
    }
  }
}

