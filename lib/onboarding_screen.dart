import 'package:flutter/material.dart';

const _sampleImageUrls = [
  'https://images.unsplash.com/photo-1470770841072-f978cf4d019e?auto=format&fit=crop&w=800&q=85',
  'https://images.unsplash.com/photo-1500530855697-b586d89ba3ee?auto=format&fit=crop&w=800&q=85',
  'https://images.unsplash.com/photo-1470252649378-9c29740c9fa8?auto=format&fit=crop&w=800&q=85',
];

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.onGetStarted});

  final VoidCallback onGetStarted;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const _pages = [
    _OnboardingPageData(
      title: 'Your Photos,\nYour Story',
      description: 'Turn your favorite photos\ninto amazing videos.',
    ),
    _OnboardingPageData(
      title: 'Make It Move',
      description: 'Enjoy smooth transitions\nwith simple motion.',
    ),
    _OnboardingPageData(
      title: 'Save and Share',
      description: 'Keep your creations\nand share them easily.',
    ),
  ];

  final PageController _pageController = PageController();
  int _currentPage = 0;

  void _nextPage() {
    if (_currentPage == _pages.length - 1) {
      widget.onGetStarted();
      return;
    }

    _pageController.nextPage(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
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
      body: Stack(
        children: [
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF071630), navy, Color(0xFF04132F)],
                ),
              ),
            ),
          ),
          Positioned(
            top: 100,
            left: -100,
            child: _Glow(color: const Color(0x2220D7FF), size: 260),
          ),
          Positioned(
            right: -120,
            bottom: 60,
            child: _Glow(color: const Color(0x1C087BFF), size: 300),
          ),
          SafeArea(
            child: Column(
              children: [
                SizedBox(
                  height: 48,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _currentPage == _pages.length - 1
                          ? null
                          : _skip,
                      child: Text(
                        'Skip',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
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
                          children: [
                            Expanded(
                              flex: 6,
                              child: Center(
                                child: _OnboardingIllustration(index: index),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              page.title,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                height: 1.12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              page.description,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.76),
                                fontSize: 16,
                                height: 1.45,
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
                    final isActive = index == _currentPage;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: isActive ? 20 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isActive ? cyan : blue.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    );
                  }),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
                  child: SizedBox(
                    width: double.infinity,
                    height: 54,
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
                            : 'Next',
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
        ],
      ),
    );
  }
}

class _OnboardingPageData {
  const _OnboardingPageData({required this.title, required this.description});

  final String title;
  final String description;
}

class _SamplePhoto extends StatelessWidget {
  const _SamplePhoto({
    required this.imageUrl,
    required this.fallbackColor,
    required this.fallbackIcon,
  });

  final String imageUrl;
  final Color fallbackColor;
  final IconData fallbackIcon;

  @override
  Widget build(BuildContext context) {
    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          return child;
        }
        return _fallback();
      },
      errorBuilder: (context, error, stackTrace) => _fallback(),
    );
  }

  Widget _fallback() {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [fallbackColor.withValues(alpha: 0.55), fallbackColor],
        ),
      ),
      child: Center(
        child: Icon(fallbackIcon, size: 100, color: const Color(0xFFA8EEFF)),
      ),
    );
  }
}

class _OnboardingIllustration extends StatelessWidget {
  const _OnboardingIllustration({required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 300, maxHeight: 300),
      child: AspectRatio(
        aspectRatio: 1,
        child: Stack(
          alignment: Alignment.center,
          children: [
            const _Glow(color: Color(0x3320D7FF), size: 240),
            if (index == 0) const _PhotoIllustration(),
            if (index == 1) const _MotionIllustration(),
            if (index == 2) const _ShareIllustration(),
          ],
        ),
      ),
    );
  }
}

