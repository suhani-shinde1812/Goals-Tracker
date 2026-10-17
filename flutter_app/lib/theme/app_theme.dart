import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF406359);
  static const Color primaryDark = Color(0xFF20312B);
  static const Color primaryLight = Color(0xFF739E92);
  static const Color primarySoft = Color(0xFFE9F2EE);

  static const Color accentMint = Color(0xFF40916C);
  static const Color accentWarm = Color(0xFFD96B43);
  static const Color accentAmber = Color(0xFFE76F51);
  static const Color accentBlue = Color(0xFF3A86FF);

  static const Color bgPrimary = Color(0xFFF8FAF8);
  static const Color bgCard = Color(0xFFFFFFFF);
  static const Color textMain = Color(0xFF19201D);
  static const Color textMuted = Color(0xFF596561);
  static const Color textLight = Color(0xFF8A9692);
  static const Color borderColor = Color(0xFFE5ECE8);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: bgPrimary,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        secondary: primaryDark,
        surface: bgCard,
        background: bgPrimary,
        error: accentWarm,
      ),
      textTheme: GoogleFonts.plusJakartaSansTextTheme().copyWith(
        displayLarge: GoogleFonts.outfit(color: textMain, fontWeight: FontWeight.bold),
        displayMedium: GoogleFonts.outfit(color: textMain, fontWeight: FontWeight.bold),
        titleLarge: GoogleFonts.outfit(color: textMain, fontWeight: FontWeight.w600, fontSize: 20),
        titleMedium: GoogleFonts.outfit(color: textMain, fontWeight: FontWeight.w600, fontSize: 16),
        bodyLarge: TextStyle(color: textMain, fontSize: 15),
        bodyMedium: TextStyle(color: textMuted, fontSize: 13),
      ),
      cardTheme: CardTheme(
        color: bgCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: borderColor, width: 1),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: bgCard,
        foregroundColor: textMain,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return primaryColor;
          }
          return Colors.transparent;
        }),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
    );
  }
}
