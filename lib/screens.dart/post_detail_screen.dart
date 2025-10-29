import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// =========================================================================
// STUB MODELS & PROVIDER (Replace with real ones later)
// =========================================================================

class Comment {
  final String id;
  final String body;
  const Comment({required this.id, required this.body});
}

class PostModel {
  final String id;
  final String title;
  final String body;
  final DateTime createdAt;
  int likes; // mutable for like button
  final List<Comment> comments;

  PostModel({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.likes,
    required this.comments,
  });
}

class ForumProvider extends ChangeNotifier {
  final List<PostModel> _posts = [
    PostModel(
      id: 'p1',
      title: 'First Post Title',
      body:
          'This is the detailed body of the first post. It contains all the discussion points.',
      createdAt: DateTime.now(),
      likes: 15,
      comments: const [
        Comment(id: 'c1', body: 'Great point!'),
        Comment(id: 'c2', body: 'I agree with this perspective.'),
      ],
    ),
  ];

  PostModel? getPostById(String postId) {
    return _posts.firstWhere(
      (post) => post.id == postId,
      orElse: () => _posts[0],
    );
  }

  void likePost(String postId) {
    final post = getPostById(postId);
    if (post != null) {
      post.likes++;
      notifyListeners();
    }
  }
}

// =========================================================================
// POST DETAIL SCREEN
// =========================================================================
class PostDetailScreen extends StatelessWidget {
  static const routeName = '/post';
  final String postId;

  const PostDetailScreen({
    Key? key,
    required this.postId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final forum = Provider.of<ForumProvider>(context);
    final post = forum.getPostById(postId)!;

    return Scaffold(
      appBar: AppBar(title: const Text('Post')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              post.title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(post.body),
            const SizedBox(height: 12),
            // Likes & Comments Row
            Row(
              children: [
                IconButton(
                  onPressed: () => forum.likePost(post.id),
                  icon: const Icon(Icons.thumb_up),
                ),
                Text('${post.likes} likes'),
                const SizedBox(width: 20),
                Text('${post.comments.length} comments'),
              ],
            ),
            const Divider(),
            const Text(
              'Comments',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            // Comments List
            Expanded(
              child: ListView.builder(
                itemCount: post.comments.length,
                itemBuilder: (context, idx) {
                  final c = post.comments[idx];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.grey[300],
                      child: const Icon(Icons.person, color: Colors.grey),
                    ),
                    title: const Text('User'),
                    subtitle: Text(c.body),
                  );
                },
              ),
            ),
            // Comment Input
            SafeArea(
              child: Row(
                children: [
                  const Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Write a comment...',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        builder: (_) => const SizedBox(height: 200),
                      );
                    },
                    icon: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}