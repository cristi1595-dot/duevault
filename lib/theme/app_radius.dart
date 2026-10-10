import 'package:flutter/material.dart';

/// DueVault Design System - Corner Radius Tokens
/// Consistent curvature geometry across cards, inputs, buttons, and sheets.
class AppRadius {
  AppRadius._();

  /// 4.0 dp - Micro elements, inner indicators
  static const double xs = 4.0;

  /// 8.0 dp - Small badges, inner chips, tooltips
  static const double sm = 8.0;

  /// 12.0 dp - Input fields, secondary cards, inner tiles
  static const double md = 12.0;

  /// 16.0 dp - Standard Bento cards, primary buttons, dialogs
  static const double lg = 16.0;

  /// 20.0 dp - Featured hero cards
  static const double xl = 20.0;

  /// 24.0 dp - Bottom sheets, floating action modals
  static const double xxl = 24.0;

  /// 999.0 dp - Fully rounded pill badges and buttons
  static const double pill = 999.0;

  // --- PRE-PACKAGED BORDERRADIUS OBJECTS ---
  static const BorderRadius borderXs = BorderRadius.all(Radius.circular(xs));
  static const BorderRadius borderSm = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius borderMd = BorderRadius.all(Radius.circular(md));
  static const BorderRadius borderLg = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius borderXl = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius borderXxl = BorderRadius.all(Radius.circular(xxl));
  static const BorderRadius borderPill = BorderRadius.all(Radius.circular(pill));

  static const BorderRadius sheetTop = BorderRadius.vertical(top: Radius.circular(xxl));
}
