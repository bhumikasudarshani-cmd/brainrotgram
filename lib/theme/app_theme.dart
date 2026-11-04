import 'package:flutter/material.dart';

/// BrainRotGram palette from BRAINROTGRAM.md
class AppColors {
  AppColors._();

  static const Color cream = Color(0xFFFAF5EE);
  static const Color plum = Color(0xFF30263C);
  static const Color lavender = Color(0xFFE9DFF6);
  static const Color purpleAccent = Color(0xFF684393);
  static const Color coral = Color(0xFFF0B19B);
  static const Color yellow = Color(0xFFF1D181);

  // Green and red only for right/wrong answers
  static const Color correct = Color(0xFF4CAF50);
  static const Color incorrect = Color(0xFFE53935);

  // Utility
  static const Color surface = Colors.white;
  static const Color textPrimary = plum;
  static const Color textSecondary = Color(0xFF6B5E7B);
  static const Color divider = Color(0xFFE0D8E8);
  static const Color reelBackground = Colors.black;
}

/// Font family constants
class AppFonts {
  AppFonts._();

  static const String basteleur = 'BasteleurBold';
  static const String uncutSans = 'UncutSans';
}

class AppTheme {
  AppTheme._();

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.cream,
      colorScheme: const ColorScheme.light(
        primary: AppColors.plum,
        onPrimary: AppColors.cream,
        secondary: AppColors.purpleAccent,
        onSecondary: Colors.white,
        tertiary: AppColors.coral,
        surface: AppColors.surface,
        onSurface: AppColors.plum,
        error: AppColors.incorrect,
        outline: AppColors.divider,
      ),
      fontFamily: AppFonts.uncutSans,
      textTheme: const TextTheme(
        // Wordmark & big titles — Basteleur Bold
        displayLarge: TextStyle(
          fontFamily: AppFonts.basteleur,
          fontSize: 40,
          fontWeight: FontWeight.w700,
          color: AppColors.plum,
        ),
        displayMedium: TextStyle(
          fontFamily: AppFonts.basteleur,
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: AppColors.plum,
        ),
        displaySmall: TextStyle(
          fontFamily: AppFonts.basteleur,
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: AppColors.plum,
        ),
        // Headlines — Uncut Sans Bold
        headlineLarge: TextStyle(
          fontFamily: AppFonts.uncutSans,
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: AppColors.plum,
        ),
        headlineMedium: TextStyle(
          fontFamily: AppFonts.uncutSans,
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: AppColors.plum,
        ),
        headlineSmall: TextStyle(
          fontFamily: AppFonts.uncutSans,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.plum,
        ),
        // Body
        bodyLarge: TextStyle(
          fontFamily: AppFonts.uncutSans,
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: AppColors.plum,
        ),
        bodyMedium: TextStyle(
          fontFamily: AppFonts.uncutSans,
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: AppColors.plum,
        ),
        bodySmall: TextStyle(
          fontFamily: AppFonts.uncutSans,
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: AppColors.textSecondary,
        ),
        // Labels
        labelLarge: TextStyle(
          fontFamily: AppFonts.uncutSans,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.plum,
        ),
        labelMedium: TextStyle(
          fontFamily: AppFonts.uncutSans,
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppColors.textSecondary,
        ),
        labelSmall: TextStyle(
          fontFamily: AppFonts.uncutSans,
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: AppColors.textSecondary,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.cream,
        foregroundColor: AppColors.plum,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: AppFonts.uncutSans,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.plum,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.cream,
        indicatorColor: AppColors.lavender,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: 72,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontFamily: AppFonts.uncutSans,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.purpleAccent,
            );
          }
          return const TextStyle(
            fontFamily: AppFonts.uncutSans,
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(
              color: AppColors.purpleAccent,
              size: 24,
            );
          }
          return const IconThemeData(
            color: AppColors.textSecondary,
            size: 24,
          );
        }),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.plum,
          foregroundColor: AppColors.cream,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontFamily: AppFonts.uncutSans,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 52),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          backgroundColor: AppColors.plum,
          foregroundColor: AppColors.cream,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(
              fontFamily: AppFonts.uncutSans,
              fontSize: 15,
              fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.plum,
          side: const BorderSide(color: AppColors.divider),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontFamily: AppFonts.uncutSans,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.divider, width: 1),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      chipTheme: ChipThemeData(
        color: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? AppColors.purpleAccent
                : AppColors.lavender),
        checkmarkColor: AppColors.cream,
        backgroundColor: AppColors.lavender,
        selectedColor: AppColors.purpleAccent,
        labelStyle: WidgetStateTextStyle.resolveWith((states) => TextStyle(
              fontFamily: AppFonts.uncutSans,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: states.contains(WidgetState.selected)
                  ? AppColors.cream
                  : AppColors.plum,
            )),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.purpleAccent, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: const TextStyle(
          fontFamily: AppFonts.uncutSans,
          color: AppColors.textSecondary,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 0,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.plum,
        contentTextStyle: const TextStyle(
          fontFamily: AppFonts.uncutSans,
          fontSize: 14,
          color: AppColors.cream,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
