import 'package:flutter/material.dart';

abstract final class AppColors {
  static const black = Color(0xFF070707);
  static const surface = Color(0xFF121212);
  static const surfaceHigh = Color(0xFF1A1A1A);
  static const hairline = Color(0x33D4AF37);

  static const gold = Color(0xFFD4AF37);
  static const goldLight = Color(0xFFF6DF8F);
  static const goldDark = Color(0xFF8C6A1C);

  // Secondary accent for co-guests, so they never read as the primary guest.
  static const silver = Color(0xFFC3C8D0);
  static const silverLight = Color(0xFFEEF0F3);
  static const silverDark = Color(0xFF666C75);
  static const silverHairline = Color(0x33C3C8D0);

  static const textPrimary = Color(0xFFF5F0E1);
  static const textMuted = Color(0xFF8F8A7A);
  static const error = Color(0xFFE5484D);

  static const goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [goldDark, gold, goldLight, gold, goldDark],
    stops: [0.0, 0.3, 0.5, 0.7, 1.0],
  );
}
