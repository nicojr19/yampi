import 'dart:ui';
import 'package:flutter/material.dart';

/// Fondo de cada pantalla: la foto de la barbería, desenfocada y oscurecida.
/// Es opaco, así que al cambiar de página no se mezcla con la anterior.
class FondoYampi extends StatelessWidget {
  final Widget child;

  const FondoYampi({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          'assets/images/fondo.png',
          fit: BoxFit.cover,
        ),
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
          child: Container(
            color: Colors.black.withValues(alpha: 0.65),
          ),
        ),
        child,
      ],
    );
  }
}
