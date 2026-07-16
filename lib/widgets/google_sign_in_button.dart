import 'package:flutter/material.dart';

class GoogleSignInButton extends StatelessWidget {
  final VoidCallback? onPressed;
  const GoogleSignInButton({super.key, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 46,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF4285F4),
          foregroundColor: Colors.white,
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _googleIcon(),
            const SizedBox(width: 10),
            const Text(
              'Continue with Google',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  // Same 4-arc "G" shape as before, just recolored to white so it reads
  // cleanly against the solid blue background (matches the web version).
  Widget _googleIcon() {
    return const SizedBox(
      width: 18,
      height: 18,
      child: Stack(children: [
        _Arc(color: Colors.white, start: 0.5, sweep: 1.5),
        _Arc(color: Colors.white, start: -0.5, sweep: 0.75),
        _Arc(color: Colors.white, start: 0.25, sweep: 0.5),
        _Arc(color: Colors.white, start: 0.75, sweep: 0.5),
      ]),
    );
  }
}

class _Arc extends StatelessWidget {
  final Color color;
  final double start;
  final double sweep;
  const _Arc({required this.color, required this.start, required this.sweep});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _ArcPainter(color: color, start: start * 3.14159 * 2, sweep: sweep * 3.14159 * 2),
    );
  }
}

class _ArcPainter extends CustomPainter {
  final Color color;
  final double start;
  final double sweep;
  const _ArcPainter({required this.color, required this.start, required this.sweep});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = size.width * 0.22
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.butt;
    final inset = size.width * 0.11;
    canvas.drawArc(
      Rect.fromLTWH(inset, inset, size.width - inset * 2, size.height - inset * 2),
      start,
      sweep,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_) => false;
}