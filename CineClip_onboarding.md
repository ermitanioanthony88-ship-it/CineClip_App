# CineClip Onboarding Screens

Implementation guide for the three CineClip onboarding screens shown in the attached UI flow.

## Onboarding flow

The onboarding starts after the 5-second splash screen and contains three pages:

| Page | Heading | Description | Button |
|---|---|---|---|
| 1 — Your Photos, Your Story | Your Photos, Your Story | Turn your favorite photos into amazing videos. | Next |
| 2 — Make It Move | Make It Move | Enjoy smooth transitions with simple motion. | Next |
| 3 — Save and Share | Save and Share | Keep your creations and share them easily. | Get Started |

### Visual style

- Dark navy/black background with glowing blue and cyan accents.
- Large illustration or preview image centered in the upper portion.
- White bold heading and smaller white/gray description.
- Three page indicator dots near the bottom; active dot is cyan.
- Rounded bright-blue primary button.
- Status bar at the top; maintain safe areas on different devices.
- Page 1 and 2 have a `Next` button. Page 3 has `Get Started`.
- `Skip` may be shown in the top-right corner (optional).

## Flutter implementation

Create `lib/onboarding_screen.dart`.

This sample uses `PageView` so users can swipe between pages as well as tap Next. Replace the illustration asset paths with your own exported images from the design.

```dart
import 'package:flutter/material.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({
    super.key,
    required this.onGetStarted,
  });

  /// Called after the user taps Get Started on the last page.
  final VoidCallback onGetStarted;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_OnboardingPageData> _pages = const [
    _OnboardingPageData(
      title: 'Your Photos,\\nYour Story',
      description: 'Turn your favorite photos\\ninto amazing videos.',
      asset: 'assets/images/onboarding_1.png',
    ),
    _OnboardingPageData(
      title: 'Make It Move',
      description: 'Enjoy smooth transitions\\nwith simple motion.',
      asset: 'assets/images/onboarding_2.png',
    ),
    _OnboardingPageData(
      title: 'Save and Share',
      description: 'Keep your creations\\nand share them easily.',
      asset: 'assets/images/onboarding_3.png',
    ),
  ];

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      widget.onGetStarted();
    }
  }

  void _skip() {
    _pageController.animateToPage(
      _pages.length - 1,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xFF020B25);
    const blue = Color(0xFF087BFF);
    const cyan = Color(0xFF20D7FF);

    return Scaffold(
      backgroundColor: navy,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _currentPage == _pages.length - 1 ? null : _skip,
                child: Text(
                  'Skip',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemBuilder: (context, index) {
                  final page = _pages[index];

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          flex: 6,
                          child: Center(
                            child: Image.asset(
                              page.asset,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.movie_creation_outlined,
                                size: 150,
                                color: cyan,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          page.title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          page.description,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.78),
                            fontSize: 16,
                            height: 1.4,
                          ),
                        ),
                        const Spacer(),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_pages.length, (index) {
                final active = index == _currentPage;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: active ? 20 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: active ? cyan : blue.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(8),
                  ),
                );
              }),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _nextPage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  child: Text(
                    _currentPage == _pages.length - 1
                        ? 'Get Started'
                        : 'Next  →',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPageData {
  const _OnboardingPageData({
    required this.title,
    required this.description,
    required this.asset,
  });

  final String title;
  final String description;
  final String asset;
}
```

## Add onboarding illustration assets

Place your three page illustrations in this structure:

```text
assets/
  images/
    onboarding_1.png
    onboarding_2.png
    onboarding_3.png
```

Declare the folder in `pubspec.yaml`:

```yaml
flutter:
  assets:
    - assets/images/
```

Then run:

```bash
flutter pub get
```

## Connect splash screen to onboarding

In your splash screen, pass `OnboardingScreen` as the next screen after the splash timer completes:

```dart
CineClipSplashScreen(
  nextScreen: OnboardingScreen(
    onGetStarted: () {
      // Navigate to CineClip Home Screen.
    },
  ),
);
```

If your splash widget expects a `Widget nextScreen`, the `onGetStarted` callback should navigate to the Home Screen using your app's existing navigation setup. Avoid creating a second `MaterialApp` inside onboarding.

## Behavior checklist

- [ ] Starts on onboarding page 1 after the splash screen.
- [ ] Users can swipe between the three pages.
- [ ] Next advances one page.
- [ ] Skip jumps to the final page.
- [ ] The page indicator updates with the current page.
- [ ] Get Started proceeds to the Home Screen.
- [ ] Layout adapts to small and large phone screens.
