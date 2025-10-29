// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import 'package:device_preview/device_preview.dart';



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
// MODELS
// -----------------------------------------------------------------------------
class Post {
  final String id;
  final String title;
  final String body;
  final List<String> tags;
  final DateTime createdAt;
  final String authorId;
  final String authorName;
  int votes;
  final Set<String> voters;
  final List<Reply> replies;

  Post({
    required this.id,
    required this.title,
    required this.body,
    required this.tags,
    required this.createdAt,
    required this.authorId,
    required this.authorName,
    this.votes = 0,
    Set<String>? voters,
    List<Reply>? replies,
  })  : voters = voters ?? <String>{},
        replies = replies ?? <Reply>[];

  Post copyWith({
    int? votes,
    Set<String>? voters,
    List<Reply>? replies,
  }) {
    return Post(
      id: id,
      title: title,
      body: body,
      tags: tags,
      createdAt: createdAt,
      authorId: authorId,
      authorName: authorName,
      votes: votes ?? this.votes,
      voters: voters ?? this.voters,
      replies: replies ?? this.replies,
    );
  }
}

class Reply {
  final String id;
  final String authorId;
  final String authorName;
  final String body;
  final DateTime createdAt;

  Reply({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.body,
    required this.createdAt,
  });
}

// -----------------------------------------------------------------------------
// AppState (auth + in-memory data)
// -----------------------------------------------------------------------------
class AppState extends ChangeNotifier {
  final SharedPreferences prefs;
  bool _isAuthenticated = false;
  final List<Post> _posts = [];
  final Map<String, String> _userNames = {
    'local_user': 'You',
    'user-a1b2': 'Alice',
    'user-b2c3': 'Bob',
  };

  AppState(this.prefs) {
    _isAuthenticated = prefs.getBool('isAuthenticated') ?? false;
    _seedPosts();
  }

  // ---------- Auth ----------
  bool get isAuthenticated => _isAuthenticated;

  Future<void> mockLogin() async {
    _isAuthenticated = true;
    await prefs.setBool('isAuthenticated', true);
    notifyListeners();
  }

  Future<void> logout() async {
    _isAuthenticated = false;
    await prefs.setBool('isAuthenticated', false);
    notifyListeners();
  }

  // ---------- Posts ----------
  List<Post> get posts => List.unmodifiable(_posts);

  void addPost(Post p) {
    _posts.insert(0, p);
    notifyListeners();
  }

  void updatePost(Post updated) {
    final i = _posts.indexWhere((p) => p.id == updated.id);
    if (i != -1) {
      _posts[i] = updated;
      notifyListeners();
    }
  }

  void toggleVote(String postId, String userId) {
    final i = _posts.indexWhere((p) => p.id == postId);
    if (i == -1) return;
    final post = _posts[i];
    final newVoters = Set<String>.from(post.voters);
    if (newVoters.contains(userId)) {
      newVoters.remove(userId);
    } else {
      newVoters.add(userId);
    }
    final newVotes = newVoters.length;
    _posts[i] = post.copyWith(votes: newVotes, voters: newVoters);
    notifyListeners();
  }

  String userName(String id) => _userNames[id] ?? 'Anonymous';

  void _seedPosts() {
    const uuid = Uuid();
    final now = DateTime.now();
    _posts.addAll([
      Post(
        id: uuid.v4(),
        title: 'How to center a Container in Flutter?',
        body: 'I try to center a container but alignment not working. Any tips?',
        tags: const ['flutter', 'layout'],
        createdAt: now.subtract(const Duration(hours: 2)),
        authorId: 'user-a1b2',
        authorName: userName('user-a1b2'),
        votes: 7,
        voters: {'local_user', 'user-b2c3'},
        replies: [
          Reply(
            id: uuid.v4(),
            authorId: 'user-b2c3',
            authorName: userName('user-b2c3'),
            body: 'Wrap with Center widget or use Alignment.center.',
            createdAt: now.subtract(const Duration(hours: 1, minutes: 30)),
          ),
        ],
      ),
      Post(
        id: uuid.v4(),
        title: 'Best way to persist user settings in web?',
        body: 'What is recommended for small settings when building flutter web?',
        tags: const ['web', 'persistence'],
        createdAt: now.subtract(const Duration(days: 1, hours: 4)),
        authorId: 'local_user',
        authorName: userName('local_user'),
        votes: 12,
        voters: {'user-a1b2'},
      ),
    ]);
  }
}

