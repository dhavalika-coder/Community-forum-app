class UserModel {
  // A unique identifier for the user.
  final String id;
  // The display name of the user.
  final String username;
  // A URL pointing to the user's profile picture.
  final String avatarUrl;

  const UserModel({
    required this.id,
    required this.username,
    required this.avatarUrl,
  });
}
