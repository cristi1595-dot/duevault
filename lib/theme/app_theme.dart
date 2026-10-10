import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';
import 'app_radius.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

export 'app_colors.dart';
export 'app_spacing.dart';
export 'app_radius.dart';
export 'app_typography.dart';
export 'app_shadows.dart';
export 'app_animations.dart';

class AppTheme {
  // --- MASTER COLORS (Material 3 Emerald Palette) ---
  static const Color primaryAction = AppColors.emerald500; // Emerald accent (#10B981)
  static const Color primaryActionDark = AppColors.emerald600; // #059669
  static const Color urgentRed = AppColors.urgentRose600; // #E11D48
  static const Color urgentRedAlert = Color(0xFFDC2626);
  static const Color warningYellow = AppColors.warningAmber500; // #F59E0B
  static const Color safeGreen = AppColors.emerald500;
  static const Color accentPurple = AppColors.violet500; // #8B5CF6

  // --- DARK MODE PALETTE (Modern Slate/Zinc Fintech) ---
  static const Color darkBackground = AppColors.slate950; // #0B0F19
  static const Color darkSurface = AppColors.slate850; // #161F30
  static const Color darkBorder = Color(0xFF222F48);
  static const Color darkTextPrimary = Color(0xFFF1F5F9);
  static const Color darkTextSecondary = AppColors.slate400; // #94A3B8

  // --- LIGHT MODE PALETTE (Clean Neutral) ---
  static const Color lightBackground = AppColors.slate50; // #F8FAFC
  static const Color lightSurface = Colors.white;
  static const Color lightBorder = AppColors.slate200; // #E2E8F0
  static const Color lightTextPrimary = AppColors.slate900; // #0F172A
  static const Color lightTextSecondary = AppColors.slate600; // #475569 (WCAG AA 4.7:1)

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
        titleTextStyle: GoogleFonts.inter(
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
        primary: brightness == Brightness.dark ? primaryAction : primaryActionDark,
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
      textTheme: GoogleFonts.interTextTheme(base.textTheme).copyWith(
        displayLarge: AppTypography.displayLarge(textPrimary),
        headlineLarge: AppTypography.headlineLarge(textPrimary),
        headlineMedium: AppTypography.headlineMedium(textPrimary),
        bodyLarge: AppTypography.bodyLarge(textPrimary),
        bodyMedium: AppTypography.bodyMedium(textSecondary),
        bodySmall: AppTypography.bodySmall(textSecondary),
        labelMedium: AppTypography.labelMedium(textSecondary),
        labelSmall: AppTypography.labelSmall(textSecondary),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(color: border, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: brightness == Brightness.dark ? primaryAction : primaryActionDark,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: AppSpacing.buttonPadding,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: AppSpacing.inputPadding,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: BorderSide(color: border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: const BorderSide(
            color: primaryAction,
            width: 2, // M3 focus border is 2dp
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: const BorderSide(
            color: urgentRed,
            width: 1.5,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: const BorderSide(
            color: urgentRed,
            width: 2,
          ),
        ),
        hintStyle: TextStyle(color: textSecondary.withValues(alpha: 0.7)),
      ),
    );
  }

  // Helper getters for backward compatibility
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AppColors.statusSafeText(isDark);
  }

  static Color getMintGreen(BuildContext context) {
    return AppColors.emerald400;
  }

  static Color getSettingsAccent(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? AppColors.emerald400
        : AppColors.emerald700;
  }

  static TextStyle labelCapsStyle(BuildContext context) {
    return AppTypography.labelCaps(getTextSecondary(context));
  }

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
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: BorderSide.none,
      ),
      filled: true,
      fillColor: darkSurface,
      contentPadding: AppSpacing.inputPadding,
    );
  }
}

/// Convenience context extensions for fluent Design System access
extension AppThemeContextExtension on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
  Color get primaryColor => Theme.of(this).colorScheme.primary;
  Color get scaffoldBg => Theme.of(this).scaffoldBackgroundColor;
  Color get cardColor =>
      Theme.of(this).cardTheme.color ?? (isDark ? AppColors.slate850 : Colors.white);
  Color get borderColor => Theme.of(this).colorScheme.outline;
  Color get textPrimary =>
      Theme.of(this).textTheme.bodyLarge?.color ??
      (isDark ? AppColors.slate50 : AppColors.slate900);
  Color get textSecondary =>
      Theme.of(this).textTheme.bodyMedium?.color ??
      (isDark ? AppColors.slate400 : AppColors.slate600);
}
