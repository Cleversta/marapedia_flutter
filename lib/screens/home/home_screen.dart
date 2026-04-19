import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../blocs/article/article_bloc.dart';
import '../../blocs/article/article_event.dart';
import '../../blocs/article/article_state.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_state.dart';
import '../../models/article_model.dart';
import '../../utils/helpers.dart';
import '../../widgets/article_card.dart';
import '../../widgets/category_tabs.dart';
import '../../widgets/offline_banner.dart';
import '../../widgets/shimmer_card.dart';
import '../../widgets/marapedia_app_bar.dart';

const _parchment   = Color(0xFFF7F3EC);
const _parchmentDk = Color(0xFFEDE5D4);
const _border      = Color(0xFFDDD4C0);
const _ink         = Color(0xFF1C1812);
const _inkMid      = Color(0xFF4A4035);
const _inkLight    = Color(0xFF8C7E6A);
const _sage        = Color(0xFF5A7A5C);
const _sageBg      = Color(0xFFEBF1EB);
const _sageLight   = Color(0xFFD4E4D4);

// ═══════════════════════════════════════════════════════════════════════════════
// HOLIDAY SYSTEM
// ═══════════════════════════════════════════════════════════════════════════════

enum _HolidayTheme {
  christmas,
  newYear,
  epiphany,
  allSaints,
  advent,
  lorrainDay,
  ashWednesday,
  palmSunday,
  goodFriday,
  easter,
  ascension,
  pentecost,
  default_,
}

DateTime _computeEaster(int year) {
  final a = year % 19;
  final b = year ~/ 100;
  final c = year % 100;
  final d = b ~/ 4;
  final e = b % 4;
  final f = (b + 8) ~/ 25;
  final g = (b - f + 1) ~/ 3;
  final h = (19 * a + b - d - g + 15) % 30;
  final i = c ~/ 4;
  final k = c % 4;
  final l = (32 + 2 * e + 2 * i - h - k) % 7;
  final m = (a + 11 * h + 22 * l) ~/ 451;
  final month = (h + l - 7 * m + 114) ~/ 31;
  final day   = ((h + l - 7 * m + 114) % 31) + 1;
  return DateTime(year, month, day);
}

_HolidayTheme _getHolidayTheme() {
  final now   = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final mo    = now.month;
  final dy    = now.day;

  if (mo == 9  && dy == 26)             return _HolidayTheme.lorrainDay;
  if (mo == 11 && dy == 1)              return _HolidayTheme.allSaints;
  if (mo == 12 && dy >= 1 && dy <= 19)  return _HolidayTheme.advent;
  if (mo == 12 && dy >= 20)             return _HolidayTheme.christmas;
  if (mo == 1  && dy <= 5)              return _HolidayTheme.newYear;
  if (mo == 1  && dy == 6)              return _HolidayTheme.epiphany;

  final easter  = _computeEaster(now.year);
  final easterD = DateTime(easter.year, easter.month, easter.day);
  final ashWed  = easterD.subtract(const Duration(days: 46));
  final diff    = today.difference(easterD).inDays;

  if (today == ashWed)             return _HolidayTheme.ashWednesday;
  if (diff == -7)                  return _HolidayTheme.palmSunday;
  if (diff == -2)                  return _HolidayTheme.goodFriday;
  if (diff == 0 || diff == 1)      return _HolidayTheme.easter;
  if (diff == 39)                  return _HolidayTheme.ascension;
  if (diff == 49 || diff == 50)    return _HolidayTheme.pentecost;

  return _HolidayTheme.default_;
}

