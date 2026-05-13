import 'package:flutter/material.dart';

class AppColors {
  // Obsidian Core Theme Palette
  static const Color background = Color(0xFF090D1A);
  static const Color surface = Color(0xFF131B2E);
  static const Color cardBg = Color(0xFF1E293B);
  
  // High energy neons
  static const Color neonGreen = Color(0xFF10B981);
  static const Color neonAmber = Color(0xFFF59E0B);
  static const Color neonRed = Color(0xFFEF4444);
  static const Color neonBlue = Color(0xFF0EA5E9);
  
  // Text Shades
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);

  // Border and shadow styling
  static const Color border = Color(0x1EFFFFFF);
  static const Color glowColor = Color(0x1010B981);

  // Linear gradient profiles
  static const LinearGradient greenGlow = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF059669)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkGlass = LinearGradient(
    colors: [Color(0x2BFFFFFF), Color(0x05FFFFFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cyberGlow = LinearGradient(
    colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient warningGlow = LinearGradient(
    colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient dangerGlow = LinearGradient(
    colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