// -----------------------------------------------------------------------------
// MAIN APP
// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------
// MAIN (with Device Preview)
// -----------------------------------------------------------------------------

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();

  runApp(
    DevicePreview(
      enabled: true, // Turn ON/OFF device preview easily
      builder: (context) => ChangeNotifierProvider(
        create: (_) => AppState(prefs),
        child: const CommunityForumApp(),
      ),
    ),
  );
}

class CommunityForumApp extends StatelessWidget {
  const CommunityForumApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Community Forum',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        scaffoldBackgroundColor: Colors.grey[50],
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
          elevation: 2,
          titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        cardTheme:  CardThemeData(
          elevation: 6,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      initialRoute: SplashScreen.routeName,
      onGenerateRoute: AppRouter.onGenerateRoute,
    );
  }
}

// -----------------------------------------------------------------------------
// ROUTER + AUTH GUARD
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
        final postId = settings.arguments as String;
        return PostDetailScreen(postId: postId);
      case CreatePostScreen.routeName:
        return const CreatePostScreen();
      case SearchScreen.routeName:
        return const SearchScreen();
      case ProfileScreen.routeName:
        final userId = settings.arguments as String? ?? 'local_user';
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

class _AuthGuard extends StatelessWidget {
  final RouteSettings settings;
  final Widget child;

  const _AuthGuard({required this.settings, required this.child, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final route = settings.name!;
    if (route == SplashScreen.routeName || route == AuthScreen.routeName) {
      return child;
    }
    final auth = Provider.of<AppState>(context).isAuthenticated;
    return auth ? child : const AuthScreen();
  }
}

// -----------------------------------------------------------------------------
// SPLASH
// -----------------------------------------------------------------------------
class SplashScreen extends StatelessWidget {
  static const routeName = '/splash';
  const SplashScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AppState>(context, listen: false).isAuthenticated;
    Future.delayed(const Duration(seconds: 1), () {
      if (!context.mounted) return;
      Navigator.pushReplacementNamed(
        context,
        auth ? HomeScreen.routeName : AuthScreen.routeName,
      );
    });

    return const Scaffold(
      backgroundColor: Colors.teal,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.forum, size: 80, color: Colors.white),
            SizedBox(height: 24),
            CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}
// -----------------------------------------------------------------------------
// AUTH (Modern Design)
// -----------------------------------------------------------------------------

class AuthScreen extends StatelessWidget {
  static const routeName = '/auth';
  const AuthScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Welcome'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF00BFA5), Color(0xFF1DE9B6)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              elevation: 10,
              shadowColor: Colors.black26,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // App Logo or Icon
                    const CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.teal,
                      child: Icon(Icons.forum_rounded,
                          color: Colors.white, size: 40),
                    ),
                    const SizedBox(height: 16),

                    const Text(
                      "Community Forum",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Join the conversation and share your thoughts.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Login button
                    ElevatedButton.icon(
                      onPressed: () async {
                        await Provider.of<AppState>(context, listen: false)
                            .mockLogin();
                        if (context.mounted) {
                          Navigator.pushReplacementNamed(
                              context, HomeScreen.routeName);
                        }
                      },
                      icon: const Icon(Icons.login_rounded),
                      label: const Text(
                        'Continue',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 56),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 4,
                      ),
                    ),

