import 'package:flutter/material.dart';

class OnboardingPage extends StatefulWidget {
  /// Dipanggil otomatis setelah animasi selesai (untuk pindah ke LoginPage)
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

    // ⏱️ DURASI ANIMASI LINGKARAN PUTIH
    // UBAH DI SINI KALAU MAU CEPAT / LAMBAT (sekarang 4 detik = 4000 ms)
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );

    // ⏸ JEDA 2 DETIK: background biru DIAM dulu
    Future.delayed(const Duration(seconds: 2), () async {
      await _controller.forward();
      if (mounted) {
        widget.onContinue(); // setelah animasi selesai -> ke LoginPage
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
    final size = MediaQuery.of(context).size;
    final maxRadius = size.longestSide * 1.2;

    return Scaffold(
      // warna di belakang semuanya (akan terlihat ketika lingkaran putih sudah penuh)
      backgroundColor: Colors.white,
      body: AnimatedBuilder(
        animation: _animation,
        builder: (_, __) {
          // 🎯 LINGKARAN PUTIH DARI DALAM ➜ MEMBESAR KE LUAR
          final radius = _animation.value * maxRadius;
          final center = Offset(size.width / 2, size.height / 2);

          return Stack(
            fit: StackFit.expand,
            children: [
              // LAYER 1: background biru + logo (diam)
              Container(
                color: const Color(0xFF57A0D3),
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
                      const Text(
                        "Kasir Pintar",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // LAYER 2: lingkaran putih yang MEMBESAR dari tengah
              CustomPaint(
                painter: _WhiteCirclePainter(center: center, radius: radius),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Painter untuk lingkaran putih membesar
class _WhiteCirclePainter extends CustomPainter {
  final Offset center;
  final double radius;

  _WhiteCirclePainter({required this.center, required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(_WhiteCirclePainter oldDelegate) =>
      oldDelegate.radius != radius;
}
