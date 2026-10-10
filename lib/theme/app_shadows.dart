import 'package:flutter/material.dart';

/// DueVault Design System - Elevation & Shadow Tokens
class AppShadows {
  AppShadows._();

  /// Subtle card shadow (light theme)
  static const List<BoxShadow> sm = [
    BoxShadow(
      color: Color(0x0A000000), // 4% black
      blurRadius: 4,
      offset: Offset(0, 1),
    ),
  ];

  /// Medium card shadow (light theme)
  static const List<BoxShadow> md = [
    BoxShadow(
      color: Color(0x0F000000), // 6% black
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];

  /// Elevated modal / sheet shadow (light theme)
  static const List<BoxShadow> lg = [
    BoxShadow(
      color: Color(0x1A000000), // 10% black
      blurRadius: 16,
      offset: Offset(0, 4),
    ),
  ];

  /// Ambient primary glow for hero elements (dark theme)
  static List<BoxShadow> darkEmeraldGlow({double opacity = 0.12}) => [
        BoxShadow(
          color: const Color(0xFF10B981).withValues(alpha: opacity),
          blurRadius: 24,
          spreadRadius: 2,
        ),
      ];
}
