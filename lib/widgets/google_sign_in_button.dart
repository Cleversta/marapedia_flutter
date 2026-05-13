import 'package:flutter/material.dart';

class GoogleSignInButton extends StatelessWidget {
  final VoidCallback? onPressed;
  const GoogleSignInButton({super.key, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 46,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFFD1D5DB)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          backgroundColor: Colors.white,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _googleIcon(),
            const SizedBox(width: 10),
            const Text(
              'Continue with Google',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF374151)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _googleIcon() {
    return SizedBox(
      width: 18,
      height: 18,
      child: Stack(children: [
        // Blue arc (left + bottom)
        _Arc(color: const Color(0xFF4285F4), start: 0.5, sweep: 1.5),
        // Red arc (top-right)
        _Arc(color: const Color(0xFFEA4335), start: -0.5, sweep: 0.75),
        // Yellow arc (bottom-right)
        _Arc(color: const Color(0xFFFBBC05), start: 0.25, sweep: 0.5),
        // Green arc (bottom-left)
        _Arc(color: const Color(0xFF34A853), start: 0.75, sweep: 0.5),
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
