import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';

class ApiService {
  // FIX 1: Corrected base URL for Android emulator and consistency.
  static const String _baseUrl = 'http://10.62.58.114:5000/api';

  Future<List<Post>> fetchPosts() async {
    final response = await http.get(Uri.parse('$_baseUrl/posts'));
    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      return body.map((dynamic item) => Post.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load posts');
    }
  }

  Future<Post> createPost(String title, String content) async {
    final prefs = await SharedPreferences.getInstance();
    // FIX 2: Use the correct key 'userName' to get the user's name.
    final name = prefs.getString('userName') ?? 'Anonymous';

    final response = await http.post(
      Uri.parse('$_baseUrl/posts/create'),
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode({
        'title': title,
        'content': content,
        'name': name,
        'userAvatarUrl': 'https://i.pravatar.cc/150?u=$name',
      }),
    );

    if (response.statusCode == 201) {
      return Post.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to create post.');
    }
  }

  Future<List<Comment>> fetchComments(String postId) async {
    final response = await http.get(Uri.parse('$_baseUrl/post/$postId/comments'));
    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      return body.map((dynamic item) => Comment.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load comments');
    }
  }

  Future<Comment> addComment(String postId, String text) async {
    final prefs = await SharedPreferences.getInstance();
    // FIX 2: Use the correct key 'userName' to get the user's name.
    final name = prefs.getString('userName') ?? 'Anonymous';

    final response = await http.post(
      Uri.parse('$_baseUrl/post/$postId/comment'),
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode({
        'text': text,
        'name': name,
        'userAvatarUrl': 'https://i.pravatar.cc/150?u=$name',
      }),
    );

    if (response.statusCode == 201) {
      return Comment.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to add comment.');
    }
  }

  Future<int> upvotePost(String postId) async {
    // FIX 3: Corrected the endpoint to match the server route.
    final response = await http.post(Uri.parse('$_baseUrl/posts/$postId/upvote'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['upvotes'];
    } else {
      throw Exception('Failed to upvote post.');
    }
  }
}