({Color heroBg, Color heroBorder, String label}) _holidayConfig(
    _HolidayTheme theme) {
  return switch (theme) {
    _HolidayTheme.christmas => (
      heroBg:     const Color(0xFF1A3A2A),
      heroBorder: const Color(0xFF2D6645),
      label: '🎄 MERRY CHRISTMAS · THE FREE MARA ENCYCLOPEDIA',
    ),
    _HolidayTheme.newYear => (
      heroBg:     const Color(0xFF0D0D2B),
      heroBorder: const Color(0xFF2A2A60),
      label: '🎆 HAPPY NEW YEAR · THE FREE MARA ENCYCLOPEDIA',
    ),
    _HolidayTheme.epiphany => (
      heroBg:     const Color(0xFF1C0A38),
      heroBorder: const Color(0xFF3A1A60),
      label: '✨ FEAST OF EPIPHANY · THE FREE MARA ENCYCLOPEDIA',
    ),
    _HolidayTheme.ashWednesday => (
      heroBg:     const Color(0xFF1A1A1A),
      heroBorder: const Color(0xFF333333),
      label: '✝ ASH WEDNESDAY · THE FREE MARA ENCYCLOPEDIA',
    ),
    _HolidayTheme.palmSunday => (
      heroBg:     const Color(0xFF1A2E0A),
      heroBorder: const Color(0xFF2D5010),
      label: '🌿 PALM SUNDAY · THE FREE MARA ENCYCLOPEDIA',
    ),
    _HolidayTheme.goodFriday => (
      heroBg:     const Color(0xFF200808),
      heroBorder: const Color(0xFF4A1010),
      label: '✝ GOOD FRIDAY · THE FREE MARA ENCYCLOPEDIA',
    ),
    _HolidayTheme.easter => (
      heroBg:     const Color(0xFF2A1800),
      heroBorder: const Color(0xFF5A3800),
      label: '✝ HAPPY EASTER · THE FREE MARA ENCYCLOPEDIA',
    ),
    _HolidayTheme.ascension => (
      heroBg:     const Color(0xFF061828),
      heroBorder: const Color(0xFF0C3050),
      label: '☁ ASCENSION DAY · THE FREE MARA ENCYCLOPEDIA',
    ),
    _HolidayTheme.pentecost => (
      heroBg:     const Color(0xFF2A0808),
      heroBorder: const Color(0xFF601010),
      label: '🔥 PENTECOST SUNDAY · THE FREE MARA ENCYCLOPEDIA',
    ),
    _HolidayTheme.allSaints => (
      heroBg:     const Color(0xFF180820),
      heroBorder: const Color(0xFF3A1050),
      label: '✦ ALL SAINTS DAY · THE FREE MARA ENCYCLOPEDIA',
    ),
    _HolidayTheme.advent => (
      heroBg:     const Color(0xFF16101E),
      heroBorder: const Color(0xFF2E1E44),
      label: '🕯 ADVENT SEASON · THE FREE MARA ENCYCLOPEDIA',
    ),
    _HolidayTheme.lorrainDay => (
      heroBg:     const Color(0xFF0F2218),
      heroBorder: const Color(0xFF1E4430),
      label: '📖 R.A. LORRAIN DAY · THE FREE MARA ENCYCLOPEDIA',
    ),
    _HolidayTheme.default_ => (
      heroBg:     _parchmentDk,
      heroBorder: _border,
      label: 'THE FREE MARA ENCYCLOPEDIA',
    ),
  };
}

// ═══════════════════════════════════════════════════════════════════════════════
// PAINTERS
// ═══════════════════════════════════════════════════════════════════════════════

class _HolidayPainter extends CustomPainter {
  final _HolidayTheme theme;
  const _HolidayPainter(this.theme);
  @override
  void paint(Canvas canvas, Size size) {
    switch (theme) {
      case _HolidayTheme.christmas:    _ChristmasPainter().paint(canvas, size);
      case _HolidayTheme.newYear:      _NewYearPainter().paint(canvas, size);
      case _HolidayTheme.epiphany:     _EpiphanyPainter().paint(canvas, size);
      case _HolidayTheme.ashWednesday: _AshWednesdayPainter().paint(canvas, size);
      case _HolidayTheme.palmSunday:   _PalmSundayPainter().paint(canvas, size);
      case _HolidayTheme.goodFriday:   _GoodFridayPainter().paint(canvas, size);
      case _HolidayTheme.easter:       _EasterPainter().paint(canvas, size);
      case _HolidayTheme.ascension:    _AscensionPainter().paint(canvas, size);
      case _HolidayTheme.pentecost:    _PentecostPainter().paint(canvas, size);
      case _HolidayTheme.allSaints:    _AllSaintsPainter().paint(canvas, size);
      case _HolidayTheme.advent:       _AdventPainter().paint(canvas, size);
      case _HolidayTheme.lorrainDay:   _LorrainDayPainter().paint(canvas, size);
      case _HolidayTheme.default_:     _PatternPainter().paint(canvas, size);
    }
  }
  @override bool shouldRepaint(covariant CustomPainter old) => false;
}

class _ChristmasPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final dot  = Paint()..color = Colors.white.withOpacity(0.18)..style = PaintingStyle.fill;
    final line = Paint()..color = Colors.white.withOpacity(0.12)..strokeWidth = 0.8..style = PaintingStyle.stroke;
    const flakes = [
      (0.10,0.08,4.0),(0.28,0.20,3.0),(0.52,0.06,5.0),(0.74,0.18,3.5),
      (0.91,0.04,4.0),(0.18,0.45,2.5),(0.63,0.40,3.0),(0.84,0.50,4.5),
      (0.38,0.65,2.0),(0.04,0.70,3.5),(0.94,0.76,2.5),(0.50,0.86,4.0),
    ];
    for (final (rx, ry, r) in flakes) {
      final cx = size.width * rx; final cy = size.height * ry;
      canvas.drawCircle(Offset(cx, cy), r * 0.5, dot);
      for (int i = 0; i < 6; i++) {
        final a = i * math.pi / 3;
        canvas.drawLine(Offset(cx, cy), Offset(cx + r * 2.2 * math.cos(a), cy + r * 2.2 * math.sin(a)), line);
      }
    }
    final treePaint = Paint()..color = Colors.white.withOpacity(0.05)..style = PaintingStyle.fill;
    canvas.drawPath(
      Path()..moveTo(size.width*.88,size.height*.44)..lineTo(size.width*.78,size.height)..lineTo(size.width*.98,size.height)..close(),
      treePaint,
    );
    canvas.drawCircle(Offset(size.width*.88, size.height*.41), 4,
        Paint()..color = const Color(0xFFFFD700).withOpacity(0.28)..style = PaintingStyle.fill);
  }
  @override bool shouldRepaint(covariant CustomPainter old) => false;
}

