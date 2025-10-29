import 'package:flutter/foundation.dart';

// =========================================================================
// USER MODEL
// =========================================================================

/// Represents a user in the community forum.
class UserModel {
  final String id;
  final String username;
  final String email;

  const UserModel({
    required this.id,
    required this.username,
    required this.email,
  });

  @override
  String toString() => 'User(id: $id, username: $username)';
}

// =========================================================================
// FORUM PROVIDER (State Management)
// =========================================================================

/// Manages user authentication state and forum data.
class ForumProvider extends ChangeNotifier {
  UserModel? _currentUser;

  /// Returns the current user. Throws if not loaded.
  UserModel get currentUser {
    if (_currentUser == null) {
      throw StateError("Current user has not been loaded or authenticated.");
    }
    return _currentUser!;
  }

  /// Simulates loading user data (e.g., from API or local storage)
  Future<void> loadMockData() async {
    await Future.delayed(const Duration(milliseconds: 100));

    _currentUser = const UserModel(
      id: 'user_12345',
      username: 'MockUser_Dart',
      email: 'mock@example.com',
    );
    notifyListeners();
  }

  /// Logs out the user
  void mockLogout() {
    _currentUser = null;
    notifyListeners();
  }
}