class _PhotoIllustration extends StatelessWidget {
  const _PhotoIllustration();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Transform.rotate(
          angle: -0.16,
          child: _photoCard(
            imageUrl: _sampleImageUrls[0],
            color: const Color(0xFF1463A5),
            icon: Icons.landscape_rounded,
          ),
        ),
        Transform.rotate(
          angle: 0.13,
          child: _photoCard(
            imageUrl: _sampleImageUrls[1],
            color: const Color(0xFF1D84AF),
            icon: Icons.waves_rounded,
          ),
        ),
        Transform.translate(
          offset: const Offset(-5, 5),
          child: _photoCard(
            imageUrl: _sampleImageUrls[2],
            color: const Color(0xFF176B9D),
            icon: Icons.landscape_rounded,
          ),
        ),
        Positioned(
          right: 27,
          bottom: 34,
          child: _floatingBadge(
            icon: Icons.auto_awesome_rounded,
            color: const Color(0xFF20D7FF),
          ),
        ),
      ],
    );
  }

  Widget _photoCard({
    required String imageUrl,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      width: 174,
      height: 212,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF10294A),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF70DFFF), width: 1.5),
        boxShadow: const [
          BoxShadow(color: Color(0x5515AFFF), blurRadius: 28, spreadRadius: 1),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          fit: StackFit.expand,
          children: [
            _SamplePhoto(
              imageUrl: imageUrl,
              fallbackColor: color,
              fallbackIcon: icon,
            ),
            Positioned(
              top: 20,
              right: 22,
              child: Icon(
                Icons.circle,
                size: 26,
                color: const Color(0xFFFFD978).withValues(alpha: 0.9),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MotionIllustration extends StatelessWidget {
  const _MotionIllustration();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 204,
          height: 254,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF0B1D38),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: const Color(0xFF2874B9), width: 1.5),
            boxShadow: const [
              BoxShadow(color: Color(0x5520BFFF), blurRadius: 32),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.movie_creation_outlined,
                    color: Color(0xFF20D7FF),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'MY STORY',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.4,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    fit: StackFit.expand,
                    alignment: Alignment.center,
                    children: [
                      _SamplePhoto(
                        imageUrl: _sampleImageUrls[1],
                        fallbackColor: const Color(0xFF1465A5),
                        fallbackIcon: Icons.landscape_rounded,
                      ),
                      const Icon(
                        Icons.play_circle_fill_rounded,
                        color: Colors.white,
                        size: 58,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: List.generate(
                  6,
                  (index) => Expanded(
                    child: Container(
                      height: 22,
                      margin: const EdgeInsets.only(right: 4),
                      decoration: BoxDecoration(
                        color: index.isEven
                            ? const Color(0xFF20D7FF)
                            : const Color(0xFF2167A2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          left: 16,
          top: 52,
          child: _floatingBadge(
            icon: Icons.auto_awesome_rounded,
            color: const Color(0xFF20D7FF),
          ),
        ),
        Positioned(
          right: 12,
          bottom: 42,
          child: _floatingBadge(
            icon: Icons.bolt_rounded,
            color: const Color(0xFF6C8BFF),
          ),
        ),
      ],
    );
  }
}

class _ShareIllustration extends StatelessWidget {
  const _ShareIllustration();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 204,
          height: 254,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF0B1D38),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: const Color(0xFF2874B9), width: 1.5),
            boxShadow: const [
              BoxShadow(color: Color(0x5520BFFF), blurRadius: 32),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF20D7FF),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'STORY SAVED',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.4,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    fit: StackFit.expand,
                    alignment: Alignment.center,
                    children: [
                      _SamplePhoto(
                        imageUrl: _sampleImageUrls[2],
                        fallbackColor: const Color(0xFF1465A5),
                        fallbackIcon: Icons.landscape_rounded,
                      ),
                      const Icon(
                        Icons.play_circle_fill_rounded,
                        color: Colors.white,
                        size: 52,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _shareAction(Icons.photo_library_rounded),
                  _shareAction(Icons.chat_bubble_rounded),
                  _shareAction(Icons.link_rounded),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _shareAction(IconData icon) {
    return Container(
      width: 42,
      height: 30,
      decoration: BoxDecoration(
        color: const Color(0xFF15385D),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF2874B9)),
      ),
      child: Icon(icon, color: const Color(0xFF20D7FF), size: 17),
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
        ),
      ),
    );
  }
}

Widget _floatingBadge({required IconData icon, required Color color}) {
  return Container(
    width: 48,
    height: 48,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: const Color(0xFF102746),
      border: Border.all(color: color.withValues(alpha: 0.8)),
      boxShadow: [
        BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 18),
      ],
    ),
    child: Icon(icon, color: color, size: 23),
  );
}
