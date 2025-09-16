// lib/services/notification_service.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';



class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final String baseUrl = "http://10.62.58.114:5000"; // Use your IP

  Future<void> initialize() async {
    await _firebaseMessaging.requestPermission();

    final fcmToken = await _firebaseMessaging.getToken();
    if (fcmToken != null) {
      print("FCM Token: $fcmToken");
      _sendTokenToServer(fcmToken);
    }

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      // Handle foreground messages (when the app is open)
      print("Got a message whilst in the foreground!");
      print("Message data: ${message.notification?.title}");
    });
  }

  Future<void> _sendTokenToServer(String token) async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('user_email');
    if (email == null) return;

    try {
      await http.post(
        Uri.parse('$baseUrl/api/user/fcm_token'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'fcm_token': token}),
      );
    } catch (e) {
      print("Failed to send FCM token to server: $e");
    }
  }
}