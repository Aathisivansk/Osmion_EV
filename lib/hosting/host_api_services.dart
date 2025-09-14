// lib/host_api_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'hosting_session.dart';

class HostApiService {
  // Use the IP address from your server's terminal output
  static const String _baseUrl = 'http://10.62.58.114:5000/api';

  // This method must be INSIDE the HostApiService class
  Future<void> createHostingSession(HostingSession session) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/hosts/create'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(session.toJson()),
    );

    if (response.statusCode != 201) {
      // You can handle different errors based on the response body
      throw Exception('Failed to create hosting session. Server responded: ${response.body}');
    }
  }
}