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
    with SingleTickerProviderStateMixin {
  late AnimationController _dotController;
  int _activeDot = 0;

  @override
  void initState() {
    super.initState();

    _dotController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..addListener(() {
        final dot = (_dotController.value * 3).floor().clamp(0, 2);
        if (dot != _activeDot) {
          setState(() => _activeDot = dot);
        }
      });

    _dotController.repeat();
    _navigate();
  }

  @override
  void dispose() {
    _dotController.dispose();
    super.dispose();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(seconds: 3));
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
      backgroundColor: const Color(0xFFFEFEFE),
      body: Stack(
        children: [
          // ── Centered logo ──────────────────────────────────────────
          Center(
            child: Image.asset('assets/logo.png', width: 160),
          ),

          // ── Bottom: dots + tagline ─────────────────────────────────
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Animated dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (i) {
                      final isActive = i == _activeDot;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: isActive ? 8 : 6,
                        height: isActive ? 8 : 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isActive
                              ? const Color(0xFF3A3A2A)
                              : const Color(0xFFCCCCCC),
                        ),
                      );
                    }),
                  ),

                  const SizedBox(height: 16),

                  // Tagline
                  const Text(
                    'THE FREE MARA ENCYCLOPEDIA',
                    style: TextStyle(
                      fontSize: 11,
                      letterSpacing: 2.0,
                      color: Color(0xFF3A3A2A),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}