import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// =========================================================================
// STUB: MockDB Provider (Replace with real one later)
// =========================================================================
class MockDB extends ChangeNotifier {
  String? currentUser;

  MockDB() {
    Future.delayed(const Duration(milliseconds: 500), () {
      currentUser = null; // Change to 'user123' to test logged-in
      notifyListeners();
    });
  }
}

// =========================================================================
// SPLASH SCREEN
// =========================================================================
class SplashScreen extends StatefulWidget {
  static const routeName = '/splash';

  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Fade animation
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    _controller.forward();

    // Navigate after delay
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;

      final mockDB = Provider.of<MockDB>(context, listen: false);
      final route = mockDB.currentUser == null ? '/login' : '/home';

      Navigator.pushReplacementNamed(context, route);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.forum,
                size: 80,
                color: Colors.white,
              ),
              SizedBox(height: 24),
              Text(
                'Community Forum',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Connect • Discuss • Grow',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}