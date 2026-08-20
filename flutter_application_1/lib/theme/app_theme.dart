import 'package:flutter/material.dart';

/// App Colors configuration
class AppColors {
  // Primary cobalt blue color requested (#0047AB)
  static const Color primary = Color(0xFF0047AB);
  static const Color primaryLight = Color(0xFF336BBD);
  static const Color primaryDark = Color(0xFF003178);

  // Accent & Neutral colors
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Colors.white;
  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color inputBorder = Color(0xFFCBD5E1);
  static const Color error = Color(0xFFEF4444);
}

/// Centralized ThemeData for the application
class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      fontFamily: 'PhetsarathOT',
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        onPrimary: Colors.white,
        secondary: AppColors.primaryLight,
        // # ເຮັດຫຍັງ: ຕັດ background ອອກຈາກ ColorScheme
        // # ຍ້ອນຫຍັງ: ColorScheme.background ຖືກ deprecate ຫຼັງ Flutter 3.18 ໃຫ້ໃຊ້
        // #          surface ແທນ ແລະ ບັນທັດຖັດໄປກຳນົດ surface ໄວ້ຢູ່ແລ້ວ
        // #          ຈຶ່ງເປັນການກຳນົດຊ້ຳທີ່ບໍ່ມີຜົນ
        // # ແກ້ຈາກສ່ວນໃດ: ColorScheme.light(...) ທີ່ມີທັງ background ແລະ surface
        // # ແກ້ເຮັດຫຍັງ: ສີພື້ນຫຼັງຍັງມາຈາກ scaffoldBackgroundColor ດ້ານລຸ່ມຄືເກົ່າ
        surface: AppColors.surface,
      ),
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(0, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.inputBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.inputBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        hintStyle: const TextStyle(color: AppColors.textSecondary),
      ),
    );
  }
}
