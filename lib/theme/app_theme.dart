import 'package:flutter/material.dart';

/// Paleta de Yampi — dorado brillante sobre blanco, elegante.
class YampiColors {
  /// Dorado principal — el brillo de la marca.
  static const Color dorado = Color(0xFFD4AF37);

  /// Dorado claro — para degradados y reflejos.
  static const Color doradoClaro = Color(0xFFF4E4A6);

  /// Dorado oscuro — para textos sobre blanco y bordes.
  static const Color doradoOscuro = Color(0xFF9C7C1F);

  /// Blanco puro — fondo principal.
  static const Color blanco = Color(0xFFFFFFFF);

  /// Blanco hueso — fondo secundario, más suave que el puro.
  static const Color blancoHueso = Color(0xFFFAF8F3);

  /// Negro suave — texto principal, nunca negro puro.
  static const Color negroSuave = Color(0xFF1A1A1A);

  /// Gris — texto secundario.
  static const Color grisTexto = Color(0xFF6B6B6B);

  /// Verde — reserva confirmada.
  static const Color confirmado = Color(0xFF2E7D32);

  /// Rojo — reserva rechazada.
  static const Color rechazado = Color(0xFFC62828);

  /// Ámbar — reserva pendiente de aprobación.
  static const Color pendiente = Color(0xFFF9A825);

  /// Degradado dorado — para el logo y los botones principales.
  static const LinearGradient degradadoDorado = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [doradoClaro, dorado, doradoOscuro],
  );
}

class AppTheme {
  static ThemeData get light {
    final base = ThemeData.light(useMaterial3: true);

    return base.copyWith(
      scaffoldBackgroundColor: YampiColors.blanco,
      colorScheme: const ColorScheme.light(
        primary: YampiColors.dorado,
        onPrimary: YampiColors.blanco,
        secondary: YampiColors.doradoOscuro,
        onSecondary: YampiColors.blanco,
        surface: YampiColors.blanco,
        onSurface: YampiColors.negroSuave,
        error: YampiColors.rechazado,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: YampiColors.blanco,
        foregroundColor: YampiColors.negroSuave,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: YampiColors.doradoOscuro,
          fontSize: 22,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.5,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: YampiColors.dorado,
          foregroundColor: YampiColors.blanco,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: YampiColors.doradoOscuro,
          side: const BorderSide(color: YampiColors.dorado, width: 1.5),
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: YampiColors.blancoHueso,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: YampiColors.doradoClaro),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: YampiColors.doradoClaro),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: YampiColors.dorado, width: 2),
        ),
        labelStyle: const TextStyle(color: YampiColors.grisTexto),
      ),
      cardTheme: CardThemeData(
        color: YampiColors.blanco,
        elevation: 2,
        shadowColor: YampiColors.dorado.withValues(alpha: 0.25),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: YampiColors.doradoClaro),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: YampiColors.doradoClaro,
        thickness: 1,
      ),
    );
  }
}
