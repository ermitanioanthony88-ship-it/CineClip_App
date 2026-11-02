import 'package:flutter/material.dart';

import 'splash_screen.dart';

void main() {
  runApp(const CineClipApp());
}

class CineClipApp extends StatelessWidget {
  const CineClipApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
      home: const CineClipSplashScreen(nextScreen: CineClipHomeScreen()),
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