class _NewYearPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final gold   = Paint()..color = const Color(0xFFFFD700).withOpacity(0.20)..style = PaintingStyle.fill;
    final silver = Paint()..color = Colors.white.withOpacity(0.14)..style = PaintingStyle.fill;
    const dots = [
      (0.10,0.15,3.0,true),(0.25,0.08,2.0,false),(0.45,0.12,4.0,true),(0.70,0.05,2.5,false),
      (0.88,0.18,3.0,true),(0.05,0.40,2.0,false),(0.35,0.35,3.5,true),(0.60,0.30,2.0,false),
      (0.80,0.42,4.0,true),(0.15,0.65,3.0,false),(0.50,0.60,2.5,true),(0.90,0.55,3.5,false),
      (0.30,0.82,2.0,true),(0.72,0.78,3.0,false),(0.92,0.88,2.5,true),
    ];
    for (final (rx, ry, r, isGold) in dots) {
      canvas.drawCircle(Offset(size.width*rx, size.height*ry), r, isGold ? gold : silver);
    }
    final spark = Paint()..color = const Color(0xFFFFD700).withOpacity(0.18)..style = PaintingStyle.stroke..strokeWidth = 0.8;
    for (final (rx, ry, r) in [(0.20,0.28,9.0),(0.60,0.14,7.0),(0.85,0.68,10.0),(0.40,0.84,7.0),(0.08,0.55,8.0)]) {
      final cx = size.width*rx; final cy = size.height*ry; final d = r*0.5;
      canvas.drawLine(Offset(cx,cy-r),Offset(cx,cy+r),spark);
      canvas.drawLine(Offset(cx-r,cy),Offset(cx+r,cy),spark);
      canvas.drawLine(Offset(cx-d,cy-d),Offset(cx+d,cy+d),spark);
      canvas.drawLine(Offset(cx+d,cy-d),Offset(cx-d,cy+d),spark);
    }
  }
  @override bool shouldRepaint(covariant CustomPainter old) => false;
}

class _EpiphanyPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final gold = Paint()..color = const Color(0xFFFFD700).withOpacity(0.22)..style = PaintingStyle.fill;
    final line = Paint()..color = const Color(0xFFFFD700).withOpacity(0.15)..style = PaintingStyle.stroke..strokeWidth = 0.8;
    final cx = size.width*0.5; final cy = size.height*0.08;
    for (int i = 0; i < 8; i++) {
      final a = i * math.pi / 4;
      canvas.drawLine(Offset(cx,cy), Offset(cx+18*math.cos(a), cy+18*math.sin(a)),
          Paint()..color=const Color(0xFFFFD700).withOpacity(0.28)..strokeWidth=1.2..style=PaintingStyle.stroke);
    }
    canvas.drawCircle(Offset(cx,cy), 5, gold);
    const stars = [(0.08,0.12,6.0),(0.88,0.10,5.0),(0.20,0.30,4.0),(0.75,0.25,5.0),
      (0.05,0.55,4.0),(0.92,0.50,4.0),(0.30,0.70,3.0),(0.70,0.75,3.5),(0.50,0.85,4.0)];
    for (final (rx, ry, r) in stars) {
      final sx = size.width*rx; final sy = size.height*ry;
      for (int i = 0; i < 4; i++) {
        final a = i*math.pi/2;
        canvas.drawLine(Offset(sx,sy), Offset(sx+r*math.cos(a), sy+r*math.sin(a)), line);
      }
      canvas.drawCircle(Offset(sx,sy), r*0.35, gold);
    }
  }
  @override bool shouldRepaint(covariant CustomPainter old) => false;
}

class _AshWednesdayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final ash  = Paint()..color = Colors.white.withOpacity(0.06)..style = PaintingStyle.fill;
    final line = Paint()..color = Colors.white.withOpacity(0.07)..style = PaintingStyle.stroke..strokeWidth = 0.8;
    const dots = [(0.15,0.20),(0.40,0.10),(0.65,0.18),(0.85,0.08),(0.08,0.45),
      (0.55,0.40),(0.80,0.50),(0.25,0.65),(0.70,0.70),(0.45,0.85),(0.90,0.80)];
    for (final (rx, ry) in dots) {
      canvas.drawCircle(Offset(size.width*rx, size.height*ry), 2.5, ash);
    }
    const crosses = [(0.20,0.35,10.0),(0.75,0.30,8.0),(0.50,0.60,9.0),(0.15,0.75,7.0),(0.85,0.65,8.0)];
    for (final (rx, ry, r) in crosses) {
      final cx = size.width*rx; final cy = size.height*ry;
      canvas.drawLine(Offset(cx,cy-r),Offset(cx,cy+r),line);
      canvas.drawLine(Offset(cx-r*0.65,cy-r*0.2),Offset(cx+r*0.65,cy-r*0.2),line);
    }
  }
  @override bool shouldRepaint(covariant CustomPainter old) => false;
}

