// lib/theme/app_theme.dart
//
// Yellow × Black × White premium theme for NeighbourHub.
// Bold, high-contrast, modern dark design.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ─── Brand Colors ─────────────────────────────────────────────────────────
  // Yellow — the hero accent
  static const Color primaryColor  = Color(0xFFFFCC00);   // Vivid yellow
  static const Color primaryLight  = Color(0xFFFFDD44);   // Lighter yellow
  static const Color primaryDark   = Color(0xFFD4A800);   // Darker gold

  // Neutral palette
  static const Color black         = Color(0xFF0A0A0A);   // True black
  static const Color darkBg        = Color(0xFF111111);   // App background
  static const Color darkCard      = Color(0xFF1C1C1C);   // Card surface
  static const Color darkBorder    = Color(0xFF2E2E2E);   // Subtle borders
  static const Color darkSubtext   = Color(0xFF9CA3AF);   // Muted text
  static const Color white         = Color(0xFFFFFFFF);
  static const Color offWhite      = Color(0xFFF3F4F6);   // Slightly warm white

  // Status colors
  static const Color successColor = Color(0xFF22C55E);
  static const Color warningColor = Color(0xFFF59E0B);
  static const Color errorColor   = Color(0xFFEF4444);
  static const Color infoColor    = Color(0xFF38BDF8);

  // Legacy grey aliases (used by some widgets)
  static const Color grey100 = Color(0xFF1C1C1C);
  static const Color grey200 = Color(0xFF2E2E2E);
  static const Color grey400 = Color(0xFF6B7280);
  static const Color grey600 = Color(0xFF9CA3AF);
  static const Color grey800 = Color(0xFFD1D5DB);
  static const Color grey900 = Color(0xFFF3F4F6);

  // ─── Dark Theme (default) ──────────────────────────────────────────────────
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        onPrimary: black,
        secondary: primaryLight,
        onSecondary: black,
        surface: darkCard,
        onSurface: white,
        error: errorColor,
        onError: white,
        outline: darkBorder,
      ),

      scaffoldBackgroundColor: darkBg,

      // Typography
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).copyWith(
        displayLarge: GoogleFonts.inter(color: white, fontWeight: FontWeight.w800),
        displayMedium: GoogleFonts.inter(color: white, fontWeight: FontWeight.w700),
        headlineLarge: GoogleFonts.inter(color: white, fontWeight: FontWeight.w700),
        headlineMedium: GoogleFonts.inter(color: white, fontWeight: FontWeight.w700),
        headlineSmall: GoogleFonts.inter(color: white, fontWeight: FontWeight.w700),
        titleLarge: GoogleFonts.inter(color: white, fontWeight: FontWeight.w600),
        titleMedium: GoogleFonts.inter(color: white, fontWeight: FontWeight.w600),
        titleSmall: GoogleFonts.inter(color: offWhite, fontWeight: FontWeight.w500),
        bodyLarge: GoogleFonts.inter(color: offWhite),
        bodyMedium: GoogleFonts.inter(color: offWhite),
        bodySmall: GoogleFonts.inter(color: darkSubtext),
        labelLarge: GoogleFonts.inter(color: white, fontWeight: FontWeight.w600),
        labelMedium: GoogleFonts.inter(color: darkSubtext, fontWeight: FontWeight.w500),
        labelSmall: GoogleFonts.inter(color: darkSubtext),
      ),

      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: darkBg,
        foregroundColor: white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: white,
        ),
        iconTheme: const IconThemeData(color: white),
        actionsIconTheme: const IconThemeData(color: primaryColor),
      ),

      // Card
      cardTheme: CardThemeData(
        elevation: 0,
        color: darkCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: darkBorder, width: 1),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),

      // Input fields
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: darkBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorColor, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        labelStyle: const TextStyle(color: darkSubtext),
        hintStyle: const TextStyle(color: darkSubtext),
        prefixIconColor: primaryColor,
        suffixIconColor: darkSubtext,
      ),

      // Elevated buttons → Yellow with black text
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: black,
          elevation: 0,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),

      // Outlined buttons
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: const BorderSide(color: primaryColor, width: 1.5),
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),

      // Text buttons
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),

      // FAB → Yellow
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: black,
        elevation: 4,
      ),

      // Bottom navigation bar
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: darkCard,
        indicatorColor: primaryColor.withValues(alpha: 0.2),
        surfaceTintColor: Colors.transparent,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: primaryColor,
            );
          }
          return GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: darkSubtext,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: primaryColor, size: 24);
          }
          return const IconThemeData(color: darkSubtext, size: 24);
        }),
      ),

      // Chip
      chipTheme: ChipThemeData(
        backgroundColor: darkBorder,
        selectedColor: primaryColor.withValues(alpha: 0.25),
        labelStyle: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: offWhite,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),

      // Divider
      dividerTheme: const DividerThemeData(
        color: darkBorder,
        thickness: 1,
        space: 1,
      ),

      // Switch
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primaryColor;
          return darkSubtext;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryColor.withValues(alpha: 0.3);
          }
          return darkBorder;
        }),
      ),

      // Progress indicator
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primaryColor,
      ),

      // Icon
      iconTheme: const IconThemeData(color: white, size: 24),

      // List tile
      listTileTheme: const ListTileThemeData(
        textColor: white,
        iconColor: primaryColor,
      ),

      // Snackbar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: darkCard,
        contentTextStyle: GoogleFonts.inter(color: white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: darkBorder),
        ),
      ),

      // Dialog
      dialogTheme: DialogThemeData(
        backgroundColor: darkCard,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: darkBorder),
        ),
        titleTextStyle: GoogleFonts.inter(
          color: white,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
        contentTextStyle: GoogleFonts.inter(color: darkSubtext, fontSize: 14),
      ),
    );
  }

  // ─── Light Theme (same yellow palette on white) ────────────────────────────
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,

      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        onPrimary: black,
        secondary: primaryDark,
        onSecondary: white,
        surface: white,
        onSurface: black,
        error: errorColor,
      ),

      scaffoldBackgroundColor: darkBg,

      textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme),

      appBarTheme: AppBarTheme(
        backgroundColor: darkBg,
        foregroundColor: white,
        elevation: 0,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: white,
        ),
        iconTheme: const IconThemeData(color: white),
        actionsIconTheme: const IconThemeData(color: primaryColor),
      ),

      cardTheme: CardThemeData(
        elevation: 0,
        color: darkCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: darkBorder, width: 1),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: black,
          elevation: 0,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: const BorderSide(color: primaryColor, width: 1.5),
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),

      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: black,
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: darkCard,
        indicatorColor: primaryColor.withValues(alpha: 0.2),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: primaryColor,
            );
          }
          return GoogleFonts.inter(fontSize: 12, color: darkSubtext);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: primaryColor, size: 24);
          }
          return const IconThemeData(color: darkSubtext, size: 24);
        }),
      ),
    );
  }
}
