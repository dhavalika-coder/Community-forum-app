import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// =========================================================================
// STUB MODELS & PROVIDER (Replace with real ones later)
// =========================================================================

class PostModel {
  final String id;
  final String title;
  final String body;
  final DateTime createdAt;
  final int likes;
  final List<dynamic> comments;

  const PostModel({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.likes,
    required this.comments,
  });
}

class ForumProvider extends ChangeNotifier {
  void likePost(String postId) {
    debugPrint('Toggling like for post $postId');
  }
}

class PostDetailScreen extends StatelessWidget {
  static const routeName = '/post-detail';

  const PostDetailScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Post Detail Stub')),
      body: const Center(child: Text('Post Detail Screen')),
    );
  }
}

// =========================================================================
// POST CARD WIDGET
// =========================================================================
class PostCard extends StatelessWidget {
  final PostModel post;

  const PostCard({
    Key? key,
    required this.post,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final forum = Provider.of<ForumProvider>(context, listen: false);

    return Hero(
      tag: post.id,
      child: Material(
        color: Colors.white,
        elevation: 1,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => Navigator.pushNamed(
            context,
            PostDetailScreen.routeName,
            arguments: post.id,
          ),
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User Row
                Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.grey[300],
                      child: const Icon(Icons.person, color: Colors.white),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'User',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            _formatDate(post.createdAt),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => forum.likePost(post.id),
                      icon: const Icon(Icons.thumb_up_alt_outlined),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Title and Body
                Text(
                  post.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  post.body,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 12),

                // Footer row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${post.likes} likes • ${post.comments.length} comments',
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pushNamed(
                        context,
                        PostDetailScreen.routeName,
                        arguments: post.id,
                      ),
                      child: const Text('View'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper: Format timestamp
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${date.month}/${date.day}/${date.year}';
  }
}