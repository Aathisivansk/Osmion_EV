// lib/post_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'models.dart';
import 'api_service.dart';

class PostDetailScreen extends StatefulWidget {
  final String postId;
  final String postTitle;

  const PostDetailScreen({super.key, required this.postId, required this.postTitle});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  late Future<List<Comment>> _commentsFuture;
  final ApiService _apiService = ApiService();
  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _commentsFuture = _apiService.fetchComments(widget.postId);
  }

  void _addComment() async {
    if (_commentController.text.isNotEmpty) {
      try {
        await _apiService.addComment(widget.postId, _commentController.text);
        _commentController.clear();
        // Refresh comments
        setState(() {
          _commentsFuture = _apiService.fetchComments(widget.postId);
        });
        // Hide keyboard
        FocusScope.of(context).unfocus();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add comment: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.postTitle),
        backgroundColor: Colors.teal,
      ),
      body: Column(
        children: [
          Expanded(
            child: FutureBuilder<List<Comment>>(
              future: _commentsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text('No comments yet. Be the first to reply!'),
                  );
                }
                final comments = snapshot.data!;
                return ListView.builder(
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    return CommentTile(comment: comments[index]);
                  },
                );
              },
            ),
          ),
          _buildCommentInputField(),
        ],
      ),
    );
  }

  Widget _buildCommentInputField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, -1),
            blurRadius: 2,
            color: Colors.black.withOpacity(0.1),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _commentController,
              decoration: const InputDecoration(
                hintText: 'Add a comment...',
                border: InputBorder.none,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send, color: Colors.teal),
            onPressed: _addComment,
          ),
        ],
      ),
    );
  }
}

class CommentTile extends StatelessWidget {
  final Comment comment;
  const CommentTile({super.key, required this.comment});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundImage: NetworkImage(comment.userAvatarUrl),
            radius: 18,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(comment.username, style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat.yMd().add_jm().format(comment.timestamp.toLocal()),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(comment.text),
              ],
            ),
          )
        ],
      ),
    );
  }
}