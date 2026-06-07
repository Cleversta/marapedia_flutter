import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_state.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {

  late AnimationController _entryCtrl;
  late AnimationController _pulseCtrl;
  late AnimationController _dotsCtrl;

  late Animation<double> _logoFade;
  late Animation<double> _logoScale;
  late Animation<double> _textFade;
  late Animation<Offset> _textSlide;
  late Animation<double> _dividerFade;
  late Animation<double> _pulse;

  int _activeDot = 0;

  @override
  void initState() {
    super.initState();

    // Entry: staggered but simple — logo first, text second
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _logoFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entryCtrl,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );
    _logoScale = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryCtrl,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutBack),
      ),
    );
    _dividerFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entryCtrl,
        curve: const Interval(0.4, 0.7, curve: Curves.easeOut),
      ),
    );
    _textFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entryCtrl,
        curve: const Interval(0.45, 0.9, curve: Curves.easeOut),
      ),
    );
    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.18),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entryCtrl,
        curve: const Interval(0.45, 0.9, curve: Curves.easeOutCubic),
      ),
    );

    // Subtle ambient pulse on logo glow
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _pulse = CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut);

    // Dots
    _dotsCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..addListener(() {
        final dot = (_dotsCtrl.value * 3).floor().clamp(0, 2);
        if (dot != _activeDot) setState(() => _activeDot = dot);
      });

    _entryCtrl.forward().then((_) => _dotsCtrl.repeat());
    _navigate();
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _pulseCtrl.dispose();
    _dotsCtrl.dispose();
    super.dispose();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      context.go('/home');
    } else {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F3EC),
      body: Stack(
        children: [

          // ── Subtle warm radial wash behind everything ──────────────────
          Positioned.fill(
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 0.85,
                  colors: [
                    Color(0xFFEFE7D5),
                    Color(0xFFF7F3EC),
                  ],
                ),
              ),
            ),
          ),

          // ── Main centered content ──────────────────────────────────────
          Center(
            child: AnimatedBuilder(
              animation: _entryCtrl,
              builder: (_, __) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [

                  // Logo with soft glow ring
                  AnimatedBuilder(
                    animation: _pulse,
                    builder: (_, child) => Container(
                      width: 108,
                      height: 108,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF5A7A5C)
                                .withOpacity(0.10 + _pulse.value * 0.08),
                            blurRadius: 28 + _pulse.value * 16,
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: child,
                    ),
                    child: FadeTransition(
                      opacity: _logoFade,
                      child: ScaleTransition(
                        scale: _logoScale,
                        child: Image.asset('assets/logo.png', width: 108),
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Thin divider line with centre dot
                  FadeTransition(
                    opacity: _dividerFade,
                    child: const _OrnamentLine(),
                  ),

                  const SizedBox(height: 22),

                  // Title
                  FadeTransition(
                    opacity: _textFade,
                    child: SlideTransition(
                      position: _textSlide,
                      child: const Text(
                        'MARAPEDIA',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 6,
                          color: Color(0xFF1C1812),
                          height: 1,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Tagline
                  FadeTransition(
                    opacity: _textFade,
                    child: SlideTransition(
                      position: _textSlide,
                      child: const Text(
                        'THE FREE MARA ENCYCLOPEDIA',
                        style: TextStyle(
                          fontSize: 10,
                          letterSpacing: 3,
                          color: Color(0xFF8C7E6A),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 22),

                  // Bottom ornament line
                  FadeTransition(
                    opacity: _dividerFade,
                    child: const _OrnamentLine(),
                  ),
                ],
              ),
            ),
          ),

          // ── Bottom dots ────────────────────────────────────────────────
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 44),
              child: AnimatedBuilder(
                animation: _entryCtrl,
                builder: (_, __) => Opacity(
                  opacity: _textFade.value,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (i) {
                      final active = i == _activeDot;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 280),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: active ? 18 : 5,
                        height: 5,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(3),
                          color: active
                              ? const Color(0xFF5A7A5C)
                              : const Color(0xFFCCBFA8),
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Ornament line: thin rule + small centre diamond ───────────────────────────

class _OrnamentLine extends StatelessWidget {
  const _OrnamentLine();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      height: 10,
      child: CustomPaint(painter: _OrnamentLinePainter()),
    );
  }
}

class _OrnamentLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = const Color(0xFFCCBFA8)
      ..strokeWidth = 0.8;

    final diamondPaint = Paint()
      ..color = const Color(0xFF8C7E6A)
      ..style = PaintingStyle.fill;

    final cy = size.height / 2;
    const gap = 10.0;
    const d = 3.5;

    // Lines
    canvas.drawLine(Offset(0, cy), Offset(size.width / 2 - gap, cy), linePaint);
    canvas.drawLine(Offset(size.width / 2 + gap, cy), Offset(size.width, cy), linePaint);

    // Diamond
    final cx = size.width / 2;
    final path = Path()
      ..moveTo(cx, cy - d)
      ..lineTo(cx + d, cy)
      ..lineTo(cx, cy + d)
      ..lineTo(cx - d, cy)
      ..close();
    canvas.drawPath(path, diamondPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}