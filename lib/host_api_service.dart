// lib/host_api_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'hosting_session.dart';

class HostApiService {
  // IMPORTANT: Use the same IP address as in your other api_service file
  static const String _baseUrl = 'http://127.0.0.1:5000/api';

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