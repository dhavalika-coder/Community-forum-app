import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// -----------------------------------------------------------------------------
// MOCK: SharedPreferences
// -----------------------------------------------------------------------------
class SharedPreferences {
  final Map<String, dynamic> _data = {};

  static Future<SharedPreferences> getInstance() async {
    final prefs = SharedPreferences._internal();
    prefs._data['isAuthenticated'] = false;
    return prefs;
  }

  SharedPreferences._internal();

  bool? getBool(String key) => _data[key] as bool?;

  Future<bool> setBool(String key, bool value) async {
    _data[key] = value;
    return true;
  }
}

// -----------------------------------------------------------------------------
// AppState
// -----------------------------------------------------------------------------
class AppState extends ChangeNotifier {
  final SharedPreferences prefs;
  bool _isAuthenticated = false;

  AppState(this.prefs) {
    _isAuthenticated = prefs.getBool('isAuthenticated') ?? false;
  }

  bool get isAuthenticated => _isAuthenticated;

  Future<void> mockLogin() async {
    _isAuthenticated = true;
    await prefs.setBool('isAuthenticated', true);
    notifyListeners();
  }
}

// -----------------------------------------------------------------------------
// Base Screen Stub
// -----------------------------------------------------------------------------
class _BaseScreenStub extends StatelessWidget {
  final String title;
  const _BaseScreenStub(this.title, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$title Screen (Stub)',
              style: const TextStyle(fontSize: 18, color: Colors.teal),
            ),
            const SizedBox(height: 20),
            if (title.contains('Authentication'))
              ElevatedButton.icon(
                onPressed: () async {
                  await Provider.of<AppState>(context, listen: false)
                      .mockLogin();
                  if (context.mounted) {
                    Navigator.pushReplacementNamed(
                        context, HomeScreen.routeName);
                  }
                },
                icon: const Icon(Icons.login),
                label: const Text('Mock Login'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// SCREEN STUBS
// -----------------------------------------------------------------------------
class SplashScreen extends StatelessWidget {
  static const routeName = '/splash';
  const SplashScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Get auth state immediately (safe, no async gap)
    final isAuthenticated =
        Provider.of<AppState>(context, listen: false).isAuthenticated;

    // Delay only for splash animation
    Future.delayed(const Duration(seconds: 1)).then((_) {
      if (context.mounted) {
        Navigator.pushReplacementNamed(
          context,
          isAuthenticated ? HomeScreen.routeName : AuthScreen.routeName,
        );
      }
    });

    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(color: Colors.teal),
      ),
    );
  }
}

class AuthScreen extends _BaseScreenStub {
  static const routeName = '/auth';
  const AuthScreen({Key? key}) : super('Authentication', key: key);
}

class HomeScreen extends _BaseScreenStub {
  static const routeName = '/home';
  const HomeScreen({Key? key}) : super('Home Feed', key: key);
}

class PostDetailScreen extends _BaseScreenStub {
  static const routeName = '/post-detail';
  final String postId;
  const PostDetailScreen({Key? key, required this.postId})
      : super('Post Details ($postId)', key: key);
}

class CreatePostScreen extends _BaseScreenStub {
  static const routeName = '/create-post';
  const CreatePostScreen({Key? key}) : super('Create Post', key: key);
}

class CommentsScreen extends _BaseScreenStub {
  static const routeName = '/comments';
  final String postId;
  const CommentsScreen({Key? key, required this.postId})
      : super('Comments ($postId)', key: key);
}

class SearchScreen extends _BaseScreenStub {
  static const routeName = '/search';
  const SearchScreen({Key? key}) : super('Search', key: key);
}

class ProfileScreen extends _BaseScreenStub {
  static const routeName = '/profile';
  final String userId;
  const ProfileScreen({Key? key, required this.userId})
      : super('User Profile ($userId)', key: key);
}

class NotificationsScreen extends _BaseScreenStub {
  static const routeName = '/notifications';
  const NotificationsScreen({Key? key}) : super('Notifications', key: key);
}

class SettingsScreen extends _BaseScreenStub {
  static const routeName = '/settings';
  const SettingsScreen({Key? key}) : super('Settings', key: key);
}

// -----------------------------------------------------------------------------
// MAIN APP
// -----------------------------------------------------------------------------
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();

  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(prefs),
      child: const CommunityForumApp(),
    ),
  );
}

class CommunityForumApp extends StatelessWidget {
  const CommunityForumApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Community Forum',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: Colors.grey[50],
        cardTheme: const CardThemeData(
          elevation: 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.teal,
          elevation: 2,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          iconTheme: IconThemeData(color: Colors.white),
        ),
      ),
      initialRoute: SplashScreen.routeName,
      onGenerateRoute: AppRouter.onGenerateRoute,
      debugShowCheckedModeBanner: false,
    );
  }
}

// -----------------------------------------------------------------------------
// ROUTER
// -----------------------------------------------------------------------------
class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    return MaterialPageRoute(
      settings: settings,
      builder: (context) => _AuthGuard(
        settings: settings,
        child: _getScreen(settings),
      ),
    );
  }

  static Widget _getScreen(RouteSettings settings) {
    switch (settings.name) {
      case SplashScreen.routeName:
        return const SplashScreen();
      case AuthScreen.routeName:
        return const AuthScreen();
      case HomeScreen.routeName:
        return const HomeScreen();
      case PostDetailScreen.routeName:
        final postId = settings.arguments as String? ?? '123';
        return PostDetailScreen(postId: postId);
      case CreatePostScreen.routeName:
        return const CreatePostScreen();
      case CommentsScreen.routeName:
        final postId = settings.arguments as String? ?? '123';
        return CommentsScreen(postId: postId);
      case SearchScreen.routeName:
        return const SearchScreen();
      case ProfileScreen.routeName:
        final userId = settings.arguments as String? ?? 'user-a1b2';
        return ProfileScreen(userId: userId);
      case NotificationsScreen.routeName:
        return const NotificationsScreen();
      case SettingsScreen.routeName:
        return const SettingsScreen();
      default:
        return const AuthScreen();
    }
  }
}

// -----------------------------------------------------------------------------
// AUTH GUARD
// -----------------------------------------------------------------------------
class _AuthGuard extends StatelessWidget {
  final RouteSettings settings;
  final Widget child;

  const _AuthGuard({required this.settings, required this.child, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final routeName = settings.name;

    if (routeName == SplashScreen.routeName ||
        routeName == AuthScreen.routeName) {
      return child;
    }

    final isAuth = Provider.of<AppState>(context).isAuthenticated;
    return isAuth ? child : const AuthScreen();
  }
}