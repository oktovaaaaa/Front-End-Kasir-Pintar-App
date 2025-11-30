import 'package:flutter/material.dart';

class OnboardingPage extends StatefulWidget {
  final VoidCallback onContinue;

  const OnboardingPage({super.key, required this.onContinue});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );

    Future.delayed(const Duration(seconds: 2), () async {
      await _controller.forward();
      if (mounted) {
        widget.onContinue();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final size = MediaQuery.of(context).size;
    final maxRadius = size.longestSide * 1.2;

    // === FIX: BACKGROUND SELALU BIRU ===
    final Color bgColor = const Color(0xFF57A0D3);

    // teks tetap putih
    final Color titleColor = Colors.white;

    // warna lingkaran mengikuti tema
    final Color circleColor =
        isDark ? theme.colorScheme.surface : Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      body: AnimatedBuilder(
        animation: _animation,
        builder: (_, __) {
          final radius = _animation.value * maxRadius;
          final center = Offset(size.width / 2, size.height / 2);

          return Stack(
            fit: StackFit.expand,
            children: [
              // BACKGROUND + LOGO
              Container(
                color: bgColor,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        "assets/kasir.png",
                        width: 120,
                        height: 120,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Kasir Pintar",
                        style: TextStyle(
                          color: titleColor,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // LINGKARAN (dark = hitam, light = putih)
              CustomPaint(
                painter: _WhiteCirclePainter(
                  center: center,
                  radius: radius,
                  color: circleColor,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _WhiteCirclePainter extends CustomPainter {
  final Offset center;
  final double radius;
  final Color color;

  _WhiteCirclePainter({
    required this.center,
    required this.radius,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(_WhiteCirclePainter oldDelegate) =>
      oldDelegate.radius != radius || oldDelegate.color != color;
}
