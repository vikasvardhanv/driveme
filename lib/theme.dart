import 'package:flutter/material.dart';

/// Professional healthcare-focused theme for NEMT system
/// Using sophisticated monochrome approach with medical-blue accent

// Color palette
class AppColors {
  // Light mode colors
  static const Color lightBackground = Color(0xFFFFFFFF);
  static const Color lightSurface = Color(0xFFF8FAFC);
  static const Color lightBorder = Color(0xFFE8EDF2);
  
  // Dark mode colors  
  static const Color darkBackground = Color(0xFF0F1419);
  static const Color darkSurface = Color(0xFF1A1F26);
  static const Color darkElevated = Color(0xFF1E2430);
  static const Color darkBorder = Color(0xFF2A3340);
  
  // Accent color - Medical/Trust Blue
  static const Color primary = Color(0xFF0066CC);
  static const Color primaryDark = Color(0xFF0052A3);
  
  // Status colors
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);
  
  // Text colors
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textDisabled = Color(0xFF9CA3AF);
  
  static const Color textPrimaryDark = Color(0xFFF9FAFB);
  static const Color textSecondaryDark = Color(0xFF9CA3AF);
  static const Color textDisabledDark = Color(0xFF6B7280);
}

final ThemeData lightTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  colorScheme: ColorScheme.light(
    primary: AppColors.primary,
    onPrimary: Colors.white,
    secondary: AppColors.primary,
    onSecondary: Colors.white,
    surface: AppColors.lightSurface,
    onSurface: AppColors.textPrimary,
    error: AppColors.error,
    onError: Colors.white,
  ),
  scaffoldBackgroundColor: AppColors.lightBackground,
  
  // App Bar
  appBarTheme: AppBarTheme(
    elevation: 0,
    centerTitle: true,
    backgroundColor: AppColors.lightBackground,
    foregroundColor: AppColors.textPrimary,
    surfaceTintColor: Colors.transparent,
    titleTextStyle: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
      letterSpacing: -0.5,
    ),
    iconTheme: IconThemeData(color: AppColors.textPrimary),
  ),
  
  // Card
  cardTheme: CardThemeData(
    elevation: 0,
    color: AppColors.lightSurface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: BorderSide(color: AppColors.lightBorder, width: 1),
    ),
    margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  ),
  
  // Elevated Button
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      elevation: 0,
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
    ),
  ),
  
  // Outlined Button
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: AppColors.primary,
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      side: BorderSide(color: AppColors.primary, width: 1.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
    ),
  ),
  
  // Text Button
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: AppColors.primary,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      textStyle: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
    ),
  ),
  
  // Input Decoration
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: AppColors.lightSurface,
    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: AppColors.lightBorder),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: AppColors.lightBorder),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: AppColors.primary, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: AppColors.error),
    ),
    labelStyle: TextStyle(color: AppColors.textSecondary, fontSize: 15),
    hintStyle: TextStyle(color: AppColors.textDisabled, fontSize: 15),
  ),
  
  // Icon Theme
  iconTheme: IconThemeData(color: AppColors.textPrimary, size: 24),
  
  // Text Theme
  textTheme: TextTheme(
    displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: AppColors.textPrimary, letterSpacing: -1),
    displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w600, color: AppColors.textPrimary, letterSpacing: -0.5),
    displaySmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: AppColors.textPrimary, letterSpacing: -0.5),
    headlineLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
    headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
    headlineSmall: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
    titleLarge: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
    titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
    titleSmall: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
    bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: AppColors.textPrimary, height: 1.5),
    bodyMedium: TextStyle(fontSize: 15, fontWeight: FontWeight.w400, color: AppColors.textPrimary, height: 1.5),
    bodySmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.textSecondary, height: 1.5),
    labelLarge: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
    labelMedium: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
    labelSmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
  ),
  
  // Divider
  dividerTheme: DividerThemeData(
    color: AppColors.lightBorder,
    thickness: 1,
    space: 1,
  ),
  
  // Bottom Navigation Bar
  bottomNavigationBarTheme: BottomNavigationBarThemeData(
    backgroundColor: AppColors.lightBackground,
    selectedItemColor: AppColors.primary,
    unselectedItemColor: AppColors.textSecondary,
    type: BottomNavigationBarType.fixed,
    elevation: 8,
  ),
  
  // Chip
  chipTheme: ChipThemeData(
    backgroundColor: AppColors.lightSurface,
    selectedColor: AppColors.primary.withValues(alpha: 0.1),
    side: BorderSide(color: AppColors.lightBorder),
    labelStyle: TextStyle(color: AppColors.textPrimary, fontSize: 14),
    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
  ),
  
  // Dialog
  dialogTheme: DialogThemeData(
    backgroundColor: AppColors.lightBackground,
    elevation: 8,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  ),
);

