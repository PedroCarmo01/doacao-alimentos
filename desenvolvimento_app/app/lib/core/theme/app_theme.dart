import 'package:flutter/material.dart';

/// Paleta de cores do Summit.
class AppColors {
  const AppColors._();

  static const verde = Color(0xFF2E7D32);
  static const verdeClaro = Color(0xFFE8F5E9);
  static const laranja = Color(0xFFF57C00);
  static const azul = Color(0xFF1565C0);
  static const cinza = Color(0xFF757575);
  static const erro = Color(0xFFD32F2F);
  static const fundo = Color(0xFFF7F8FA);
}

/// Tema visual do app. Aplicado no MaterialApp (ver app.dart).
class AppTheme {
  const AppTheme._();

  static ThemeData get light {
    final base = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.verde,
        primary: AppColors.verde,
      ),
      scaffoldBackgroundColor: AppColors.fundo,
      useMaterial3: true,
    );

    return base.copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.verde,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.verde,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
      ),
    );
  }
}
