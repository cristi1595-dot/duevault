import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// DueVault Design System - Typography Tokens
/// Based on Google Fonts Inter with tuned letter spacing and line heights.
class AppTypography {
  AppTypography._();

  // --- HEADLINE & DISPLAY STYLES ---
  static TextStyle displayLarge(Color color) => GoogleFonts.inter(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.64,
        height: 1.25,
        color: color,
      );

  static TextStyle headlineLarge(Color color) => GoogleFonts.inter(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.32,
        height: 1.3,
        color: color,
      );

  static TextStyle headlineMedium(Color color) => GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        height: 1.35,
        color: color,
      );

  static TextStyle titleMedium(Color color) => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.1,
        height: 1.4,
        color: color,
      );

  // --- BODY STYLES ---
  static TextStyle bodyLarge(Color color) => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.0,
        height: 1.5,
        color: color,
      );

  static TextStyle bodyMedium(Color color) => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.0,
        height: 1.5,
        color: color,
      );

  static TextStyle bodySmall(Color color) => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.1,
        height: 1.4,
        color: color,
      );

  // --- LABELS & CAPTIONS ---
  static TextStyle labelMedium(Color color) => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        height: 1.4,
        color: color,
      );

  static TextStyle labelSmall(Color color) => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        height: 1.3,
        color: color,
      );

  static TextStyle labelCaps(Color color) => GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
        height: 1.3,
        color: color,
      );

  static TextStyle caption(Color color) => GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.2,
        height: 1.3,
        color: color,
      );
}
