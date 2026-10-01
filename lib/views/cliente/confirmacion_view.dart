import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/servicio.dart';
import '../../theme/app_theme.dart';
import 'package:intl/intl.dart';


/// Pantalla final: le dice al cliente que su hora quedó en espera.
///
/// Es importante que diga "pendiente" y no "confirmada": el barbero todavía
/// no ha aprobado nada, y el correo de confirmación llega recién cuando lo
/// haga.
class ConfirmacionView extends StatelessWidget {
  final Servicio servicio;
  final DateTime fechaHora;
  final String emailCliente;

  const ConfirmacionView({
    super.key,
    required this.servicio,
    required this.fechaHora,
    required this.emailCliente,
  });

  @override
  Widget build(BuildContext context) {
    final fecha = DateFormat("EEEE d 'de' MMMM", 'es').format(fechaHora);
    final hora = DateFormat('HH:mm').format(fechaHora);

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 90,
                  height: 90,
                  decoration: const BoxDecoration(
                    gradient: YampiColors.degradadoDorado,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: YampiColors.blanco,
                    size: 48,
                  ),
                ),
                const SizedBox(height: 28),
                const Text(
                  '¡Reserva enviada!',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: YampiColors.negroSuave,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Tu hora quedó pendiente de confirmación.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: YampiColors.grisTexto,
                  ),
                ),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: YampiColors.blancoHueso,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: YampiColors.doradoClaro),
                  ),
                  child: Column(
                    children: [
                      _Fila(etiqueta: 'Servicio', valor: servicio.nombre),
                      const SizedBox(height: 12),
                      _Fila(etiqueta: 'Día', valor: fecha),
                      const SizedBox(height: 12),
                      _Fila(etiqueta: 'Hora', valor: '$hora hrs'),
                      const SizedBox(height: 12),
                                            _Fila(
                        etiqueta: 'Precio',
                        valor: NumberFormat.currency(
                          locale: 'es_CL',
                          symbol: '\$',
                          decimalDigits: 0,
                        ).format(servicio.precio),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: YampiColors.doradoClaro.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.mail_outline,
                        color: YampiColors.doradoOscuro,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Te avisaremos a $emailCliente cuando el barbero confirme tu hora.',
                          style: const TextStyle(
                            fontSize: 13,
                            color: YampiColors.negroSuave,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                OutlinedButton(
                  onPressed: () {
                    Navigator.popUntil(context, (route) => route.isFirst);
                  },
                  child: const Text('VOLVER AL INICIO'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Fila extends StatelessWidget {
  final String etiqueta;
  final String valor;

  const _Fila({required this.etiqueta, required this.valor});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          etiqueta,
          style: const TextStyle(
            fontSize: 14,
            color: YampiColors.grisTexto,
          ),
        ),
        Flexible(
          child: Text(
            valor,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: YampiColors.negroSuave,
            ),
          ),
        ),
      ],
    );
  }
}