class _PalmSundayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final leaf = Paint()..color = Colors.white.withOpacity(0.06)..style = PaintingStyle.fill;
    final vein = Paint()..color = Colors.white.withOpacity(0.08)..style = PaintingStyle.stroke..strokeWidth = 0.7;
    void drawFrond(double cx, double cy, double len, double angle) {
      final ex = cx + len*math.cos(angle); final ey = cy + len*math.sin(angle);
      final mx = cx + len*0.5*math.cos(angle-0.3); final my = cy + len*0.5*math.sin(angle-0.3);
      final p = Path()..moveTo(cx,cy)..quadraticBezierTo(mx,my,ex,ey)
        ..lineTo(cx+4*math.cos(angle+math.pi*0.5), cy+4*math.sin(angle+math.pi*0.5))..close();
      canvas.drawPath(p, leaf);
      canvas.drawLine(Offset(cx,cy), Offset(ex,ey), vein);
    }
    drawFrond(size.width*.85,size.height*.90,70,-math.pi*0.60);
    drawFrond(size.width*.85,size.height*.90,60,-math.pi*0.75);
    drawFrond(size.width*.85,size.height*.90,55,-math.pi*0.45);
    drawFrond(size.width*.10,size.height*.85,65,-math.pi*0.35);
    drawFrond(size.width*.10,size.height*.85,58,-math.pi*0.20);
    final dot = Paint()..color = Colors.white.withOpacity(0.08)..style = PaintingStyle.fill;
    for (final (rx, ry) in [(0.20,0.15),(0.50,0.08),(0.70,0.20),(0.30,0.40),(0.65,0.50),(0.15,0.60)]) {
      canvas.drawOval(Rect.fromCenter(center:Offset(size.width*rx,size.height*ry), width:8, height:4), dot);
    }
  }
  @override bool shouldRepaint(covariant CustomPainter old) => false;
}

class _GoodFridayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cross = Paint()..color = Colors.white.withOpacity(0.04)..style = PaintingStyle.stroke..strokeWidth = 18..strokeCap = StrokeCap.round;
    final cx = size.width*0.5; final cy = size.height*0.45;
    canvas.drawLine(Offset(cx,size.height*.10),Offset(cx,size.height*.85),cross);
    canvas.drawLine(Offset(size.width*.25,cy),Offset(size.width*.75,cy),cross);
    final dot = Paint()..color = Colors.red.withOpacity(0.06)..style = PaintingStyle.fill;
    for (final (rx,ry,r) in [(0.10,0.15,3.0),(0.30,0.08,2.0),(0.70,0.12,2.5),(0.90,0.20,2.0),
      (0.05,0.50,2.0),(0.95,0.55,2.5),(0.20,0.80,2.0),(0.80,0.85,2.5)]) {
      canvas.drawCircle(Offset(size.width*rx,size.height*ry), r, dot);
    }
  }
  @override bool shouldRepaint(covariant CustomPainter old) => false;
}

class _EasterPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final ray = Paint()..color = const Color(0xFFFFD700).withOpacity(0.10)..style = PaintingStyle.stroke..strokeWidth = 1.2;
    final dot = Paint()..color = const Color(0xFFFFD700).withOpacity(0.18)..style = PaintingStyle.fill;
    final sx = size.width*0.5; final sy = -size.height*0.05;
    for (int i = 0; i < 12; i++) {
      final a = (i/12)*math.pi;
      canvas.drawLine(Offset(sx,sy), Offset(sx+size.width*.7*math.cos(a), sy+size.width*.7*math.sin(a)), ray);
    }
    canvas.drawCircle(Offset(sx,sy+8), 10,
        Paint()..color=const Color(0xFFFFD700).withOpacity(0.12)..style=PaintingStyle.fill);
    for (final (rx,ry,r) in [(0.10,0.30,3.0),(0.25,0.18,2.5),(0.45,0.22,4.0),(0.70,0.15,3.0),
      (0.88,0.28,2.5),(0.15,0.55,2.0),(0.60,0.50,3.5),(0.85,0.65,2.0),(0.35,0.72,2.5),(0.55,0.82,3.0)]) {
      canvas.drawCircle(Offset(size.width*rx,size.height*ry), r, dot);
    }
  }
  @override bool shouldRepaint(covariant CustomPainter old) => false;
}

class _AscensionPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final ray   = Paint()..color = Colors.white.withOpacity(0.06)..style = PaintingStyle.stroke..strokeWidth = 1;
    final cloud = Paint()..color = Colors.white.withOpacity(0.05)..style = PaintingStyle.fill;
    final dot   = Paint()..color = const Color(0xFF87CEEB).withOpacity(0.15)..style = PaintingStyle.fill;
    final bx = size.width*0.5;
    for (int i = 0; i < 9; i++) {
      final a = math.pi + (i-4)*0.18;
      canvas.drawLine(Offset(bx,size.height), Offset(bx+size.height*math.cos(a), size.height+size.height*math.sin(a)), ray);
    }
    void drawCloud(double cx, double cy) {
      canvas.drawCircle(Offset(cx,cy), 14, cloud);
      canvas.drawCircle(Offset(cx-12,cy+4), 10, cloud);
      canvas.drawCircle(Offset(cx+12,cy+4), 10, cloud);
    }
    drawCloud(size.width*.25, size.height*.15);
    drawCloud(size.width*.72, size.height*.10);
    drawCloud(size.width*.50, size.height*.05);
    for (final (rx,ry,r) in [(0.10,0.28,2.5),(0.40,0.18,3.0),(0.65,0.25,2.0),(0.88,0.35,2.5),
      (0.05,0.55,2.0),(0.82,0.58,2.0),(0.30,0.70,2.5),(0.60,0.75,2.0)]) {
      canvas.drawCircle(Offset(size.width*rx,size.height*ry), r, dot);
    }
  }
  @override bool shouldRepaint(covariant CustomPainter old) => false;
}

