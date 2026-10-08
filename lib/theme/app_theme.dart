import 'package:flutter/material.dart';

/// Paleta de Yampi adaptada para un entorno oscuro y profesional.
class YampiColors {
  // --- Fondos ---
  static const Color fondo = Color(0xFF0F0F0F);
  static const Color superficie = Color(0xFF1E1E1E);
  static const Color superficieClara = Color(0xFF2A2A2A);

  // --- Acento metálico / elegante ---
  static const Color dorado = Color(0xFF8E95A0); // Gris metálico más claro para resaltar en oscuro
  static const Color doradoOscuro = Color(0xFF4A4F57);
  static const Color doradoClaro = Color(0xFF333842); // Bordes sutiles oscuros

  static const LinearGradient degradadoDorado = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF6E747D), Color(0xFF3A3E45)],
  );

  // --- Texto ---
  static const Color negroSuave = Color(0xFFFFFFFF); // Blanco principal en modo oscuro
  static const Color grisTexto = Color(0xFF9EA4AE); // Texto secundario legible

  // --- Neutros ---
  static const Color blanco = Color(0xFFFFFFFF);
  static const Color blancoHueso = Color(0xFF1E1E1E);

  // --- Estados ---
  static const Color confirmado = Color(0xFF2E8B57);
  static const Color rechazado = Color(0xFFC0392B);
  static const Color pendiente = Color(0xFFB8860B);
}

class AppTheme {
  static ThemeData get dark {
    final base = ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      scaffoldBackgroundColor: Colors.black,
      colorScheme: const ColorScheme.dark(
        primary: YampiColors.blanco,
        onPrimary: Colors.black,
        secondary: YampiColors.dorado,
        onSecondary: Colors.white,
        surface: YampiColors.superficie,
        onSurface: YampiColors.negroSuave,
        error: YampiColors.rechazado,
        onError: YampiColors.blanco,
      ),
    );

    return base.copyWith(
      tabBarTheme: TabBarThemeData(
        labelColor: YampiColors.blanco, // Texto blanco activo y en hover
        unselectedLabelColor: YampiColors.grisTexto,
        indicatorColor: YampiColors.dorado,
        overlayColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.hovered)) {
            return YampiColors.dorado.withValues(alpha: 0.12);
          }
          if (states.contains(WidgetState.pressed)) {
            return YampiColors.dorado.withValues(alpha: 0.20);
          }
          return null;
        }),
        splashBorderRadius: BorderRadius.circular(10),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.black,
        foregroundColor: YampiColors.negroSuave,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
          color: YampiColors.negroSuave,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1E1E1E),
          foregroundColor: YampiColors.blanco,
          minimumSize: const Size.fromHeight(52),
          elevation: 4,
          side: const BorderSide(color: Colors.white24, width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: YampiColors.grisTexto,
          minimumSize: const Size.fromHeight(52),
          backgroundColor: const Color(0xFF141414).withOpacity(0.6),
          side: const BorderSide(color: Colors.white12, width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.0,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: YampiColors.superficieClara,
        labelStyle: const TextStyle(color: YampiColors.grisTexto),
        hintStyle: const TextStyle(color: YampiColors.grisTexto),
        prefixIconColor: YampiColors.dorado,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: YampiColors.doradoClaro),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Colors.white30,
            width: 1.5,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: YampiColors.superficie,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: YampiColors.doradoClaro),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: YampiColors.doradoClaro,
        thickness: 1,
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: YampiColors.superficieClara,
        contentTextStyle: TextStyle(color: YampiColors.blanco),
      ),
    );
  }
}






