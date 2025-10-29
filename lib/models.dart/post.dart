import 'comment.dart';


class PostModel {
final String id;
final String authorId;
final String title;
final String body;
final DateTime createdAt;
int likes;
List<CommentModel> comments;


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