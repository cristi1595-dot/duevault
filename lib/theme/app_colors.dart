import 'package:flutter/material.dart';

/// DueVault Design System - Color Tokens
/// Adheres to WCAG AA accessibility standards with semantic contrast mappings.
class AppColors {
  AppColors._();

  // --- BRAND / PRIMARY EMERALD SCALE ---
  static const Color emerald50 = Color(0xFFECFDF5);
  static const Color emerald100 = Color(0xFFD1FAE5);
  static const Color emerald200 = Color(0xFFA7F3D0);
  static const Color emerald300 = Color(0xFF6EE7B7);
  static const Color emerald400 = Color(0xFF34D399); // Mint Safe / Dark mode vibrant text
  static const Color emerald500 = Color(0xFF10B981); // Master Emerald Primary
  static const Color emerald600 = Color(0xFF059669); // Dark Emerald / Light mode button fill
  static const Color emerald700 = Color(0xFF047857); // Deep Emerald / Light mode accessible text (4.6:1)
  static const Color emerald800 = Color(0xFF065F46);
  static const Color emerald900 = Color(0xFF064E3B);

  // --- SECONDARY / ACCENT VIOLET ---
  static const Color violet400 = Color(0xFFA78BFA);
  static const Color violet500 = Color(0xFF8B5CF6);
  static const Color violet600 = Color(0xFF7C3AED);

  // --- SLATE NEUTRALS (FINTECH FOUNDATION) ---
  static const Color slate50 = Color(0xFFF8FAFC);
  static const Color slate100 = Color(0xFFF1F5F9);
  static const Color slate200 = Color(0xFFE2E8F0);
  static const Color slate300 = Color(0xFFCBD5E1);
  static const Color slate400 = Color(0xFF94A3B8);
  static const Color slate500 = Color(0xFF64748B);
  static const Color slate600 = Color(0xFF475569);
  static const Color slate700 = Color(0xFF334155);
  static const Color slate800 = Color(0xFF1E293B);
  static const Color slate850 = Color(0xFF161F30); // Dark Surface
  static const Color slate900 = Color(0xFF0F172A);
  static const Color slate950 = Color(0xFF0B0F19); // Dark Scaffold Background

  // --- SEMANTIC STATUS PALETTES ---
  // Overdue / Urgent (<= 3 days)
  static const Color urgentRose400 = Color(0xFFFB7185); // Dark text
  static const Color urgentRose500 = Color(0xFFF43F5E);
  static const Color urgentRose600 = Color(0xFFE11D48); // Primary urgent red
  static const Color urgentRose700 = Color(0xFFBE123C); // Light text (passes 4.7:1)

  // Warning / Soon (4 - 7 days)
  static const Color warningAmber400 = Color(0xFFFBBF24); // Dark text
  static const Color warningAmber500 = Color(0xFFF59E0B);
  static const Color warningAmber700 = Color(0xFFB45309); // Light text (passes 4.5:1)

  // Safe / Active (> 7 days or Paid)
  static const Color safeEmerald400 = Color(0xFF34D399); // Dark text
  static const Color safeEmerald500 = Color(0xFF10B981);
  static const Color safeEmerald700 = Color(0xFF047857); // Light text (passes 4.6:1)

  // Info / Permanent Document
  static const Color infoBlue400 = Color(0xFF60A5FA); // Dark text
  static const Color infoBlue500 = Color(0xFF3B82F6);
  static const Color infoBlue700 = Color(0xFF1D4ED8); // Light text (passes 4.5:1)

  // --- CONTEXT SENSITIVE HELPERS (DARK VS LIGHT) ---
  static Color background(bool isDark) => isDark ? slate950 : slate50;
  static Color surface(bool isDark) => isDark ? slate850 : Colors.white;
  static Color surfaceElevated(bool isDark) => isDark ? slate800 : slate100;
  static Color border(bool isDark) => isDark ? const Color(0xFF222F48) : slate200;
  static Color borderSubtle(bool isDark) => isDark ? slate800 : const Color(0xFFF1F5F9);

  static Color textPrimary(bool isDark) => isDark ? slate50 : slate900;
  static Color textSecondary(bool isDark) => isDark ? slate400 : slate600;
  static Color textMuted(bool isDark) => isDark ? slate500 : slate400;

  // Status colors with guaranteed WCAG AA contrast (>= 4.5:1 on background)
  static Color statusUrgentText(bool isDark) => isDark ? urgentRose400 : urgentRose700;
  static Color statusWarningText(bool isDark) => isDark ? warningAmber400 : warningAmber700;
  static Color statusSafeText(bool isDark) => isDark ? safeEmerald400 : safeEmerald700;
  static Color statusInfoText(bool isDark) => isDark ? infoBlue400 : infoBlue700;
}
