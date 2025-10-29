import 'package:uuid/uuid.dart';

// =========================================================================
// STUB MODEL CLASSES (Replace with real models later)
// =========================================================================

class CommentModel {
  final String id;
  final String postId;
  final String authorId;
  final String body;
  final DateTime createdAt;

  const CommentModel({
    required this.id,
    required this.postId,
    required this.authorId,
    required this.body,
    required this.createdAt,
  });
}

class PostModel {
  final String id;
  final String authorId;
  final String title;
  final String body;
  final DateTime createdAt;
  int likes;
  final List<CommentModel> comments;

  PostModel({
    required this.id,
    required this.authorId,
    required this.title,
    required this.body,
    required this.createdAt,
    this.likes = 0,
    List<CommentModel>? comments,
  }) : comments = comments ?? [];
}

class UserModel {
  final String id;
  final String name;
  final String username;
  final String avatarUrl;

  const UserModel({
    required this.id,
    required this.name,
    required this.username,
    required this.avatarUrl,
  });
}

// =========================================================================
// MOCK DB SERVICE
// =========================================================================
class MockDB {
  static const _uuid = Uuid(); // Fixed: Use const

  final Map<String, UserModel> users = {};
  final Map<String, PostModel> posts = {};

  void seed() {
    final u1 = UserModel(
      id: _uuid.v4(),
      name: 'Asha Rao',
      username: 'asharao',
      avatarUrl: 'assets/images/avatar.png',
    );
    final u2 = UserModel(
      id: _uuid.v4(),
      name: 'Ravi Kumar',
      username: 'ravik',
      avatarUrl: 'assets/images/avatar.png',
    );
    users[u1.id] = u1;
    users[u2.id] = u2;

    final p1 = PostModel(
      id: _uuid.v4(),
      authorId: u1.id,
      title: 'Welcome to the new community!',
      body: 'This is a community for sharing ideas and asking questions. Be kind and follow the rules.',
      createdAt: DateTime.now().subtract(const Duration(hours: 5)),
      likes: 12,
    );

    final p2 = PostModel(
      id: _uuid.v4(),
      authorId: u2.id,
      title: 'Flutter animations tips',
      body: 'Share your favorite animation tricks and packages.',
      createdAt: DateTime.now().subtract(const Duration(days: 1, hours: 3)),
      likes: 8,
    );

    p1.comments.add(
      CommentModel(
        id: _uuid.v4(),
        postId: p1.id,
        authorId: u2.id,
        body: 'Great to be here!',
        createdAt: DateTime.now().subtract(const Duration(hours: 4)),
      ),
    );

    posts[p1.id] = p1;
    posts[p2.id] = p2;
  }

  String createPost(String authorId, String title, String body) {
    final id = _uuid.v4();
    final post = PostModel(
      id: id,
      authorId: authorId,
      title: title,
      body: body,
      createdAt: DateTime.now(),
    );
    posts[id] = post;
    return id;
  }

  void addComment(String postId, String authorId, String body) {
    final comment = CommentModel(
      id: _uuid.v4(),
      postId: postId,
      authorId: authorId,
      body: body,
      createdAt: DateTime.now(),
    );
    posts[postId]?.comments.insert(0, comment);
  }

  void toggleLike(String postId) {
    final p = posts[postId];
    if (p == null) return;
    p.likes += 1;
  }
}