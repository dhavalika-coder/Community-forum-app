import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// =========================================================================
// MOCK: SharedPreferences (replaces missing package)
// =========================================================================
class SharedPreferences {
  final Map<String, dynamic> _data = {};

  static Future<SharedPreferences> getInstance() async {
    return SharedPreferences._internal();
  }

  SharedPreferences._internal();

  bool? getBool(String key) => _data[key] as bool?;
}

// =========================================================================
// STUB: AppState
// =========================================================================
class AppState extends ChangeNotifier {
  final SharedPreferences prefs;

  AppState(this.prefs) {
    prefs.getBool('isAuthenticated');
  }
}

// =========================================================================
// BASE STUB SCREEN
// =========================================================================
class _BaseScreenStub extends StatelessWidget {
  final String title;

  const _BaseScreenStub(this.title, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Text(
          '$title Screen (Stub)',
          style: const TextStyle(fontSize: 18, color: Colors.teal),
        ),
      ),
    );
  }
}

// =========================================================================
// SCREEN STUBS (with Key? key)
// =========================================================================

class SplashScreen extends _BaseScreenStub {
  static const routeName = '/splash';
  const SplashScreen({Key? key}) : super('Splash', key: key);
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

// =========================================================================
// MAIN APP
// =========================================================================

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
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: Colors.teal,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: Colors.grey[100],
        // Fixed: Use CardThemeData, not CardTheme
        cardTheme: const CardThemeData(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.teal,
          elevation: 0,
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

// =========================================================================
// ROUTER
// =========================================================================
class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case SplashScreen.routeName:
        return _buildRoute(settings, const SplashScreen());
      case AuthScreen.routeName:
        return _buildRoute(settings, const AuthScreen());
      case HomeScreen.routeName:
        return _buildRoute(settings, const HomeScreen());
      case PostDetailScreen.routeName:
        final postId = settings.arguments as String? ?? 'N/A';
        return _buildRoute(settings, PostDetailScreen(postId: postId));
      case CreatePostScreen.routeName:
        return _buildRoute(settings, const CreatePostScreen());
      case CommentsScreen.routeName:
        final postId = settings.arguments as String? ?? 'N/A';
        return _buildRoute(settings, CommentsScreen(postId: postId));
      case SearchScreen.routeName:
        return _buildRoute(settings, const SearchScreen());
      case ProfileScreen.routeName:
        final userId = settings.arguments as String? ?? 'N/A';
        return _buildRoute(settings, ProfileScreen(userId: userId));
      case NotificationsScreen.routeName:
        return _buildRoute(settings, const NotificationsScreen());
      case SettingsScreen.routeName:
        return _buildRoute(settings, const SettingsScreen());
      default:
        return _buildRoute(settings, const SplashScreen());
    }
  }

  static PageRouteBuilder _buildRoute(RouteSettings settings, Widget widget) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => widget,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeOut;
        final tween =
            Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
    );
  }
}