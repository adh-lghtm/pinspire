import 'package:flutter/material.dart';

abstract final class PColors {
  static const background = Color(0xFF101114);
  static const surface = Color(0xFF1A1C21);
  static const elevated = Color(0xFF25282F);
  static const border = Color(0xFF32353D);
  static const text = Color(0xFFF5F1EB);
  static const muted = Color(0xFF9A9EA9);
  static const coral = Color(0xFFFF806B);
  static const sage = Color(0xFFB6CDA0);
  static const lavender = Color(0xFFC3B2E7);
}

abstract final class PinspireTheme {
  static ThemeData dark({bool oled = false}) {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: PColors.coral,
          brightness: Brightness.dark,
        ).copyWith(
          primary: PColors.coral,
          onPrimary: const Color(0xFF28120E),
          surface: PColors.surface,
          onSurface: PColors.text,
          secondary: PColors.sage,
          outline: PColors.border,
        );
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: 'PlusJakartaSans',
      colorScheme: scheme,
      scaffoldBackgroundColor: oled ? Colors.black : PColors.background,
      textTheme: ThemeData.dark().textTheme.apply(
        fontFamily: 'PlusJakartaSans',
        bodyColor: PColors.text,
        displayColor: PColors.text,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: oled ? Colors.black : PColors.background,
        surfaceTintColor: Colors.transparent,
        foregroundColor: PColors.text,
        centerTitle: false,
        titleTextStyle: const TextStyle(
          color: PColors.text,
          fontFamily: 'PlusJakartaSans',
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: PColors.coral,
          foregroundColor: const Color(0xFF261611),
          minimumSize: const Size(48, 52),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 14,
            fontFamily: 'PlusJakartaSans',
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: PColors.text,
          minimumSize: const Size(48, 50),
          side: const BorderSide(color: PColors.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: PColors.surface,
        hintStyle: const TextStyle(color: PColors.muted, fontSize: 14),
        labelStyle: const TextStyle(color: PColors.muted),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(17),
          borderSide: const BorderSide(color: PColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(17),
          borderSide: const BorderSide(color: PColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(17),
          borderSide: const BorderSide(color: PColors.coral, width: 1.5),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: PColors.surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      dialogTheme: const DialogThemeData(backgroundColor: PColors.surface),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: PColors.elevated,
        contentTextStyle: const TextStyle(
          color: PColors.text,
          fontFamily: 'PlusJakartaSans',
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      dividerTheme: const DividerThemeData(
        color: PColors.border,
        thickness: .7,
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(foregroundColor: PColors.text),
      ),
    );
  }
}
