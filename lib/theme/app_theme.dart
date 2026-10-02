import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // --- MASTER COLORS (Material 3 Emerald Palette) ---
  static const Color primaryAction = Color(0xFF10B981); // Emerald accent
  static const Color primaryActionDark = Color(0xFF059669);
  static const Color urgentRed = Color(0xFFEF4444);
  static const Color urgentRedAlert = Color(0xFFDC2626);
  static const Color warningYellow = Color(0xFFF59E0B);
  static const Color safeGreen = Color(0xFF10B981);
  static const Color accentPurple = Color(0xFF8B5CF6);

  // --- DARK MODE PALETTE (Neutral Slate/Zinc) ---
  static const Color darkBackground = Color(0xFF0C0E12);
  static const Color darkSurface = Color(0xFF161A22);
  static const Color darkBorder = Color(0xFF222734);
  static const Color darkTextPrimary = Color(0xFFF1F5F9);
  static const Color darkTextSecondary = Color(0xFF94A3B8);

  // --- LIGHT MODE PALETTE (Clean Neutral) ---
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
    ).copyWith(
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? primaryAction : null,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? primaryAction.withValues(alpha: 0.5)
              : null,
        ),
      ),
      sliderTheme: const SliderThemeData(
        activeTrackColor: primaryAction,
        thumbColor: primaryAction,
      ),
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
    ).copyWith(
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? primaryActionDark : null,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? primaryActionDark.withValues(alpha: 0.5)
              : null,
        ),
      ),
      sliderTheme: const SliderThemeData(
        activeTrackColor: primaryActionDark,
        thumbColor: primaryActionDark,
      ),
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
    final base = ThemeData(brightness: brightness, useMaterial3: true);

    return base.copyWith(
      scaffoldBackgroundColor: background,
      primaryColor: primaryAction,
      dividerColor: border,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textPrimary),
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        systemOverlayStyle: brightness == Brightness.dark
            ? SystemUiOverlayStyle.light.copyWith(
                statusBarColor: Colors.transparent,
                statusBarIconBrightness: Brightness.light,
                statusBarBrightness: Brightness.dark,
              )
            : SystemUiOverlayStyle.dark.copyWith(
                statusBarColor: Colors.transparent,
                statusBarIconBrightness: Brightness.dark,
                statusBarBrightness: Brightness.light,
              ),
      ),
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
        surfaceContainerLow: background, // M3 Container logic
      ),
      textTheme: GoogleFonts.outfitTextTheme(base.textTheme).copyWith(
        displayLarge: GoogleFonts.outfit(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: textPrimary,
          letterSpacing: -0.64,
        ),
        headlineLarge: GoogleFonts.outfit(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        headlineMedium: GoogleFonts.outfit(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        bodyLarge: GoogleFonts.outfit(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: textPrimary,
        ),
        bodyMedium: GoogleFonts.outfit(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: textSecondary,
        ),
        labelSmall: GoogleFonts.outfit(
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
          borderRadius: BorderRadius.circular(16), // Clean M3 Radius
          side: BorderSide(color: border, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryAction,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.outfit(fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: primaryAction,
            width: 2,
          ), // M3 focus border is 2dp
        ),
        hintStyle: TextStyle(color: textSecondary),
      ),
    );
  }

  // Helper getters for static access (though dynamic is preferred via Theme.of)
  static Color getBackground(BuildContext context) =>
      Theme.of(context).scaffoldBackgroundColor;
  static Color getSurface(BuildContext context) =>
      Theme.of(context).cardTheme.color!;
  static Color getBorder(BuildContext context) =>
      Theme.of(context).colorScheme.outline;
  static Color getTextPrimary(BuildContext context) =>
      Theme.of(context).textTheme.bodyLarge!.color!;
  static Color getTextSecondary(BuildContext context) =>
      Theme.of(context).textTheme.bodyMedium!.color!;

  static Color getSafeGreen(BuildContext context) {
    return const Color(0xFF10B981);
  }

  static Color getMintGreen(BuildContext context) {
    return const Color(0xFF34D399);
  }

  static Color getSettingsAccent(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.greenAccent
        : Colors.teal.shade700;
  }

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
