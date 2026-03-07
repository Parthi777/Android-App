import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Fazztrack specific colors
  static const Color primaryBlue = Color(0xFF2D60FF);
  static const Color backgroundGrey = Color(0xFFF5F7FA);
  static const Color textDark = Color(0xFF232323);
  static const Color textLight = Color(0xFF718EBF);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: backgroundGrey,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryBlue,
        primary: primaryBlue,
        background: backgroundGrey,
        surface: Colors.white,
      ),
      textTheme: GoogleFonts.interTextTheme(
        ThemeData.light().textTheme,
      ).apply(bodyColor: textDark, displayColor: textDark),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: textDark,
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        headerBackgroundColor: Colors.white,
        headerForegroundColor: textDark,
        rangePickerSurfaceTintColor:
            Colors.transparent, // Disable material tint
        rangeSelectionOverlayColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const Color(
              0xFFFF8B8B,
            ).withOpacity(0.1); // Soft Coral range background
          }
          return Colors.transparent;
        }),
        dayStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
        weekdayStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: const Color(
            0xFFFF8B8B,
          ), // Soft Coral for weekday headers to match reference
        ),
        yearStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w500),
        dayForegroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.white;
          }
          if (states.contains(WidgetState.disabled)) {
            return Colors.grey.withOpacity(0.5);
          }
          return textDark;
        }),
        todayForegroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.white;
          }
          return const Color(
            0xFFFF8B8B,
          ); // Coral text for 'today' if unselected
        }),
        dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const Color(
              0xFFFF8B8B,
            ); // Solid Soft Coral circle for selected
          }
          return Colors.transparent;
        }),
        todayBorder: const BorderSide(color: Color(0xFFFF8B8B), width: 1),
      ),
    );
  }

  static ThemeData get darkTheme {
    // Keeping dark theme simple for now, can be updated later if requested
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorSchemeSeed: primaryBlue,
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
      appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
    );
  }
}
