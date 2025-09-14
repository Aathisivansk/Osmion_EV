// lib/api_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'models.dart';

class ApiService {
  // IMPORTANT: Replace with your computer's IP address.
  // Your computer and test device (emulator/phone) must be on the SAME Wi-Fi network.
  static const String _baseUrl = 'http://10.62.58.114:5000/api';

  // Fetch all posts from the server
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
  Future<Post> createPost(String title, String content) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/posts/create'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'title': title,
        'content': content,
        'username': 'FlutterFan', // In a real app, get this from user auth
        'userAvatarUrl': 'https://i.pravatar.cc/150?u=flutterfan',
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
  Future<Comment> addComment(String postId, String text) async {
      final response = await http.post(
      Uri.parse('$_baseUrl/post/$postId/comment'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'text': text,
        'username': 'Commenter', // In a real app, get this from user auth
        'userAvatarUrl': 'https://i.pravatar.cc/150?u=commenter',
      }),
    );
     if (response.statusCode == 201) {
      return Comment.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to add comment.');
    }
  }
}