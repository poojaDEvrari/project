import 'package:flutter/material.dart';
import 'package:velocity_x/velocity_x.dart';
import 'app_colors.dart';

ThemeData appTheme() {
  final base = ThemeData(brightness: Brightness.light, useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: Colors.white,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.blue,
      brightness: Brightness.light,
      primary: AppColors.blue,
      background: Colors.white,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      elevation: 0,
      centerTitle: true,
    ),
    textTheme: base.textTheme.copyWith(
      headlineMedium: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: Colors.black),
      titleLarge: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.black),
      bodyLarge: const TextStyle(fontSize: 16, color: Colors.black87),
      bodyMedium: const TextStyle(fontSize: 14, color: Colors.black87),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      selectedItemColor: AppColors.navy,
      unselectedItemColor: AppColors.gray400,
      backgroundColor: Colors.white,
      elevation: 8,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      ),
    ),
  );
}

extension Tailwind on num {
  // VelocityX offers Tailwind-like spacing, but aliases help readability
  EdgeInsets get p => EdgeInsets.all(toDouble());
}
