// lib/community_feed_screen.dart

import 'package:flutter/material.dart';
import 'api_service.dart';
import 'models.dart';
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
    _postsFuture = _apiService.fetchPosts();
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
        title: const Text('EV Community Forum 🚗'),
        backgroundColor: Colors.teal,
        elevation: 1,
      ),
      body: FutureBuilder<List<Post>>(
        future: _postsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Failed to load posts: ${snapshot.error}'));
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
                final post = posts[index];
                return PostCard(post: post, onPostTapped: _refreshPosts);
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
            _refreshPosts(); // Refresh list if a post was created
          }
        },
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class PostCard extends StatelessWidget {
  final Post post;
  final VoidCallback onPostTapped;

  const PostCard({super.key, required this.post, required this.onPostTapped});

  String _timeAgo(DateTime time) {
    final difference = DateTime.now().difference(time);
    if (difference.inDays > 1) {
      return '${difference.inDays} days';
    } else if (difference.inHours > 1) {
      return '${difference.inHours} hours';
    } else if (difference.inMinutes > 1) {
      return '${difference.inMinutes} mins';
    } else {
      return 'just now';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      elevation: 2,
      child: InkWell(
        onTap: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => PostDetailScreen(postId: post.id, postTitle: post.title),
            ),
          );
          onPostTapped(); // Refresh the feed when returning
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundImage: NetworkImage(post.userAvatarUrl),
                    radius: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(post.username, style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text('${_timeAgo(post.timestamp)} ago', style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(post.title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(
                post.content,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.arrow_upward, size: 20, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(post.upvotes.toString()),
                    ],
                  ),
                  Row(
                    children: [
                      const Icon(Icons.comment_outlined, size: 20, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(post.commentCount.toString()),
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