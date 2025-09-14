import 'package:flutter/material.dart';
import 'package:osmion/community/api_service.dart';
import 'package:osmion/community/models.dart';
import 'post_detail_screen.dart';
import 'create_post_screen.dart';

class CommunityFeedScreen extends StatefulWidget {
  const CommunityFeedScreen({super.key});

  @override
  State<CommunityFeedScreen> createState() => _CommunityFeedScreenState();
}

class _CommunityFeedScreenState extends State<CommunityFeedScreen> {
  late Future<List<Post>> _postsFuture;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _refreshPosts();
  }

  void _refreshPosts() {
    setState(() {
      _postsFuture = _apiService.fetchPosts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('EV Community Forum'),
        backgroundColor: Colors.transparent,
      ),
      body: FutureBuilder<List<Post>>(
        future: _postsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error loading posts: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No posts yet. Be the first!'));
          }

          final posts = snapshot.data!;
          return RefreshIndicator(
            onRefresh: () async => _refreshPosts(),
            child: ListView.builder(
              itemCount: posts.length,
              itemBuilder: (context, index) {
                // Use a stateful widget for the card to manage its own state
                return PostCard(post: posts[index], onPostTapped: _refreshPosts);
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const CreatePostScreen()),
          );
          if (result == true) {
            _refreshPosts();
          }
        },
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add),
      ),
    );
  }
}

// FIX: Converted PostCard to a StatefulWidget to manage its upvote state
class PostCard extends StatefulWidget {
  final Post post;
  final VoidCallback onPostTapped;

  const PostCard({super.key, required this.post, required this.onPostTapped});

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  late int _currentUpvotes;
  bool _isUpvoted = false; // To prevent multiple upvotes
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _currentUpvotes = widget.post.upvotes;
  }

  String _timeAgo(DateTime time) {
    // ... (time ago logic is unchanged)
    final difference = DateTime.now().difference(time);
    if (difference.inDays > 1) return '${difference.inDays} days';
    if (difference.inHours > 0) return '${difference.inHours}h';
    if (difference.inMinutes > 0) return '${difference.inMinutes}m';
    return 'just now';
  }

  void _handleUpvote() async {
    if (_isUpvoted) return; // Prevent spamming upvote button

    setState(() {
      _isUpvoted = true;
      _currentUpvotes++; // Optimistically update UI
    });

    try {
      final newUpvoteCount = await _apiService.upvotePost(widget.post.id);
      setState(() {
        _currentUpvotes = newUpvoteCount; // Update with actual count from server
      });
    } catch (e) {
      // If server fails, revert the change and show error
      setState(() {
        _isUpvoted = false;
        _currentUpvotes--;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upvote failed: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: InkWell(
        onTap: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => PostDetailScreen(post: widget.post),
            ),
          );
          widget.onPostTapped();
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(backgroundImage: NetworkImage(widget.post.userAvatarUrl), radius: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.post.username, style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text('${_timeAgo(widget.post.timestamp)} ago', style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(widget.post.title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(
                widget.post.content,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // NEW: Functional upvote button
                  InkWell(
                    onTap: _handleUpvote,
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Row(
                        children: [
                          Icon(Icons.arrow_upward, size: 20, color: _isUpvoted ? Colors.teal : Colors.grey),
                          const SizedBox(width: 4),
                          Text(_currentUpvotes.toString()),
                        ],
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.comment_outlined, size: 20, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(widget.post.commentCount.toString()),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}