import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// DyanX — Design System
/// Paleta: índigo muted / charcoal escuro / off-white quente
/// Sem azul genérico, sem verde WhatsApp
class AppColors {
  AppColors._();

  // ── Accent ──────────────────────────────────────────────────────
  static const Color accentLight = Color(0xFF4F46E5);  // indigo
  static const Color accentDark  = Color(0xFF818CF8);  // indigo suave

  // ── Background ──────────────────────────────────────────────────
  static const Color bgLight   = Color(0xFFF7F7F5);
  static const Color bgDark    = Color(0xFF07080D);

  // ── Surface / Card ──────────────────────────────────────────────
  static const Color surfaceLight  = Color(0xFFFFFFFF);
  static const Color surfaceDark   = Color(0xFF0E0F17);
  static const Color surface2Dark  = Color(0xFF13141E);

  // ── Border ──────────────────────────────────────────────────────
  static const Color borderLight = Color(0x12000000); // rgba 0,0,0,0.07
  static const Color borderDark  = Color(0x0FFFFFFF); // rgba 255,255,255,0.06

  // ── Text ────────────────────────────────────────────────────────
  static const Color textLight     = Color(0xFF111118);
  static const Color textSubLight  = Color(0xFF6B6B82);
  static const Color textMutedLight= Color(0xFFA8A8BC);

  static const Color textDark      = Color(0xFFF0F1FA);
  static const Color textSubDark   = Color(0xFF8B8CA8);
  static const Color textMutedDark = Color(0xFF4A4B62);

  // ── Semantic ────────────────────────────────────────────────────
  static const Color greenLight  = Color(0xFF059669);
  static const Color greenDark   = Color(0xFF34D399);

  static const Color redLight    = Color(0xFFDC2626);
  static const Color redDark     = Color(0xFFF87171);

  static const Color amberLight  = Color(0xFFD97706);
  static const Color amberDark   = Color(0xFFFBBF24);
}

class AppTheme {
  AppTheme._();

  // ── Light ───────────────────────────────────────────────────────
  static ThemeData light() {
    const accent = AppColors.accentLight;
    final textTheme = GoogleFonts.poppinsTextTheme(ThemeData.light().textTheme);

    return ThemeData.light(useMaterial3: true).copyWith(
      colorScheme: const ColorScheme.light(
        primary:         accent,
        onPrimary:       Colors.white,
        secondary:       AppColors.greenLight,
        onSecondary:     Colors.white,
        error:           AppColors.redLight,
        surface:         AppColors.surfaceLight,
        onSurface:       AppColors.textLight,
        surfaceContainer: AppColors.bgLight,
        outline:         AppColors.borderLight,
      ),
      scaffoldBackgroundColor: AppColors.bgLight,
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        backgroundColor: AppColors.bgLight,
        foregroundColor: AppColors.textLight,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 20, fontWeight: FontWeight.w800,
          color: AppColors.textLight, letterSpacing: -0.5,
        ),
      ),
      cardTheme: CardTheme(
        elevation: 0,
        color: AppColors.surfaceLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.borderLight),
        ),
        margin: EdgeInsets.zero,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.borderLight, thickness: 1, space: 1,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.white,
          textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: accent,
          side: const BorderSide(color: AppColors.accentLight),
          textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceLight,
        hintStyle: GoogleFonts.poppins(color: AppColors.textMutedLight),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: accent, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        linearMinHeight: 2,
        color: accent,
        linearTrackColor: AppColors.borderLight,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.bgLight,
        side: const BorderSide(color: AppColors.borderLight),
        labelStyle: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
        padding: const EdgeInsets.symmetric(horizontal: 4),
      ),
    );
  }

  // ── Dark ────────────────────────────────────────────────────────
  static ThemeData dark() {
    const accent = AppColors.accentDark;
    final textTheme = GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme);

    return ThemeData.dark(useMaterial3: true).copyWith(
      colorScheme: const ColorScheme.dark(
        primary:         accent,
        onPrimary:       Color(0xFF07080D),
        secondary:       AppColors.greenDark,
        onSecondary:     Color(0xFF07080D),
        error:           AppColors.redDark,
        surface:         AppColors.surfaceDark,
        onSurface:       AppColors.textDark,
        surfaceContainer: AppColors.bgDark,
        outline:         AppColors.borderDark,
      ),
      scaffoldBackgroundColor: AppColors.bgDark,
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        backgroundColor: AppColors.bgDark,
        foregroundColor: AppColors.textDark,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 20, fontWeight: FontWeight.w800,
          color: AppColors.textDark, letterSpacing: -0.5,
        ),
      ),
      cardTheme: CardTheme(
        elevation: 0,
        color: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.borderDark),
        ),
        margin: EdgeInsets.zero,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.borderDark, thickness: 1, space: 1,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: const Color(0xFF07080D),
          textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: accent,
          side: const BorderSide(color: AppColors.accentDark),
          textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceDark,
        hintStyle: GoogleFonts.poppins(color: AppColors.textMutedDark),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: accent, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        linearMinHeight: 2,
        color: accent,
        linearTrackColor: AppColors.borderDark,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceDark,
        side: const BorderSide(color: AppColors.borderDark),
        labelStyle: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSubDark),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
        padding: const EdgeInsets.symmetric(horizontal: 4),
      ),
    );
  }
}
