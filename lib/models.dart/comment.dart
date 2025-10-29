class CommentModel {
final String id;
final String postId;
final String authorId;
final String body;
final DateTime createdAt;


CommentModel({required this.id, required this.postId, required this.authorId, required this.body, required this.createdAt});
}