import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'onboarding_screen.dart';
import 'splash_screen.dart';

const _onboardingCompletedKey = 'onboarding_completed';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final preferences = await SharedPreferences.getInstance();
  runApp(
    CineClipApp(
      onboardingCompleted:
          preferences.getBool(_onboardingCompletedKey) ?? false,
    ),
  );
}

class CineClipApp extends StatefulWidget {
  const CineClipApp({super.key, this.onboardingCompleted = false});

  final bool onboardingCompleted;

  @override
  State<CineClipApp> createState() => _CineClipAppState();
}

class _CineClipAppState extends State<CineClipApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();

  Future<void> _completeOnboarding() async {
    final preferences = await SharedPreferences.getInstance();
    final saved = await preferences.setBool(_onboardingCompletedKey, true);
    if (!saved) {
      throw StateError('Could not save onboarding completion.');
    }

    final navigator = _navigatorKey.currentState;
    if (navigator == null) {
      throw StateError('The app navigator is not available.');
    }
    navigator.pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const CineClipHomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'CineClip',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF21C8FF),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF020B25),
        useMaterial3: true,
      ),
      home: CineClipSplashScreen(
        nextScreen: widget.onboardingCompleted
            ? const CineClipHomeScreen()
            : OnboardingScreen(onGetStarted: _completeOnboarding),
      ),
    );
  }
}

class CineClipHomeScreen extends StatelessWidget {
  const CineClipHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'CineClip',
                style: TextStyle(
                  color: Color(0xFF43D8FF),
                  fontSize: 36,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Your next story starts here.',
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(color: Colors.white70),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
