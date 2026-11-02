# CineClip Splash Screen (5 Seconds)

A dark navy and neon-blue splash screen for **CineClip — Turn Moments Into Movies**.

## Design

- Centered CineClip clapperboard/play logo
- CineClip wordmark with white `Cine` and cyan `Clip`
- Tagline: “Turn Moments Into Movies”
- Cinematic film-strip accents and blue glow
- Splash screen duration: **5 seconds**
- Automatically navigates to the next screen after 5 seconds

## Asset setup

Save the generated splash-screen artwork in your Flutter project as:

```text
assets/images/cineclip_splash.png
```

Add it to `pubspec.yaml`:

```yaml
flutter:
  assets:
    - assets/images/cineclip_splash.png
```

## Flutter implementation

Create `lib/splash_screen.dart`:

```dart
import 'dart:async';
import 'package:flutter/material.dart';

class CineClipSplashScreen extends StatefulWidget {
  const CineClipSplashScreen({
    super.key,
    required this.nextScreen,
  });

  /// Screen to show after the 5-second splash screen.
  final Widget nextScreen;

  @override
  State<CineClipSplashScreen> createState() => _CineClipSplashScreenState();
}

class _CineClipSplashScreenState extends State<CineClipSplashScreen> {
  Timer? _splashTimer;

  @override
  void initState() {
    super.initState();

    _splashTimer = Timer(const Duration(seconds: 5), () {
      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => widget.nextScreen),
      );
    });
  }

  @override
  void dispose() {
    _splashTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020B25),
      body: SizedBox.expand(
        child: Image.asset(
          'assets/images/cineclip_splash.png',
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
```

## Use it

For example, show the onboarding screen after the splash:

```dart
MaterialApp(
  home: CineClipSplashScreen(
    nextScreen: const OnboardingScreen(),
  ),
);
```

Replace `OnboardingScreen()` with the screen that should appear next in your app.

## Notes

- The timer starts when the splash widget is created and transitions after 5 seconds.
- The splash artwork is displayed edge-to-edge with `BoxFit.cover`.
- Ensure the image asset path matches the path declared in `pubspec.yaml`.
