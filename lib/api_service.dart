import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {

  static const String _baseUrl = 'http://10.62.58.114:5000';
  // NEW: Function to send OTP
  static Future<Map<String, dynamic>> sendOtp(String email) async {
    final url = Uri.parse('$_baseUrl/api/send_otp');
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

  // NEW: Function to verify OTP
  static Future<Map<String, dynamic>> verifyOtp(String email, String otp) async {
    final url = Uri.parse('$_baseUrl/api/verify_otp');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'otp': otp}),
      );
      return {'statusCode': response.statusCode, 'body': jsonDecode(response.body)};
    } catch (e) {
      return {'statusCode': 500, 'body': {'message': 'Network error: ${e.toString()}'}};
    }
  }

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

  static Future<Map<String, dynamic>> addVehicleDetails({
    required String email,
    required String make,
    required String model,
    required String registerNo,
    required String connectorType,
  }) async {
    final url = Uri.parse('$_baseUrl/api/add_vehicle');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'make': make,
          'model': model,
          'register_no': registerNo,
          'connector_type': connectorType,
        }),
      );
      return {'statusCode': response.statusCode, 'body': jsonDecode(response.body)};
    } catch (e) {
      return {'statusCode': 500, 'body': {'message': 'Network error: ${e.toString()}'}};
    }
  }
}

