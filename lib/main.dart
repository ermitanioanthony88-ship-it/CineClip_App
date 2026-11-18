import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'home_screen.dart';
import 'onboarding_screen.dart';
import 'settings_screen.dart';
import 'splash_screen.dart';

const _onboardingCompletedKey = 'onboarding_completed';

ThemeMode _themeModeFromPreference(String? value) => switch (value) {
  'dark' => ThemeMode.dark,
  'light' => ThemeMode.light,
  _ => ThemeMode.system,
};

String _preferenceValueForThemeMode(ThemeMode mode) => switch (mode) {
  ThemeMode.system => 'system',
  ThemeMode.dark => 'dark',
  ThemeMode.light => 'light',
};

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final preferences = await SharedPreferences.getInstance();
  runApp(
    CineClipApp(
      onboardingCompleted:
          preferences.getBool(_onboardingCompletedKey) ?? false,
      themeMode: _themeModeFromPreference(
        preferences.getString(settingsThemeModeKey),
      ),
    ),
  );
}

class CineClipApp extends StatefulWidget {
  const CineClipApp({
    super.key,
    this.onboardingCompleted = false,
    this.themeMode = ThemeMode.system,
  });

  final bool onboardingCompleted;
  final ThemeMode themeMode;

  @override
  State<CineClipApp> createState() => _CineClipAppState();
}

class _CineClipAppState extends State<CineClipApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  late ThemeMode _themeMode = widget.themeMode;

  Future<void> _changeThemeMode(ThemeMode mode) async {
    final preferences = await SharedPreferences.getInstance();
    final saved = await preferences.setString(
      settingsThemeModeKey,
      _preferenceValueForThemeMode(mode),
    );
    if (!saved) throw StateError('Could not save appearance setting.');
    if (mounted) setState(() => _themeMode = mode);
  }

  void _openSettings() {
    final navigator = _navigatorKey.currentState;
    if (navigator == null) {
      throw StateError('The app navigator is not available.');
    }
    navigator.push<void>(
      MaterialPageRoute(
        builder: (_) => CineClipSettingsScreen(
          themeMode: _themeMode,
          onThemeModeChanged: _changeThemeMode,
        ),
      ),
    );
  }

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
    MaterialPageRoute<void>(
      builder: (_) => CineClipHomeScreen(onOpenSettings: _openSettings),
    ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'CineClip',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: ThemeData(
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF21C8FF),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF4F7FB),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
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
            ? CineClipHomeScreen(onOpenSettings: _openSettings)
            : OnboardingScreen(onGetStarted: _completeOnboarding),
      ),
    );
  }
}
