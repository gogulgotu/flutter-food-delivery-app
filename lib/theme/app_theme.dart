import 'package:flutter/material.dart';

/// App Theme Configuration
/// 
/// Food Delivery Platform - Fresh, Healthy, Modern Theme
/// Based on the provided color palette
class AppTheme {
  // Primary Colors
  static const Color primaryGreen = Color(0xFF4CAF50);
  static const Color primaryGreenLight = Color(0xFF66BB6A);
  static const Color primaryGreenDark = Color(0xFF388E3C);
  static const Color primaryGreenDarker = Color(0xFF2E7D32);

  // Accent Colors
  static const Color accentLeafGreen = Color(0xFF81C784);
  static const Color accentLeafGreenLight = Color(0xFFA5D6A7);
  static const Color accentYellow = Color(0xFFFFEB3B);
  static const Color accentYellowLight = Color(0xFFFFF176);
  static const Color accentYellowDark = Color(0xFFFDD835);

  // Background Colors
  static const Color bgWhite = Color(0xFFFFFFFF);
  static const Color bgOffWhite = Color(0xFFFAFAFA);
  static const Color bgLightGray = Color(0xFFF5F5F5);
  static const Color bgGray = Color(0xFFEEEEEE);
  static const Color bgSectionLight = Color(0xFFF9FBF9);
  static const Color bgSectionGreen = Color(0xFFE8F5E9);
  static const Color bgSectionYellow = Color(0xFFFFFDE7);

  // Text Colors
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF616161);
  static const Color textTertiary = Color(0xFF757575);
  static const Color textMuted = Color(0xFF9E9E9E);
  static const Color textWhite = Color(0xFFFFFFFF);

  // UI Element Colors
  static const Color borderLight = Color(0xFFE0E0E0);
  static const Color borderMedium = Color(0xFFBDBDBD);
  static const Color borderDark = Color(0xFF9E9E9E);

  // Semantic Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color successLight = Color(0xFF81C784);
  static const Color successDark = Color(0xFF388E3C);
  static const Color successBg = Color(0xFFE8F5E9);

  static const Color warning = Color(0xFFFFEB3B);
  static const Color warningLight = Color(0xFFFFF176);
  static const Color warningDark = Color(0xFFFDD835);
  static const Color warningBg = Color(0xFFFFFDE7);

  static const Color error = Color(0xFFF44336);
  static const Color errorLight = Color(0xFFE57373);
  static const Color errorDark = Color(0xFFD32F2F);
  static const Color errorBg = Color(0xFFFFEBEE);

  // Button Colors
  static const Color btnPrimaryBg = Color(0xFF4CAF50);
  static const Color btnPrimaryBgHover = Color(0xFF388E3C);
  static const Color btnPrimaryBgActive = Color(0xFF2E7D32);

  static const Color btnSecondaryBg = Color(0xFF81C784);
  static const Color btnAccentBg = Color(0xFFFFEB3B);

  // Card Colors
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color cardBorder = Color(0xFFE0E0E0);

  // Form Colors
  static const Color inputBg = Color(0xFFFFFFFF);
  static const Color inputBorder = Color(0xFFBDBDBD);
  static const Color inputBorderFocus = Color(0xFF4CAF50);
  static const Color inputPlaceholder = Color(0xFF9E9E9E);
  static const Color inputErrorBorder = Color(0xFFF44336);
  static const Color inputErrorBg = Color(0xFFFFEBEE);

  /// Get the app theme
  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.light(
        primary: primaryGreen,
        primaryContainer: primaryGreenLight,
        secondary: accentLeafGreen,
        secondaryContainer: accentLeafGreenLight,
        tertiary: accentYellow,
        surface: bgWhite,
        surfaceContainerHighest: bgOffWhite,
        background: bgOffWhite,
        error: error,
        onPrimary: textWhite,
        onSecondary: textWhite,
        onTertiary: textPrimary,
        onSurface: textPrimary,
        onBackground: textPrimary,
        onError: textWhite,
        outline: borderLight,
        outlineVariant: borderMedium,
      ),
      scaffoldBackgroundColor: bgOffWhite,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: bgWhite,
        foregroundColor: textPrimary,
        iconTheme: const IconThemeData(color: textPrimary),
        titleTextStyle: const TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        color: cardBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: cardBorder, width: 1),
        ),
        shadowColor: Colors.black.withOpacity(0.08),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: inputBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: inputBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: inputBorderFocus, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: inputErrorBorder),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: inputErrorBorder, width: 2),
        ),
        labelStyle: const TextStyle(color: textSecondary),
        hintStyle: TextStyle(color: inputPlaceholder),
        errorStyle: const TextStyle(color: error),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: btnPrimaryBg,
          foregroundColor: textWhite,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryGreen,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryGreen,
          side: const BorderSide(color: primaryGreen),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryGreen,
        foregroundColor: textWhite,
        elevation: 4,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: bgWhite,
        selectedItemColor: primaryGreen,
        unselectedItemColor: textMuted,
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.bold),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      dividerTheme: const DividerThemeData(
        color: borderLight,
        thickness: 1,
        space: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: textPrimary,
        contentTextStyle: const TextStyle(color: textWhite),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: bgLightGray,
        selectedColor: primaryGreen,
        labelStyle: const TextStyle(color: textPrimary),
        secondaryLabelStyle: const TextStyle(color: textWhite),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return primaryGreen;
          }
          return textMuted;
        }),
        trackColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return primaryGreenLight;
          }
          return bgGray;
        }),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return primaryGreen;
          }
          return Colors.transparent;
        }),
        checkColor: MaterialStateProperty.all(textWhite),
        side: const BorderSide(color: borderMedium),
      ),
      radioTheme: RadioThemeData(
        fillColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return primaryGreen;
          }
          return textMuted;
        }),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primaryGreen,
        linearTrackColor: bgLightGray,
        circularTrackColor: bgLightGray,
      ),
    );
  }
}

