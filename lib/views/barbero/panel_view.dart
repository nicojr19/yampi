import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/horario.dart';
import '../../models/reserva.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';
import 'editar_horarios_view.dart';

/// Panel del barbero: aquí ve las reservas y decide.
///
/// Las reservas llegan en vivo desde Firestore, así que cuando un cliente
/// reserva desde su celular, aparece aquí sin apretar "refrescar".
class PanelView extends StatelessWidget {
  const PanelView({super.key});

  @override
  Widget build(BuildContext context) {
    final firestore = FirestoreService();
    final auth = AuthService();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Panel del barbero'),
          actions: [
            IconButton(
              tooltip: 'Editar horarios',
              icon: const Icon(Icons.schedule),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const EditarHorariosView(),
                  ),
                );
              },
            ),
            IconButton(
              tooltip: 'Cerrar sesión',
              icon: const Icon(Icons.logout),
              onPressed: () async {
                await auth.salir();
                if (context.mounted) Navigator.pop(context);
              },
            ),
          ],
          bottom: const TabBar(
            labelColor: YampiColors.doradoOscuro,
            unselectedLabelColor: YampiColors.grisTexto,
            indicatorColor: YampiColors.dorado,
            tabs: [
              Tab(text: 'POR CONFIRMAR'),
              Tab(text: 'AGENDA'),
            ],
          ),
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: StreamBuilder<List<Reserva>>(
              stream: firestore.todasLasReservas(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: YampiColors.dorado,
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Text(
                        'No pudimos cargar las reservas.',
                        style: TextStyle(color: YampiColors.grisTexto),
                      ),
                    ),
                  );
                }

                final todas = snapshot.data ?? [];
                final pendientes = todas
                    .where((r) => r.estado == EstadoReserva.pendiente)
                    .toList();
                final agenda = todas
                    .where((r) => r.estado != EstadoReserva.pendiente)
                    .toList();

                return TabBarView(
                  children: [
                    _ListaReservas(
                      reservas: pendientes,
                      vacio: 'No hay horas por confirmar.',
                      firestore: firestore,
                    ),
                    _ListaReservas(
                      reservas: agenda,
                      vacio: 'Todavía no hay horas confirmadas ni rechazadas.',
                      firestore: firestore,
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _ListaReservas extends StatelessWidget {
  final List<Reserva> reservas;
  final String vacio;
  final FirestoreService firestore;

  const _ListaReservas({
    required this.reservas,
    required this.vacio,
    required this.firestore,
  });

  @override
  Widget build(BuildContext context) {
    if (reservas.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.inbox_outlined,
                size: 56,
                color: YampiColors.doradoClaro,
              ),
              const SizedBox(height: 16),
              Text(
                vacio,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  color: YampiColors.grisTexto,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: reservas.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (context, i) => _TarjetaReserva(
        reserva: reservas[i],
        firestore: firestore,
      ),
    );
  }
}

class _TarjetaReserva extends StatelessWidget {
  final Reserva reserva;
  final FirestoreService firestore;

  const _TarjetaReserva({required this.reserva, required this.firestore});

  Color get _colorEstado {
    switch (reserva.estado) {
      case EstadoReserva.pendiente:
        return YampiColors.pendiente;
      case EstadoReserva.confirmada:
        return YampiColors.confirmado;
      case EstadoReserva.rechazada:
        return YampiColors.rechazado;
    }
  }

  Future<void> _confirmar(BuildContext context) async {
    await firestore.confirmarReserva(reserva.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Hora de ${reserva.clienteNombre} confirmada.'),
        backgroundColor: YampiColors.confirmado,
      ),
    );
  }

  Future<void> _rechazar(BuildContext context) async {
    final motivo = await showDialog<String>(
      context: context,
      builder: (ctx) => const _DialogoRechazo(),
    );
    if (motivo == null) return;

    await firestore.rechazarReserva(reserva.id, motivo);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Hora de ${reserva.clienteNombre} rechazada.'),
        backgroundColor: YampiColors.rechazado,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pesos = NumberFormat.currency(
      locale: 'es_CL',
      symbol: '\$',
      decimalDigits: 0,
    );
    final fecha = DateFormat("EEEE d 'de' MMMM", 'es').format(reserva.fechaHora);
    final hora = DateFormat('HH:mm').format(reserva.fechaHora);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _colorEstado.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _colorEstado),
                  ),
                  child: Text(
                    reserva.estadoTexto,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: _colorEstado,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  pesos.format(reserva.precio),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: YampiColors.doradoOscuro,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              reserva.clienteNombre,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: YampiColors.negroSuave,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              reserva.servicioNombre,
              style: const TextStyle(
                fontSize: 14,
                color: YampiColors.grisTexto,
              ),
            ),
            const Divider(height: 22),
            Row(
              children: [
                const Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: YampiColors.doradoOscuro,
                ),
                const SizedBox(width: 8),
                Text(fecha, style: const TextStyle(fontSize: 13)),
                const SizedBox(width: 18),
                const Icon(
                  Icons.access_time,
                  size: 16,
                  color: YampiColors.doradoOscuro,
                ),
                const SizedBox(width: 8),
                Text(
                  hora,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(
                  Icons.mail_outline,
                  size: 16,
                  color: YampiColors.doradoOscuro,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    reserva.clienteEmail,
                    style: const TextStyle(
                      fontSize: 13,
                      color: YampiColors.grisTexto,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(
                  Icons.phone_outlined,
                  size: 16,
                  color: YampiColors.doradoOscuro,
                ),
                const SizedBox(width: 8),
                Text(
                  reserva.clienteTelefono,
                  style: const TextStyle(
                    fontSize: 13,
                    color: YampiColors.grisTexto,
                  ),
                ),
              ],
            ),
            if (reserva.estado == EstadoReserva.rechazada &&
                reserva.motivoRechazo.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: YampiColors.rechazado.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Motivo: ${reserva.motivoRechazo}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: YampiColors.rechazado,
                  ),
                ),
              ),
            ],
            if (reserva.estado == EstadoReserva.pendiente) ...[
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _confirmar(context),
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('CONFIRMAR'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: YampiColors.confirmado,
                        minimumSize: const Size(0, 44),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _rechazar(context),
                      icon: const Icon(Icons.close, size: 18),
                      label: const Text('RECHAZAR'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: YampiColors.rechazado,
                        side: const BorderSide(color: YampiColors.rechazado),
                        minimumSize: const Size(0, 44),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Pregunta el motivo antes de rechazar: el cliente lo verá en su correo.
class _DialogoRechazo extends StatefulWidget {
  const _DialogoRechazo();

  @override
  State<_DialogoRechazo> createState() => _DialogoRechazoState();
}

class _DialogoRechazoState extends State<_DialogoRechazo> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('¿Por qué rechazas esta hora?'),
      content: TextField(
        controller: _ctrl,
        maxLines: 3,
        autofocus: true,
        decoration: const InputDecoration(
          hintText: 'Ej: Ese día no puedo atender, ¿te sirve el domingo?',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('CANCELAR'),
        ),
        ElevatedButton(
          onPressed: () {
            final texto = _ctrl.text.trim();
            Navigator.pop(context, texto.isEmpty ? 'Sin motivo' : texto);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: YampiColors.rechazado,
            minimumSize: const Size(0, 44),
          ),
          child: const Text('RECHAZAR'),
        ),
      ],
    );
  }
}
