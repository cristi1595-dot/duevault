import 'package:flutter/material.dart';

/// DueVault Design System - Motion & Animation Tokens
class AppAnimations {
  AppAnimations._();

  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 400);

  static const Curve curveDefault = Curves.easeInOutCubic;
  static const Curve curveEntrance = Curves.easeOutCubic;
  static const Curve curveExit = Curves.easeInCubic;
}
