import 'package:flutter/material.dart';

class AppColors {
  static const red = Color(0xFFE53935);
  static const redDark = Color(0xFFC62828);
  static const page = Color(0xFFF6F3F0);
  static const card = Colors.white;
  static const ink = Color(0xFF1F1F1F);
}

class AppTheme {
  static ThemeData get light {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.red,
        primary: AppColors.red,
      ),
      scaffoldBackgroundColor: AppColors.page,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.ink,
        elevation: 0,
        centerTitle: true,
      ),
      useMaterial3: true,
    );
  }
}
