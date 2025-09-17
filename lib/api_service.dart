import 'dart:convert';
import 'package:http/http.dart' as http;
import 'community/models.dart';

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
    required String fcmToken,
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
          'fcmToken': fcmToken,
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
    required double capacity,
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
          'capacity': capacity,
        }),
      );
      return {'statusCode': response.statusCode, 'body': jsonDecode(response.body)};
    } catch (e) {
      return {'statusCode': 500, 'body': {'message': 'Network error: ${e.toString()}'}};
    }
  }

  // NEW: Function to get username by email
  static Future<Map<String, dynamic>> getUsernameByEmail(String email) async {
    final url = Uri.parse('$_baseUrl/api/get_username');
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

//   ===================================================================================================================================
  Future<List<Post>> fetchPosts() async {
    final response = await http.get(Uri.parse('$_baseUrl/posts'));

    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      List<Post> posts = body.map((dynamic item) => Post.fromJson(item)).toList();
      return posts;
    } else {
      throw Exception('Failed to load posts');
    }
  }

  // Create a new post
  Future<Post> createPost(String title, String content, String email) async {
    // Fetch username using the email
    final usernameResponse = await getUsernameByEmail(email);
    String username = 'Anonymous'; // Default username
    if (usernameResponse['statusCode'] == 200 && usernameResponse['body']['username'] != null) {
      username = usernameResponse['body']['username'];
    }
    final response = await http.post(
      Uri.parse('$_baseUrl/posts/create'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'title': title,
        'content': content,
        'username': username, // Use fetched username
        'userAvatarUrl': 'https://i.pravatar.cc/150?u=$username', // Optionally, make avatar URL dynamic too
      }),
    );

    if (response.statusCode == 201) {
      return Post.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to create post.');
    }
  }

  // Fetch comments for a specific post
  Future<List<Comment>> fetchComments(String postId) async {
    final response = await http.get(Uri.parse('$_baseUrl/post/$postId/comments'));

    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      List<Comment> comments = body.map((dynamic item) => Comment.fromJson(item)).toList();
      return comments;
    } else {
      throw Exception('Failed to load comments');
    }
  }

  // Add a comment to a post
  Future<Comment> addComment(String postId, String text, String email) async {
    // Fetch username using the email
    final usernameResponse = await getUsernameByEmail(email);
    String username = 'Anonymous'; // Default username
    if (usernameResponse['statusCode'] == 200 && usernameResponse['body']['username'] != null) {
      username = usernameResponse['body']['username'];
    } else {
      // Handle error or use a default/guest username
      print('Failed to fetch username for comment: ${usernameResponse['body']['message']}');
    }
    final response = await http.post(
      Uri.parse('$_baseUrl/post/$postId/comment'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'text': text,
        'username': username, // Use fetched username
        'userAvatarUrl': 'https://i.pravatar.cc/150?u=$username', // Optionally, make avatar URL dynamic
      }),
    );
    if (response.statusCode == 201) {
      return Comment.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to add comment.');
    }
  }

}