final ThemeData darkTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  colorScheme: ColorScheme.dark(
    primary: AppColors.primary,
    onPrimary: Colors.white,
    secondary: AppColors.primary,
    onSecondary: Colors.white,
    surface: AppColors.darkSurface,
    onSurface: AppColors.textPrimaryDark,
    error: AppColors.error,
    onError: Colors.white,
  ),
  scaffoldBackgroundColor: AppColors.darkBackground,
  
  // App Bar
  appBarTheme: AppBarTheme(
    elevation: 0,
    centerTitle: true,
    backgroundColor: AppColors.darkBackground,
    foregroundColor: AppColors.textPrimaryDark,
    surfaceTintColor: Colors.transparent,
    titleTextStyle: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimaryDark,
      letterSpacing: -0.5,
    ),
    iconTheme: IconThemeData(color: AppColors.textPrimaryDark),
  ),
  
  // Card
  cardTheme: CardThemeData(
    elevation: 0,
    color: AppColors.darkSurface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: BorderSide(color: AppColors.darkBorder, width: 1),
    ),
    margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  ),
  
  // Elevated Button
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      elevation: 0,
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
    ),
  ),
  
  // Outlined Button
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: AppColors.primary,
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      side: BorderSide(color: AppColors.primary, width: 1.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
    ),
  ),
  
  // Text Button
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: AppColors.primary,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      textStyle: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
    ),
  ),
  
  // Input Decoration
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: AppColors.darkElevated,
    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: AppColors.darkBorder),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: AppColors.darkBorder),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: AppColors.primary, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: AppColors.error),
    ),
    labelStyle: TextStyle(color: AppColors.textSecondaryDark, fontSize: 15),
    hintStyle: TextStyle(color: AppColors.textDisabledDark, fontSize: 15),
  ),
  
  // Icon Theme
  iconTheme: IconThemeData(color: AppColors.textPrimaryDark, size: 24),
  
  // Text Theme
  textTheme: TextTheme(
    displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: AppColors.textPrimaryDark, letterSpacing: -1),
    displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w600, color: AppColors.textPrimaryDark, letterSpacing: -0.5),
    displaySmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: AppColors.textPrimaryDark, letterSpacing: -0.5),
    headlineLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: AppColors.textPrimaryDark),
    headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.textPrimaryDark),
    headlineSmall: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimaryDark),
    titleLarge: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.textPrimaryDark),
    titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.textPrimaryDark),
    titleSmall: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.textPrimaryDark),
    bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: AppColors.textPrimaryDark, height: 1.5),
    bodyMedium: TextStyle(fontSize: 15, fontWeight: FontWeight.w400, color: AppColors.textPrimaryDark, height: 1.5),
    bodySmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.textSecondaryDark, height: 1.5),
    labelLarge: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimaryDark),
    labelMedium: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textSecondaryDark),
    labelSmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondaryDark),
  ),
  
  // Divider
  dividerTheme: DividerThemeData(
    color: AppColors.darkBorder,
    thickness: 1,
    space: 1,
  ),
  
  // Bottom Navigation Bar
  bottomNavigationBarTheme: BottomNavigationBarThemeData(
    backgroundColor: AppColors.darkSurface,
    selectedItemColor: AppColors.primary,
    unselectedItemColor: AppColors.textSecondaryDark,
    type: BottomNavigationBarType.fixed,
    elevation: 8,
  ),
  
  // Chip
  chipTheme: ChipThemeData(
    backgroundColor: AppColors.darkElevated,
    selectedColor: AppColors.primary.withValues(alpha: 0.2),
    side: BorderSide(color: AppColors.darkBorder),
    labelStyle: TextStyle(color: AppColors.textPrimaryDark, fontSize: 14),
    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
  ),
  
  // Dialog
  dialogTheme: DialogThemeData(
    backgroundColor: AppColors.darkSurface,
    elevation: 8,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  ),
);