class _PentecostPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final flame = Paint()..color = const Color(0xFFFF4500).withOpacity(0.12)..style = PaintingStyle.fill;
    final ember = Paint()..color = const Color(0xFFFFD700).withOpacity(0.16)..style = PaintingStyle.fill;
    void drawFlame(double cx, double cy, double h) {
      final p = Path();
      p.moveTo(cx, cy+h*0.5);
      p.cubicTo(cx-h*0.3,cy, cx-h*0.2,cy-h*0.5, cx,cy-h);
      p.cubicTo(cx+h*0.2,cy-h*0.5, cx+h*0.3,cy, cx,cy+h*0.5);
      canvas.drawPath(p, flame);
    }
    drawFlame(size.width*.20,size.height*.50,40);
    drawFlame(size.width*.40,size.height*.45,50);
    drawFlame(size.width*.60,size.height*.48,44);
    drawFlame(size.width*.80,size.height*.52,38);
    drawFlame(size.width*.05,size.height*.60,30);
    drawFlame(size.width*.92,size.height*.55,32);
    for (final (rx,ry,r) in [(0.15,0.25,3.0),(0.35,0.18,2.5),(0.55,0.22,3.5),(0.72,0.15,2.5),
      (0.88,0.30,2.0),(0.28,0.55,2.0),(0.65,0.60,2.5),(0.48,0.72,2.0),(0.82,0.75,2.0)]) {
      canvas.drawCircle(Offset(size.width*rx,size.height*ry), r, ember);
    }
  }
  @override bool shouldRepaint(covariant CustomPainter old) => false;
}

class _AllSaintsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final ring = Paint()..color = const Color(0xFFFFD700).withOpacity(0.10)..style = PaintingStyle.stroke..strokeWidth = 1;
    final dot  = Paint()..color = Colors.white.withOpacity(0.10)..style = PaintingStyle.fill;
    for (final (rx,ry,r) in [(0.20,0.20,16.0),(0.70,0.15,14.0),(0.85,0.55,12.0),(0.15,0.65,13.0),(0.50,0.80,15.0)]) {
      canvas.drawCircle(Offset(size.width*rx,size.height*ry), r, ring);
      canvas.drawCircle(Offset(size.width*rx,size.height*ry), r*0.4, dot);
    }
    for (final (rx,ry,r) in [(0.35,0.10,2.0),(0.55,0.08,2.5),(0.90,0.30,2.0),(0.08,0.40,2.0),
      (0.45,0.45,2.5),(0.75,0.40,2.0),(0.30,0.75,2.0),(0.65,0.70,2.5),(0.92,0.80,2.0)]) {
      canvas.drawCircle(Offset(size.width*rx,size.height*ry), r, dot);
    }
  }
  @override bool shouldRepaint(covariant CustomPainter old) => false;
}

class _AdventPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final purple = Paint()..color = const Color(0xFF9B59B6).withOpacity(0.12)..style = PaintingStyle.fill;
    final gold   = Paint()..color = const Color(0xFFFFD700).withOpacity(0.18)..style = PaintingStyle.fill;
    final glow   = Paint()..color = const Color(0xFFFFD700).withOpacity(0.10)..style = PaintingStyle.fill;
    for (final (rx, ry) in [(0.20,0.70),(0.38,0.68),(0.56,0.70),(0.74,0.68)]) {
      final cx = size.width*rx; final cy = size.height*ry;
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center:Offset(cx,cy),width:10,height:30),const Radius.circular(2)),purple);
      final fp = Path()..moveTo(cx,cy-15)..cubicTo(cx-5,cy-20,cx-3,cy-28,cx,cy-32)..cubicTo(cx+3,cy-28,cx+5,cy-20,cx,cy-15);
      canvas.drawPath(fp, gold);
      canvas.drawCircle(Offset(cx,cy-22), 5, glow);
    }
    final star = Paint()..color = Colors.white.withOpacity(0.10)..style = PaintingStyle.fill;
    for (final (rx,ry,r) in [(0.08,0.12,2.5),(0.30,0.08,2.0),(0.55,0.10,3.0),(0.80,0.06,2.5),(0.95,0.20,2.0),
      (0.10,0.40,2.0),(0.65,0.35,2.5),(0.90,0.55,2.0),(0.25,0.85,2.0),(0.85,0.85,2.5)]) {
      canvas.drawCircle(Offset(size.width*rx,size.height*ry), r, star);
    }
  }
  @override bool shouldRepaint(covariant CustomPainter old) => false;
}

