import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color greenPrimary = Color(0xFF15803D);
  static const Color greenDark = Color(0xFF166534);
  static const Color greenLight = Color(0xFFDCFCE7);
  static const Color greenBg = Color(0xFFF0FDF4);
  static const Color stone50 = Color(0xFFFAFAF8);
  static const Color stone200 = Color(0xFFE7E5E4);
  static const Color stone900 = Color(0xFF1C1917);

  static ThemeData get theme => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: greenPrimary,
      primary: greenPrimary,
      surface: Colors.white,
    ),
    scaffoldBackgroundColor: stone50,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: stone900,
      elevation: 0,
      scrolledUnderElevation: 1,
      shadowColor: Colors.black12,
      titleTextStyle: GoogleFonts.playfairDisplay(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: stone900,
      ),
    ),
    textTheme: GoogleFonts.dmSansTextTheme().copyWith(
      displayLarge: GoogleFonts.playfairDisplay(
        fontSize: 32,
        fontWeight: FontWeight.w700,
      ),
      displayMedium: GoogleFonts.playfairDisplay(
        fontSize: 24,
        fontWeight: FontWeight.w700,
      ),
      headlineLarge: GoogleFonts.playfairDisplay(
        fontSize: 22,
        fontWeight: FontWeight.w700,
      ),
      headlineMedium: GoogleFonts.playfairDisplay(
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
      titleLarge: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w600),
      bodyLarge: GoogleFonts.dmSans(fontSize: 15, height: 1.7),
      bodyMedium: GoogleFonts.dmSans(fontSize: 14, height: 1.6),
      bodySmall: GoogleFonts.dmSans(fontSize: 12, color: Colors.grey[600]),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: greenPrimary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: greenPrimary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      filled: true,
      fillColor: Colors.grey[50],
    ),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      color: Colors.white,
    ),
  );
}
