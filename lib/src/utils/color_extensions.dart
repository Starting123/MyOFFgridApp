import 'package:flutter/material.dart';

extension ColorExtensions on Color {
  /// Creates a new color with the given opacity value.
  /// Uses the newer .withValues() method to avoid deprecation warnings.
  Color withAlpha(double opacity) {
    final int alpha = (opacity * 255).round();
    return Color.fromARGB(alpha, red, green, blue);
  }
}