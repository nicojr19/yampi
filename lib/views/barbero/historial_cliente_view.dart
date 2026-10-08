import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/historial_cliente.dart';
import '../../models/reserva.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/fondo_yampi.dart';

/// Ficha de un cliente: cuántas veces vino, cuánto ha gastado y su historial.
class HistorialClienteView extends StatefulWidget {
  final String email;

  const HistorialClienteView({super.key, required this.email});

  @override
  State<HistorialClienteView> createState() => _HistorialClienteViewState();
}

class _HistorialClienteViewState extends State<HistorialClienteView> {
  final FirestoreService _firestore = FirestoreService();

  HistorialCliente? _historial;
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final h = await _firestore.historialCliente(widget.email);
    if (!mounted) return;
    setState(() {
      _historial = h;
      _cargando = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pesos = NumberFormat.currency(
      locale: 'es_CL',
      symbol: '\$',
      decimalDigits: 0,
    );

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: const Text('Historial del cliente')),
      body: FondoYampi(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: _cargando
                ? const Center(
                    child: CircularProgressIndicator(
                      color: YampiColors.dorado,
                    ),
                  )
                : _historial == null || _historial!.reservas.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: Text(
                            'No encontramos reservas de este cliente.',
                            style: TextStyle(color: YampiColors.grisTexto),
                          ),
                        ),
                      )
                    : _contenido(_historial!, pesos),
          ),
        ),
      ),
    );
  }

  Widget _contenido(HistorialCliente h, NumberFormat pesos) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        h.nombre,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: YampiColors.negroSuave,
                        ),
                      ),
                    ),
                    if (h.esRecurrente)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: YampiColors.dorado.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: YampiColors.dorado),
                        ),
                        child: const Text(
                          'RECURRENTE',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                            color: YampiColors.doradoOscuro,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  h.email,
                  style: const TextStyle(
                    fontSize: 13,
                    color: YampiColors.grisTexto,
                  ),
                ),
                if (h.telefono.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    h.telefono,
                    style: const TextStyle(
                      fontSize: 13,
                      color: YampiColors.grisTexto,
                    ),
                  ),
                ],
                const Divider(height: 28),
                Row(
                  children: [
                    Expanded(
                      child: _Dato(
                        etiqueta: 'Visitas',
                        valor: '${h.visitas}',
                      ),
                    ),
                    Expanded(
                      child: _Dato(
                        etiqueta: 'Total gastado',
                        valor: pesos.format(h.totalGastado),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _Dato(
                        etiqueta: 'Última visita',
                        valor: h.ultimaVisitaTexto,
                      ),
                    ),
                    Expanded(
                      child: _Dato(
                        etiqueta: 'Suele pedir',
                        valor: h.servicioFavorito,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Todas sus reservas',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: YampiColors.negroSuave,
          ),
        ),
        const SizedBox(height: 12),
        ...h.reservas.map((r) => _FilaReserva(reserva: r, pesos: pesos)),
      ],
    );
  }
}

class _Dato extends StatelessWidget {
  final String etiqueta;
  final String valor;

  const _Dato({required this.etiqueta, required this.valor});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          etiqueta.toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
            letterSpacing: 1.2,
            color: YampiColors.grisTexto,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          valor,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: YampiColors.negroSuave,
          ),
        ),
      ],
    );
  }
}

class _FilaReserva extends StatelessWidget {
  final Reserva reserva;
  final NumberFormat pesos;

  const _FilaReserva({required this.reserva, required this.pesos});

  Color get _color {
    switch (reserva.estado) {
      case EstadoReserva.pendiente:
        return YampiColors.pendiente;
      case EstadoReserva.confirmada:
        return YampiColors.confirmado;
      case EstadoReserva.rechazada:
        return YampiColors.rechazado;
    }
  }

  @override
  Widget build(BuildContext context) {
    final fecha =
        DateFormat("d 'de' MMMM yyyy, HH:mm", 'es').format(reserva.fechaHora);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        child: ListTile(
          leading: Icon(Icons.content_cut, color: _color, size: 20),
          title: Text(
            fecha,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: YampiColors.negroSuave,
            ),
          ),
          subtitle: Text(
            '${reserva.servicioNombre} · ${reserva.estadoTexto}',
            style: const TextStyle(
              fontSize: 12,
              color: YampiColors.grisTexto,
            ),
          ),
          trailing: Text(
            pesos.format(reserva.precio),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: YampiColors.doradoOscuro,
            ),
          ),
        ),
      ),
    );
  }
}

