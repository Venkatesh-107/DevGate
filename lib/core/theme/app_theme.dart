import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// DevGate Design System — Single source of truth for all visual tokens.
class AppTheme {
  AppTheme._(); // prevent instantiation

  // ─── Core Palette ──────────────────────────────────────────────────────────
  static const Color seedBlue    = Color(0xFF4285F4);  // Google Blue
  static const Color surface     = Color(0xFF131314);  // near-black background
  static const Color card        = Color(0xFF1E1E1E);  // elevated card surface
  static const Color border      = Color(0xFF3C4043);  // subtle dividers
  static const Color accent      = Color(0xFF8AB4F8);  // light blue — primary actions
  static const Color deepNavy    = Color(0xFF0F172A);  // headers, stat bar
  static const Color divider     = Color(0xFF334155);  // secondary dividers

  // ─── Semantic Colors ───────────────────────────────────────────────────────
  static const Color success     = Color(0xFF10B981); // Emerald 500
  static const Color danger      = Color(0xFFEF4444); // Red 500
  static const Color warning     = Color(0xFFF59E0B); // Amber 500
  static const Color info        = Color(0xFF3B82F6); // Blue 500
  static const Color secretMask  = Color(0xFF2A1414); // Dark red-black for masked secrets

  // ─── Text Colors ───────────────────────────────────────────────────────────
  static const Color textPrimary   = Colors.white;
  static const Color textSecondary = Colors.white70;
  static const Color textMuted     = Colors.grey;

  // ─── Typography (Type Scale) ───────────────────────────────────────────────
  static TextStyle get codeStyle => GoogleFonts.jetBrainsMono(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: textSecondary,
  );

  static TextTheme get _textTheme => GoogleFonts.interTextTheme(ThemeData.dark().textTheme).copyWith(
    displaySmall: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w600, color: textPrimary),
    titleMedium: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: textPrimary),
    bodyMedium: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w400, color: textPrimary),
    labelSmall: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: textSecondary, letterSpacing: 0.06),
  );

  // ─── Opacity Helpers ───────────────────────────────────────────────────────
  /// Use these instead of .withOpacity() to avoid the deprecation
  static Color accentLight([double alpha = 0.1]) => accent.withValues(alpha: alpha);
  static Color successLight([double alpha = 0.1]) => success.withValues(alpha: alpha);
  static Color dangerLight([double alpha = 0.1]) => danger.withValues(alpha: alpha);
  static Color borderLight([double alpha = 0.5]) => border.withValues(alpha: alpha);

  // ─── Input Decoration ──────────────────────────────────────────────────────
  static InputDecoration inputDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: textMuted, fontSize: 12),
      prefixIcon: Icon(icon, color: textMuted, size: 20),
      filled: true,
      fillColor: deepNavy,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade800)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: info)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  // ─── Card Decoration ───────────────────────────────────────────────────────
  static BoxDecoration cardDecoration({Color? borderColor}) {
    return BoxDecoration(
      color: card,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: borderColor ?? border),
    );
  }

  // ─── Full Theme ────────────────────────────────────────────────────────────
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      textTheme: _textTheme,
      colorScheme: ColorScheme.fromSeed(
        seedColor: seedBlue,
        brightness: Brightness.dark,
        surface: surface,
      ),
      scaffoldBackgroundColor: surface,
      appBarTheme: const AppBarTheme(
        backgroundColor: surface,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      navigationRailTheme: const NavigationRailThemeData(
        backgroundColor: card,
        useIndicator: true,
        indicatorColor: seedBlue,
      ),
    );
  }
}
