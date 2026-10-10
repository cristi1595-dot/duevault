import 'package:flutter/material.dart';

/// DueVault Design System - Spacing Tokens
/// Built on a strict 4pt / 8pt mathematical grid for visual harmony and cadence.
class AppSpacing {
  AppSpacing._();

  /// 2.0 dp - Micro adjustments
  static const double xxs = 2.0;

  /// 4.0 dp - Tight spacing, internal chip padding
  static const double xs = 4.0;

  /// 8.0 dp - Small spacing, icon gaps, compact rows
  static const double sm = 8.0;

  /// 12.0 dp - Standard card padding, compact margins
  static const double md = 12.0;

  /// 16.0 dp - Base rhythm, standard screen edge padding, form gaps
  static const double base = 16.0;

  /// 20.0 dp - Medium-large spacing, section separation
  static const double lg = 20.0;

  /// 24.0 dp - Large spacing, card group separation
  static const double xl = 24.0;

  /// 32.0 dp - Extra large spacing, modal headers, empty state margins
  static const double xxl = 32.0;

  /// 48.0 dp - Section breaks, hero offsets
  static const double xxxl = 48.0;

  /// 64.0 dp - Large vertical whitespace
  static const double huge = 64.0;

  // --- PRE-PACKAGED EDGEINSETS FOR COMMON UI PATTERNS ---
  static const EdgeInsets screenPadding = EdgeInsets.symmetric(horizontal: base);
  static const EdgeInsets cardPadding = EdgeInsets.all(md);
  static const EdgeInsets cardPaddingLg = EdgeInsets.all(base);
  static const EdgeInsets dialogPadding = EdgeInsets.all(xl);
  static const EdgeInsets badgePadding = EdgeInsets.symmetric(horizontal: sm, vertical: xxs);
  static const EdgeInsets inputPadding = EdgeInsets.symmetric(horizontal: base, vertical: md);
  static const EdgeInsets buttonPadding = EdgeInsets.symmetric(horizontal: xl, vertical: base);
}
