import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'colors.dart';

const ColorScheme _colorScheme = ColorScheme.dark(
  surfaceTint: Colors.transparent,
  primary: MyColors.primaryBlue,
  onPrimary: Colors.white,
  secondary: MyColors.primaryLightBlue,
  onSecondary: Colors.black,
  surface: MyColors.bgPrimary,
  onSurface: Colors.white,
  error: MyColors.redError,
  onError: Colors.white,
);

final TextTheme _baseTextTheme = GoogleFonts.interTextTheme().apply(
  bodyColor: Colors.white,
  displayColor: Colors.white,
);

final darkTheme = ThemeData(
  useMaterial3: false,
  applyElevationOverlayColor: false,
  brightness: Brightness.dark,
  fontFamily: GoogleFonts.inter().fontFamily,
  primaryColor: _colorScheme.primary,
  scaffoldBackgroundColor: MyColors.bgPrimary,
  canvasColor: _colorScheme.surface,
  colorScheme: _colorScheme,
  appBarTheme: AppBarTheme(
    backgroundColor: _colorScheme.surface,
    foregroundColor: _colorScheme.onSurface,
    surfaceTintColor: Colors.transparent,
    titleTextStyle: GoogleFonts.montserrat(
      fontSize: 26,
      fontWeight: FontWeight.w700,
      color: _colorScheme.onSurface,
    ),
  ),
  cardTheme: const CardThemeData(
    color: MyColors.bgSecondary,
    surfaceTintColor: Colors.transparent,
  ),
  bottomSheetTheme: const BottomSheetThemeData(
    backgroundColor: MyColors.bgSecondary,
    surfaceTintColor: Colors.transparent,
  ),
  dialogTheme: const DialogThemeData(
    backgroundColor: MyColors.bgSecondary,
    surfaceTintColor: Colors.transparent,
  ),
  navigationBarTheme: const NavigationBarThemeData(
    backgroundColor: MyColors.bgSecondary,
    surfaceTintColor: Colors.transparent,
    indicatorColor: Colors.transparent,
  ),
  textTheme: _baseTextTheme.copyWith(
    labelMedium: GoogleFonts.inter(
      fontWeight: FontWeight.w600,
      fontSize: 12,
      color: Color(0xFF003A99),
    ),
    headlineSmall: GoogleFonts.inter(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      color: MyColors.primaryLightBlue,
    ),
    titleSmall: GoogleFonts.inter(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      color: MyColors.primaryGrey,
    ),
    headlineLarge: GoogleFonts.inter(
      fontSize: 10,
      fontWeight: FontWeight.w400,
      color: MyColors.primaryGrey2,
    ),
    displaySmall: GoogleFonts.inter(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      color: MyColors.primaryBlue,
    ),
    displayLarge: GoogleFonts.montserrat(
      fontSize: 16,
      fontWeight: FontWeight.w800,
      color: MyColors.primaryGrey,
    ),
    displayMedium: GoogleFonts.inter(
      fontSize: 26,
      fontWeight: FontWeight.w700,
      color: Colors.white,
    ),
    headlineMedium: GoogleFonts.inter(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: Colors.white,
    ),
    titleLarge: GoogleFonts.montserrat(
      fontSize: 25,
      fontWeight: FontWeight.w800,
      color: MyColors.primaryBlue,
    ),
    bodyLarge: GoogleFonts.roboto(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      color: Colors.white,
    ),
    bodyMedium: GoogleFonts.inter(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      color: Colors.black,
    ),
    bodySmall: GoogleFonts.inter(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      color: Colors.white,
    ),
    labelLarge: GoogleFonts.montserrat(
      fontSize: 10,
      fontWeight: FontWeight.w800,
      color: Colors.white,
    ),
  ),
);