class _LorrainDayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final ivory = Paint()..color = Colors.white.withOpacity(0.06)..style = PaintingStyle.fill;
    final line  = Paint()..color = Colors.white.withOpacity(0.08)..style = PaintingStyle.stroke..strokeWidth = 0.8;
    final gold  = Paint()..color = const Color(0xFFFFD700).withOpacity(0.14)..style = PaintingStyle.fill;
    final bx = size.width*.80; final by = size.height*.78;
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(bx-32,by-20,30,28),const Radius.circular(2)),ivory);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(bx+2,by-20,30,28),const Radius.circular(2)),ivory);
    canvas.drawLine(Offset(bx,by-20),Offset(bx,by+8),line);
    for (int i = 0; i < 3; i++) {
      canvas.drawLine(Offset(bx-28,by-12+i*7.0),Offset(bx-6,by-12+i*7.0),line);
      canvas.drawLine(Offset(bx+6,by-12+i*7.0),Offset(bx+28,by-12+i*7.0),line);
    }
    final crossP = Paint()..color=Colors.white.withOpacity(0.07)..style=PaintingStyle.stroke..strokeWidth=8..strokeCap=StrokeCap.round;
    canvas.drawLine(Offset(size.width*.15,size.height*.08),Offset(size.width*.15,size.height*.30),crossP);
    canvas.drawLine(Offset(size.width*.08,size.height*.16),Offset(size.width*.22,size.height*.16),crossP);
    for (final (rx,ry,r) in [(0.40,0.10,2.5),(0.60,0.08,3.0),(0.85,0.15,2.0),(0.05,0.40,2.5),
      (0.50,0.45,2.0),(0.92,0.45,2.5),(0.30,0.60,2.0),(0.70,0.58,2.5),
      (0.10,0.80,2.0),(0.55,0.85,3.0),(0.88,0.90,2.0)]) {
      canvas.drawCircle(Offset(size.width*rx,size.height*ry), r, gold);
    }
  }
  @override bool shouldRepaint(covariant CustomPainter old) => false;
}

class _PatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFF8C7E6A).withOpacity(0.06)..style = PaintingStyle.stroke..strokeWidth = 1;
    for (double i = -size.height; i < size.width+size.height; i += 26) {
      canvas.drawLine(Offset(i,0), Offset(i+size.height,size.height), paint);
    }
    final accent = Paint()..color=const Color(0xFF8C7E6A).withOpacity(0.07)..style=PaintingStyle.stroke..strokeWidth=1;
    for (int r = 1; r <= 4; r++) {
      canvas.drawCircle(Offset(size.width,0), r*30.0, accent);
    }
  }
  @override bool shouldRepaint(covariant CustomPainter old) => false;
}

