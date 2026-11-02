import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

class CineClipSplashScreen extends StatefulWidget {
  const CineClipSplashScreen({super.key, required this.nextScreen});

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
        MaterialPageRoute<void>(builder: (_) => widget.nextScreen),
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
      body: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF071630),
                  Color(0xFF020B25),
                  Color(0xFF04132F),
                ],
              ),
            ),
          ),
          const CustomPaint(painter: _FilmStripPainter()),
          Align(
            child: Container(
              width: 360,
              height: 360,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Color(0x3323BFFF), Color(0x00020B25)],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 148,
                      height: 112,
                      child: CustomPaint(painter: _ClapperboardPainter()),
                    ),
                    const SizedBox(height: 28),
                    const Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: 'Cine',
                            style: TextStyle(color: Colors.white),
                          ),
                          TextSpan(
                            text: 'Clip',
                            style: TextStyle(color: Color(0xFF36D4FF)),
                          ),
                        ],
                      ),
                      style: TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1.5,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Turn Moments Into Movies',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFFD8E6F8),
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(height: 34),
                    Container(
                      width: 34,
                      height: 3,
                      decoration: BoxDecoration(
                        color: const Color(0xFF36D4FF),
                        borderRadius: BorderRadius.circular(3),
                        boxShadow: const [
                          BoxShadow(color: Color(0x9936D4FF), blurRadius: 12),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'YOUR STORY, ON THE BIG SCREEN',
                      style: TextStyle(
                        color: Color(0xFF7593B8),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 2.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilmStripPainter extends CustomPainter {
  const _FilmStripPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final railPaint = Paint()
      ..color = const Color(0x1838CFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final sprocketPaint = Paint()..color = const Color(0x1538CFFF);
    final left = size.width * 0.055;
    final right = size.width - left;

    canvas.drawLine(Offset(left, 0), Offset(left, size.height), railPaint);
    canvas.drawLine(
      Offset(left + 12, 0),
      Offset(left + 12, size.height),
      railPaint,
    );
    canvas.drawLine(
      Offset(right - 12, 0),
      Offset(right - 12, size.height),
      railPaint,
    );
    canvas.drawLine(Offset(right, 0), Offset(right, size.height), railPaint);

    for (var y = 18.0; y < size.height; y += 38) {
      for (final x in [left + 3, right - 9]) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x, y, 6, 14),
            const Radius.circular(2),
          ),
          sprocketPaint,
        );
      }
    }

    final accentPaint = Paint()
      ..color = const Color(0x1238CFFF)
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(size.width * 0.18, size.height * 0.19),
      Offset(size.width * 0.32, size.height * 0.19),
      accentPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.68, size.height * 0.81),
      Offset(size.width * 0.82, size.height * 0.81),
      accentPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _FilmStripPainter oldDelegate) => false;
}

class _ClapperboardPainter extends CustomPainter {
  const _ClapperboardPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final scale = math.min(size.width / 148, size.height / 112);
    canvas.save();
    canvas.translate(
      (size.width - 148 * scale) / 2,
      (size.height - 112 * scale) / 2,
    );
    canvas.scale(scale);

    final body = RRect.fromRectAndRadius(
      const Rect.fromLTWH(10, 34, 128, 68),
      const Radius.circular(12),
    );
    canvas.drawRRect(
      body,
      Paint()
        ..color = const Color(0xFF071A3D)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16),
    );
    canvas.drawRRect(body, Paint()..color = const Color(0xFF0A2147));
    canvas.drawRRect(
      body,
      Paint()
        ..color = const Color(0xFF35D5FF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    final top = Path()
      ..moveTo(13, 30)
      ..lineTo(24, 8)
      ..lineTo(140, 8)
      ..lineTo(129, 30)
      ..close();
    canvas.drawPath(
      top,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFF087FCE), Color(0xFF36D5FF)],
        ).createShader(const Rect.fromLTWH(10, 8, 130, 24)),
    );

    canvas.save();
    canvas.clipPath(top);
    final stripePaint = Paint()
      ..color = const Color(0xCCDBF7FF)
      ..strokeWidth = 9;
    for (var x = 26.0; x < 145; x += 28) {
      canvas.drawLine(Offset(x, 6), Offset(x - 15, 34), stripePaint);
    }
    canvas.restore();

    final play = Path()
      ..moveTo(65, 50)
      ..lineTo(93, 68)
      ..lineTo(65, 86)
      ..close();
    canvas.drawPath(play, Paint()..color = const Color(0xFFECFAFF));
    canvas.drawLine(
      const Offset(19, 94),
      const Offset(39, 94),
      Paint()
        ..color = const Color(0xFF35D5FF)
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ClapperboardPainter oldDelegate) => false;
}
