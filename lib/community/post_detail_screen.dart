import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:osmion/community/models.dart';
import 'package:osmion/community/api_service.dart';

class PostDetailScreen extends StatefulWidget {
  // FIX: Pass the entire Post object, not just the ID and title
  final Post post;

  const PostDetailScreen({super.key, required this.post});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  late Future<List<Comment>> _commentsFuture;
  final ApiService _apiService = ApiService();
  final TextEditingController _commentController = TextEditingController();
  bool _isPostingComment = false;

  @override
  void initState() {
    super.initState();
    _refreshComments();
  }

  void _refreshComments() {
    setState(() {
      _commentsFuture = _apiService.fetchComments(widget.post.id);
    });
  }

  void _addComment() async {
    if (_commentController.text.isEmpty) return;

    setState(() => _isPostingComment = true);

    try {
      await _apiService.addComment(widget.post.id, _commentController.text);
      _commentController.clear();
      FocusScope.of(context).unfocus();
      _refreshComments();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add comment: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPostingComment = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.post.title),
        backgroundColor: Colors.transparent,
      ),
      body: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => _refreshComments(),
              child: CustomScrollView(
                slivers: [
                  // NEW: Sliver to show the main post content
                  SliverToBoxAdapter(
                    child: _buildPostContent(),
                  ),
                  // Sliver that shows the comments list
                  FutureBuilder<List<Comment>>(
                    future: _commentsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const SliverFillRemaining(child: Center(child: CircularProgressIndicator()));
                      }
                      if (snapshot.hasError) {
                        return SliverFillRemaining(child: Center(child: Text('Error: ${snapshot.error}')));
                      }
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.all(24.0),
                            child: Center(child: Text('No comments yet.')),
                          ),
                        );
                      }
                      final comments = snapshot.data!;
                      return SliverList(
                        delegate: SliverChildBuilderDelegate(
                              (context, index) => CommentTile(comment: comments[index]),
                          childCount: comments.length,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          _buildCommentInputField(),
        ],
      ),
    );
  }

  // NEW: Widget to display the main post's full content
  Widget _buildPostContent() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      color: Colors.grey[100],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.post.title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Row(
            children: [
              CircleAvatar(backgroundImage: NetworkImage(widget.post.userAvatarUrl), radius: 16),
              const SizedBox(width: 8),
              Text(widget.post.username, style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const Divider(height: 24),
          Text(widget.post.content, style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildCommentInputField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [BoxShadow(offset: const Offset(0, -1), blurRadius: 2, color: Colors.black.withOpacity(0.1))],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _commentController,
              decoration: const InputDecoration(hintText: 'Add a comment...', border: InputBorder.none),
              textCapitalization: TextCapitalization.sentences,
            ),
          ),
          _isPostingComment
              ? const Padding(padding: EdgeInsets.all(12.0), child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator()))
              : IconButton(
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
          CircleAvatar(backgroundImage: NetworkImage(comment.userAvatarUrl), radius: 18),
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