// ═══════════════════════════════════════════════════════════════════════════════
// SCREEN
// ═══════════════════════════════════════════════════════════════════════════════

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  String? _selectedCategory;
  late AnimationController _heroCtrl;
  late Animation<double>   _heroFade;
  late Animation<Offset>   _heroSlide;

  @override
  void initState() {
    super.initState();
    _heroCtrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _heroFade  = CurvedAnimation(parent: _heroCtrl, curve: Curves.easeOut);
    _heroSlide = Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero)
        .animate(CurvedAnimation(parent: _heroCtrl, curve: Curves.easeOut));
  }

  @override
  void dispose() { _heroCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _parchment,
      appBar: const MarapediaAppBar(),
      body: Column(
        children: [
          BlocBuilder<ArticleBloc, ArticleState>(
            builder: (context, state) {
              final counts = state is ArticleHomeLoaded
                  ? state.categoryCounts
                  : <String, int>{};
              return CategoryTabs(
                selected: _selectedCategory,
                counts: counts,
                onTap: (cat) {
                  if (cat == 'photos') { context.push('/photos'); return; }
                  setState(() => _selectedCategory = cat);
                  context.push('/category/$cat');
                },
              );
            },
          ),
          Expanded(
            child: BlocConsumer<ArticleBloc, ArticleState>(
              listener: (context, state) {
                if (state is ArticleHomeLoaded) _heroCtrl.forward(from: 0);
              },
              builder: (context, state) {
                if (state is ArticleLoading) {
                  return ListView(padding: const EdgeInsets.all(16), children: const [ShimmerList(count: 4)]);
                }
                if (state is ArticleHomeLoaded) return _buildHome(context, state);
                if (state is ArticleError)      return _buildError(context, state.message);
                return ListView(padding: const EdgeInsets.all(16), children: const [ShimmerList(count: 4)]);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is AuthAuthenticated) {
            return FloatingActionButton.extended(
              onPressed: () => context.push('/articles/create'),
              backgroundColor: _sage, elevation: 2,
              icon: const Icon(Icons.edit_outlined, color: Colors.white, size: 18),
              label: Text('Contribute', style: GoogleFonts.lora(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildHome(BuildContext context, ArticleHomeLoaded state) {
    final nonFeaturedMostViewed =
        state.mostViewed.where((a) => a.id != state.featured?.id).toList();
    return Column(
      children: [
        if (state.isOffline) const OfflineBanner(),
        Expanded(
          child: RefreshIndicator(
            color: _sage,
            onRefresh: () async => context.read<ArticleBloc>().add(ArticleHomeLoadRequested()),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FadeTransition(
                    opacity: _heroFade,
                    child: SlideTransition(position: _heroSlide, child: _buildHero(context, state)),
                  ),
                  const SizedBox(height: 28),
                  if (state.featured != null) ...[
                    _sectionHeader('Featured Article', icon: '✦'),
                    const SizedBox(height: 12),
                    _buildFeatured(context, state),
                    const SizedBox(height: 28),
                  ],
                  _sectionHeader('Recent Articles', icon: '◈'),
                  const SizedBox(height: 12),
                  _buildArticleGrid(context, state.recent),
                  if (nonFeaturedMostViewed.isNotEmpty) ...[
                    const SizedBox(height: 28),
                    _sectionHeader('Most Viewed', icon: '◉'),
                    const SizedBox(height: 12),
                    _buildArticleGrid(context, nonFeaturedMostViewed),
                  ],
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHero(BuildContext context, ArticleHomeLoaded state) {
    final theme  = _getHolidayTheme();
    final cfg    = _holidayConfig(theme);
    final isDark = theme != _HolidayTheme.default_;

    final titleColor  = isDark ? Colors.white                    : _ink;
    final subColor    = isDark ? Colors.white70                  : _inkLight;
    final badgeBg     = isDark ? Colors.white.withOpacity(0.10)  : Colors.white.withOpacity(0.5);
    final badgeBorder = isDark ? Colors.white24                  : _border;
    final badgeText   = isDark ? Colors.white60                  : _inkLight;
    final pillBg      = isDark ? Colors.white.withOpacity(0.10)  : Colors.white.withOpacity(0.7);
    final pillBorder  = isDark ? Colors.white24                  : _border;
    final pillText    = isDark ? Colors.white70                  : _inkMid;
    final statBg      = isDark ? Colors.white.withOpacity(0.08)  : Colors.white.withOpacity(0.6);
    final statBorder  = isDark ? Colors.white24                  : _border;
    final statIcon    = isDark ? Colors.white54                  : _sage;
    final statValue   = isDark ? Colors.white                    : _ink;
    final statLabel   = isDark ? Colors.white54                  : _inkLight;
    final ctaBg       = isDark ? Colors.white.withOpacity(0.10)  : Colors.white.withOpacity(0.7);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      decoration: BoxDecoration(
        color: cfg.heroBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cfg.heroBorder),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0,3))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _HolidayPainter(theme))),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 26, 24, 22),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    border: Border.all(color: badgeBorder),
                    borderRadius: BorderRadius.circular(20),
                    color: badgeBg,
                  ),
                  child: Text(cfg.label,
                      style: GoogleFonts.lora(fontSize: 9, fontWeight: FontWeight.w600,
                          color: badgeText, letterSpacing: 1.6)),
                ),
                const SizedBox(height: 14),
                Text('Preserving Mara\nHistory & Culture',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.lora(fontSize: 26, fontWeight: FontWeight.w700,
                        color: titleColor, height: 1.25)),
                const SizedBox(height: 8),
                Text('A community-built encyclopedia for the Mara people.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: subColor, height: 1.5)),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 6, runSpacing: 6, alignment: WrapAlignment.center,
                  children: ['Mara','English','Myanmar','Mizo'].map((lang) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(color: pillBg,
                        border: Border.all(color: pillBorder), borderRadius: BorderRadius.circular(20)),
                    child: Text(lang, style: TextStyle(fontSize: 11, color: pillText, fontWeight: FontWeight.w500)),
                  )).toList(),
                ),
                const SizedBox(height: 18),
                Row(children: [
                  Expanded(child: _statCard('${state.articleCount}','Articles',Icons.article_outlined,
                      bg:statBg,border:statBorder,iconColor:statIcon,valueColor:statValue,labelColor:statLabel)),
                  const SizedBox(width: 8),
                  Expanded(child: _statCard('${state.userCount}','Contributors',Icons.people_outline,
                      bg:statBg,border:statBorder,iconColor:statIcon,valueColor:statValue,labelColor:statLabel)),
                  const SizedBox(width: 8),
                  Expanded(child: _statCard('4','Languages',Icons.translate,
                      bg:statBg,border:statBorder,iconColor:statIcon,valueColor:statValue,labelColor:statLabel)),
                ]),
                const SizedBox(height: 14),
                GestureDetector(
                  onTap: () => context.push('/contributors'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    decoration: BoxDecoration(color: ctaBg,
                        borderRadius: BorderRadius.circular(30), border: Border.all(color: _sage)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('👥', style: TextStyle(fontSize: 14)),
                        const SizedBox(width: 8),
                        Text('Meet our contributors',
                            style: GoogleFonts.lora(fontSize: 13, fontWeight: FontWeight.w600, color: _sage)),
                        const SizedBox(width: 6),
                        const Icon(Icons.chevron_right_rounded, size: 16, color: _sage),
                      ],
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

  Widget _statCard(String value, String label, IconData icon, {
    Color? bg, Color? border, Color? iconColor, Color? valueColor, Color? labelColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: bg ?? Colors.white.withOpacity(0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border ?? _border),
      ),
      child: Column(children: [
        Icon(icon, color: iconColor ?? _sage, size: 15),
        const SizedBox(height: 4),
        Text(value, style: GoogleFonts.lora(fontSize: 19, fontWeight: FontWeight.w700, color: valueColor ?? _ink)),
        Text(label, style: TextStyle(fontSize: 10, color: labelColor ?? _inkLight, fontWeight: FontWeight.w500)),
      ]),
    );
  }

  Widget _sectionHeader(String title, {String icon = '◈'}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(children: [
        Text(icon, style: const TextStyle(fontSize: 11, color: _sage)),
        const SizedBox(width: 8),
        Text(title, style: GoogleFonts.lora(fontSize: 17, fontWeight: FontWeight.w700, color: _ink)),
        const SizedBox(width: 10),
        Expanded(child: Container(height: 1, decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [_border, Colors.transparent])))),
      ]),
    );
  }

  Widget _buildFeatured(BuildContext context, ArticleHomeLoaded state) {
    final article = state.featured!;
    final t = Helpers.getPreferredTranslation(
      article.translations.map((t) => {
        'language': t.language, 'title': t.title,
        'content': t.content,  'excerpt': t.excerpt,
      }).toList(),
    );
    if (t == null) return const SizedBox.shrink();

    final title   = t['title']   as String? ?? '';
    final excerpt = t['excerpt'] as String? ??
        Helpers.makeExcerpt(t['content'] as String? ?? '', length: 180);
    final hasThumb = article.thumbnailUrl != null && article.thumbnailUrl!.isNotEmpty;
    final cat = Helpers.getCategoryInfo(article.category);

    return GestureDetector(
      onTap: () => context.push('/articles/${article.slug}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.black, width: 0.3),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 16, offset: const Offset(0,4))],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (hasThumb)
                Stack(children: [
                  SizedBox(height: 200, width: double.infinity,
                    child: CachedNetworkImage(imageUrl: article.thumbnailUrl!, fit: BoxFit.cover,
                      placeholder: (_, __) => Container(color: _parchmentDk),
                      errorWidget: (_, __, ___) => Container(color: _parchmentDk))),
                  Positioned(bottom:0,left:0,right:0,height:80,
                    child: DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(
                        begin: Alignment.topCenter, end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black.withOpacity(0.22)])))),
                  Positioned(top:12, left:12, child: _featuredBadge()),
                ])
              else
                Container(height: 56, color: _parchmentDk,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(children: [_featuredBadge()])),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: _sageBg, borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: _sageLight)),
                      child: Text('${cat?['icon']??''} ${cat?['label']??''}',
                          style: const TextStyle(fontSize: 11, color: _sage, fontWeight: FontWeight.w500)),
                    ),
                    const SizedBox(height: 10),
                    Text(title, style: GoogleFonts.lora(fontSize: 20, fontWeight: FontWeight.w700, color: _ink, height: 1.3),
                        maxLines: 3, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 8),
                    Text(excerpt, style: const TextStyle(fontSize: 13, color: _inkLight, height: 1.6),
                        maxLines: 3, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 14),
                    Container(height: 1, color: _border),
                    const SizedBox(height: 12),
                    Row(children: [
                      CircleAvatar(radius: 13, backgroundColor: _sageBg,
                        child: Text((article.profile?.username ?? 'A')[0].toUpperCase(),
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _sage))),
                      const SizedBox(width: 8),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(article.profile?.username ?? 'Anonymous',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _inkMid)),
                        Text(Helpers.timeAgo(article.updatedAt ?? article.createdAt),
                            style: const TextStyle(fontSize: 11, color: _inkLight)),
                      ])),
                      if (article.viewCount > 0) ...[
                        const Icon(Icons.remove_red_eye_outlined, size: 12, color: _inkLight),
                        const SizedBox(width: 3),
                        Text('${article.viewCount}', style: const TextStyle(fontSize: 11, color: _inkLight)),
                        const SizedBox(width: 10),
                      ],
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(color: _ink, borderRadius: BorderRadius.circular(8)),
                        child: const Text('Read →', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
                      ),
                    ]),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _featuredBadge() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(color: _sage, borderRadius: BorderRadius.circular(8)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.star_rounded, color: Colors.white, size: 11),
      const SizedBox(width: 4),
      Text('Featured', style: GoogleFonts.lora(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white)),
    ]),
  );

  Widget _buildArticleGrid(BuildContext context, List<ArticleModel> articles) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 0.65),
        itemCount: articles.length,
        itemBuilder: (_, i) => ArticleCard(article: articles[i]),
      ),
    );
  }

  Widget _buildError(BuildContext context, String message) {
    return Center(child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(width: 60, height: 60,
          decoration: BoxDecoration(color: const Color(0xFFFFF3E0), shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFFFD9A0))),
          child: const Icon(Icons.wifi_off_outlined, size: 26, color: Color(0xFFD4860A))),
        const SizedBox(height: 16),
        Text('Could not load articles',
            style: GoogleFonts.lora(fontSize: 16, fontWeight: FontWeight.w600, color: _ink)),
        const SizedBox(height: 6),
        Text(message, textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: _inkLight)),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: () => context.read<ArticleBloc>().add(ArticleHomeLoadRequested()),
          style: ElevatedButton.styleFrom(backgroundColor: _sage, foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          child: const Text('Try again'),
        ),
      ]),
    ));
  }
}