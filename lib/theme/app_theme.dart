import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // --- MASTER COLORS ---
  static const Color primaryAction = Color(0xFF3B82F6);
  static const Color urgentRed = Color(0xFFEF4444);
  static const Color urgentRedAlert = Color(0xFFA62121);
  static const Color warningYellow = Color(0xFFF59E0B);
  static const Color safeGreen = Color(0xFF10B981);
  static const Color accentPurple = Color(0xFF8B5CF6);

  // --- DARK MODE PALETTE ---
  static const Color darkBackground = Color(0xFF131313);
  static const Color darkSurface = Color(0xFF27272A);
  static const Color darkBorder = Color(0xFF52525B);
  static const Color darkTextPrimary = Colors.white;
  static const Color darkTextSecondary = Color(0xFFA1A1AA);

  // --- LIGHT MODE PALETTE ---
  static const Color lightBackground = Color(0xFFF8FAFC);
  static const Color lightSurface = Colors.white;
  static const Color lightBorder = Color(0xFFE2E8F0);
  static const Color lightTextPrimary = Color(0xFF0F172A);
  static const Color lightTextSecondary = Color(0xFF64748B);

  // --- THEME DATA GETTERS ---

  static ThemeData get darkTheme {
    return _buildTheme(
      brightness: Brightness.dark,
      background: darkBackground,
      surface: darkSurface,
      border: darkBorder,
      textPrimary: darkTextPrimary,
      textSecondary: darkTextSecondary,
    );
  }

  static ThemeData get lightTheme {
    return _buildTheme(
      brightness: Brightness.light,
      background: lightBackground,
      surface: lightSurface,
      border: lightBorder,
      textPrimary: lightTextPrimary,
      textSecondary: lightTextSecondary,
    );
  }

  static ThemeData _buildTheme({
    required Brightness brightness,
    required Color background,
    required Color surface,
    required Color border,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    final base = brightness == Brightness.dark ? ThemeData.dark() : ThemeData.light();
    
    return base.copyWith(
      brightness: brightness,
      scaffoldBackgroundColor: background,
      primaryColor: primaryAction,
      dividerColor: border,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: primaryAction,
        onPrimary: Colors.white,
        secondary: primaryAction,
        onSecondary: Colors.white,
        error: urgentRed,
        onError: Colors.white,
        surface: surface,
        onSurface: textPrimary,
        outline: border,
      ),
      textTheme: GoogleFonts.interTextTheme(base.textTheme).copyWith(
        displayLarge: GoogleFonts.inter(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: textPrimary,
          letterSpacing: -0.64,
        ),
        headlineLarge: GoogleFonts.inter(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        headlineMedium: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: textPrimary,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: textSecondary,
        ),
        labelSmall: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textSecondary,
          letterSpacing: 0.5,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: border, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryAction,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryAction, width: 1),
        ),
        hintStyle: TextStyle(color: textSecondary),
      ),
    );
  }

  // Helper getters for static access (though dynamic is preferred via Theme.of)
  static Color getBackground(BuildContext context) => Theme.of(context).scaffoldBackgroundColor;
  static Color getSurface(BuildContext context) => Theme.of(context).cardTheme.color!;
  static Color getBorder(BuildContext context) => Theme.of(context).colorScheme.outline;
  static Color getTextPrimary(BuildContext context) => Theme.of(context).textTheme.bodyLarge!.color!;
  static Color getTextSecondary(BuildContext context) => Theme.of(context).textTheme.bodyMedium!.color!;

  static TextStyle labelCapsStyle(BuildContext context) {
    return GoogleFonts.inter(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: getTextSecondary(context),
      letterSpacing: 0.6,
    );
  }

  // Maintain backward compatibility for static constants if possible, 
  // but warn that they are no longer static-only.
  // We'll keep the names but they should ideally come from Theme.of(context)
  static const Color textSecondary = darkTextSecondary;
  static const Color background = darkBackground;
  static const Color surface = darkSurface;
  static const Color textPrimary = darkTextPrimary;
  static const Color borderGlow = darkBorder;
  static const Color backgroundBlack = Color(0xFF000000);

  static InputDecoration inputDecoration(String hintText) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(color: darkTextSecondary, fontSize: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      filled: true,
      fillColor: darkSurface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }
}