                    const SizedBox(height: 20),
                    Text(
                      "By continuing, you agree to our Terms & Privacy Policy.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
// -----------------------------------------------------------------------------
// HOME / FORUM
// -----------------------------------------------------------------------------
class HomeScreen extends StatefulWidget {
  static const routeName = '/home';
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

enum _SortMode { newest, top }

class _HomeScreenState extends State<HomeScreen> {
  String _search = '';
  _SortMode _sort = _SortMode.newest;
  final _myId = 'local_user';

  List<Post> _filteredPosts(AppState app) {
    var list = app.posts.where((p) {
      final q = _search.toLowerCase();
      if (q.isEmpty) return true;
      return p.title.toLowerCase().contains(q) ||
          p.body.toLowerCase().contains(q) ||
          p.tags.any((t) => t.toLowerCase().contains(q));
    }).toList();

    if (_sort == _SortMode.newest) {
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } else {
      list.sort((a, b) => b.votes.compareTo(a.votes));
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, app, _) {
        final posts = _filteredPosts(app);
        return Scaffold(
          appBar: AppBar(
            title: const Text('Community Forum'),
            actions: [
              IconButton(
                icon: Icon(_sort == _SortMode.newest ? Icons.new_releases : Icons.trending_up),
                tooltip: 'Sort',
                onPressed: () => setState(() => _sort = _sort == _SortMode.newest ? _SortMode.top : _SortMode.newest),
              ),
              IconButton(
                icon: const Icon(Icons.person),
                tooltip: 'Profile',
                onPressed: () => Navigator.pushNamed(context, ProfileScreen.routeName, arguments: _myId),
              ),
              IconButton(
                icon: const Icon(Icons.settings),
                tooltip: 'Settings',
                onPressed: () => Navigator.pushNamed(context, SettingsScreen.routeName),
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(56),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search posts...',
                    fillColor: Colors.white,
                    filled: true,
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onChanged: (v) => setState(() => _search = v),
                ),
              ),
            ),
          ),
          body: posts.isEmpty
              ? const Center(child: Text('No posts yet – create one!'))
              : ListView.builder(
                  itemCount: posts.length,
                  padding: const EdgeInsets.all(8),
                  itemBuilder: (_, i) {
                    final p = posts[i];
                    final voted = p.voters.contains(_myId);
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        onTap: () => Navigator.pushNamed(
                          context,
                          PostDetailScreen.routeName,
                          arguments: p.id,
                        ),
                        leading: CircleAvatar(
                          backgroundColor: Colors.teal.shade100,
                          child: Text(p.authorName[0]),
                        ),
                        title: Text(p.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p.body, maxLines: 2, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 4),
                            Wrap(
                              spacing: 4,
                              children: p.tags
                                  .map((t) => Chip(label: Text(t), padding: EdgeInsets.zero))
                                  .toList(),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${p.replies.length} replies • ${timeAgo(p.createdAt)} • ${p.authorName}',
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                        trailing: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(voted ? Icons.thumb_up : Icons.thumb_up_outlined,
                                  color: voted ? Colors.teal : null),
                              onPressed: () => app.toggleVote(p.id, _myId),
                            ),
                            Text('${p.votes}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
          floatingActionButton: FloatingActionButton(
            backgroundColor: Colors.teal,
            child: const Icon(Icons.add, color: Colors.white),
            onPressed: () => Navigator.pushNamed(context, CreatePostScreen.routeName),
          ),
        );
      },
    );
  }
}

// -----------------------------------------------------------------------------
// POST DETAIL (includes comments) - FIXED CRASH
// -----------------------------------------------------------------------------
class PostDetailScreen extends StatefulWidget {
  static const routeName = '/post-detail';
  final String postId;
  const PostDetailScreen({Key? key, required this.postId}) : super(key: key);

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  Post? _post;
  final _replyCtrl = TextEditingController();
  final _myId = 'local_user';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Safe to use Provider here
    final app = Provider.of<AppState>(context, listen: false);
    _post = app.posts.cast<Post?>().firstWhere(
          (p) => p?.id == widget.postId,
          orElse: () => null,
        );
  }

  void _addReply() {
    final text = _replyCtrl.text.trim();
    if (text.isEmpty || _post == null) return;
    const uuid = Uuid();
    final reply = Reply(
      id: uuid.v4(),
      authorId: _myId,
      authorName: Provider.of<AppState>(context, listen: false).userName(_myId),
      body: text,
      createdAt: DateTime.now(),
    );
    final updated = _post!.copyWith(replies: [..._post!.replies, reply]);
    Provider.of<AppState>(context, listen: false).updatePost(updated);
    setState(() {
      _post = updated;
      _replyCtrl.clear();
    });
  }

  @override
  void dispose() {
    _replyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_post == null) {
      return const Scaffold(
        body: Center(child: Text('Post not found')),
      );
    }

    final app = Provider.of<AppState>(context);
    final voted = _post!.voters.contains(_myId);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Post'),
        actions: [
          IconButton(
            icon: Icon(voted ? Icons.thumb_up : Icons.thumb_up_outlined,
                color: voted ? Colors.white : null),
            onPressed: () => app.toggleVote(_post!.id, _myId),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Center(child: Text('${_post!.votes}')),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: Colors.teal.shade100,
                            child: Text(_post!.authorName[0]),
                          ),
                          const SizedBox(width: 8),
                          Text(_post!.authorName,
                              style: const TextStyle(fontWeight: FontWeight.bold)),
                          const Spacer(),
                          Text(timeAgo(_post!.createdAt),
                              style: const TextStyle(color: Colors.grey)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(_post!.title,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(_post!.body),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 6,
                        children: _post!.tags.map((t) => Chip(label: Text(t))).toList(),
                      ),
                      const Divider(height: 32),
                      const Text('Replies', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      if (_post!.replies.isEmpty)
                        const Center(child: Text('No replies yet – be the first!'))
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _post!.replies.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (_, i) {
                            final r = _post!.replies[i];
                            return ListTile(
                              leading: CircleAvatar(
                                radius: 16,
                                backgroundColor: Colors.teal.shade100,
                                child: Text(r.authorName[0]),
                              ),
                              title: Text(r.authorName,
                                  style: const TextStyle(fontSize: 14)),
                              subtitle: Text(r.body),
                              trailing: Text(timeAgo(r.createdAt),
                                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _replyCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Write a reply...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.teal),
                  onPressed: _addReply,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// CREATE POST
// -----------------------------------------------------------------------------
class CreatePostScreen extends StatefulWidget {
  static const routeName = '/create-post';
  const CreatePostScreen({Key? key}) : super(key: key);

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  final _tagsCtrl = TextEditingController();
  final _myId = 'local_user';

  void _submit() {
    final title = _titleCtrl.text.trim();
    final body = _bodyCtrl.text.trim();
    final tags = _tagsCtrl.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    if (title.isEmpty || body.isEmpty) return;

    final app = Provider.of<AppState>(context, listen: false);
    const uuid = Uuid();
    final post = Post(
      id: uuid.v4(),
      title: title,
      body: body,
      tags: tags,
      createdAt: DateTime.now(),
      authorId: _myId,
      authorName: app.userName(_myId),
    );
    app.addPost(post);
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    _tagsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Post'), actions: [
        TextButton(
          onPressed: _submit,
          child: const Text('Post', style: TextStyle(color: Colors.white)),
        ),
      ]),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _titleCtrl,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _bodyCtrl,
              decoration: const InputDecoration(
                labelText: 'Body',
                border: OutlineInputBorder(),
              ),
              maxLines: 6,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _tagsCtrl,
              decoration: const InputDecoration(
                labelText: 'Tags (comma separated)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// SEARCH
// -----------------------------------------------------------------------------
class SearchScreen extends StatefulWidget {
  static const routeName = '/search';
  const SearchScreen({Key? key}) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Search posts...',
            border: InputBorder.none,
          ),
          onChanged: (v) => setState(() => _query = v),
        ),
        actions: [
          if (_query.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () => setState(() => _query = ''),
            ),
        ],
      ),
      body: Consumer<AppState>(
        builder: (_, app, __) {
          final filtered = app.posts.where((p) {
            final q = _query.toLowerCase();
            return p.title.toLowerCase().contains(q) ||
                p.body.toLowerCase().contains(q) ||
                p.tags.any((t) => t.toLowerCase().contains(q));
          }).toList();

          return filtered.isEmpty
              ? const Center(child: Text('No results'))
              : ListView.builder(
                  itemCount: filtered.length,
                  padding: const EdgeInsets.all(8),
                  itemBuilder: (_, i) {
                    final p = filtered[i];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        title: Text(p.title),
                        subtitle: Text(p.body, maxLines: 1, overflow: TextOverflow.ellipsis),
                        trailing: Text('${p.votes} votes'),
                        onTap: () => Navigator.pushNamed(
                          context,
                          PostDetailScreen.routeName,
                          arguments: p.id,
                        ),
                      ),
                    );
                  },
                );
        },
      ),
    );
  }
}



class ProfileScreen extends StatelessWidget {
  static const routeName = '/profile';
  final String userId;

  const ProfileScreen({Key? key, required this.userId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final app = Provider.of<AppState>(context);
    final name = app.userName(userId);
    final myPosts = app.posts.where((p) => p.authorId == userId).toList();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Profile"),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          // Gradient background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF00BFA5), Color(0xFF1DE9B6)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // Content
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  const SizedBox(height: 20),

                  // Profile Card
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const CircleAvatar(
                          radius: 50,
                          backgroundImage: AssetImage('assets/images/profile_placeholder.png'),
                          backgroundColor: Colors.tealAccent,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Community Member",
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildStat("Posts", myPosts.length.toString()),
                            _buildStat("Votes", myPosts.fold<int>(0, (sum, p) => sum + p.votes).toString()),
                            _buildStat("Replies", myPosts.fold<int>(0, (sum, p) => sum + p.replies.length).toString()),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Recent Posts",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Posts List
                  if (myPosts.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 80),
                      child: Text(
                        "No posts yet 😅",
                        style: TextStyle(fontSize: 16, color: Colors.black54),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: myPosts.length,
                      itemBuilder: (_, i) {
                        final post = myPosts[i];
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: ListTile(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                            contentPadding: const EdgeInsets.all(16),
                            title: Text(
                              post.title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            subtitle: Text(
                              "${post.replies.length} replies • ${post.votes} votes",
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                            ),
                            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 18),
                            onTap: () => Navigator.pushNamed(
                              context,
                              PostDetailScreen.routeName,
                              arguments: post.id,
                            ),
                          ),
                        );
                      },
                    ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.teal,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: Colors.black54),
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// NOTIFICATIONS
// -----------------------------------------------------------------------------
class NotificationsScreen extends StatelessWidget {
  static const routeName = '/notifications';
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: const Center(child: Text('No new notifications')),
    );
  }
}
// -----------------------------------------------------------------------------
// SETTINGS
// -----------------------------------------------------------------------------


class SettingsScreen extends StatelessWidget {
  static const routeName = '/settings';
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Profile section
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            leading: CircleAvatar(
              radius: 25,
              backgroundColor: Colors.teal.shade100,
              child: const Icon(Icons.person, color: Colors.teal, size: 28),
            ),
            title: const Text(
              'Your Profile',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: const Text('View and edit your personal info'),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
            onTap: () {
              // Navigate to profile screen if needed
              // Navigator.pushNamed(context, ProfileScreen.routeName);
            },
          ),

          const SizedBox(height: 24),
          const Text(
            'Preferences',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),

          Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 0.5,
            child: Column(
              children: [
                _buildSettingTile(
                  icon: Icons.palette_rounded,
                  title: 'Theme',
                  subtitle: 'Light / Dark mode',
                  onTap: () {},
                ),
                _divider(),
                _buildSettingTile(
                  icon: Icons.notifications_rounded,
                  title: 'Notifications',
                  subtitle: 'Manage push alerts',
                  onTap: () {},
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          const Text(
            'Support',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),

          Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 0.5,
            child: Column(
              children: [
                _buildSettingTile(
                  icon: Icons.help_outline_rounded,
                  title: 'Help & FAQ',
                  subtitle: 'Get answers and tips',
                  onTap: () {},
                ),
                _divider(),
                _buildSettingTile(
                  icon: Icons.lock_outline_rounded,
                  title: 'Privacy Policy',
                  subtitle: 'View app data usage',
                  onTap: () {},
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          const Text(
            'Account',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),

          Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 0.5,
            child: Column(
              children: [
                _buildSettingTile(
                  icon: Icons.logout_rounded,
                  title: 'Logout',
                  subtitle: 'Sign out of your account',
                  color: Colors.redAccent,
                  onTap: () async {
                    await Provider.of<AppState>(context, listen: false).logout();
                    if (context.mounted) {
                      Navigator.pushReplacementNamed(
                          context, AuthScreen.routeName);
                    }
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),
          Center(
            child: Text(
              'App version 1.0.0',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Color? color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: CircleAvatar(
        radius: 20,
        backgroundColor:
            color?.withOpacity(0.1) ?? Colors.teal.shade50.withOpacity(0.4),
        child: Icon(icon, color: color ?? Colors.teal, size: 22),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: color ?? Colors.black87,
        ),
      ),
      subtitle: subtitle != null
          ? Text(subtitle, style: const TextStyle(fontSize: 13))
          : null,
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
      onTap: onTap,
    );
  }

  Widget _divider() {
    return const Padding(
      padding: EdgeInsets.only(left: 72, right: 16),
      child: Divider(height: 1),
    );
  }
}

// -----------------------------------------------------------------------------
// UTILS
// -----------------------------------------------------------------------------
String timeAgo(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return '${dt.month}/${dt.day}/${dt.year}';
}