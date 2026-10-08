import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/dia_abierto.dart';
import '../../models/dia_bloqueado.dart';
import '../../models/reserva.dart';
import '../../services/auth_service.dart';
import '../../services/email_service.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/fondo_yampi.dart';
import 'editar_horarios_view.dart';
import 'historial_cliente_view.dart';
import 'ingresos_view.dart';

/// Panel del barbero: aquí ve las reservas y decide.
class PanelView extends StatelessWidget {
  const PanelView({super.key});

  @override
  Widget build(BuildContext context) {
    final firestore = FirestoreService();
    final auth = AuthService();

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.black,
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
              tooltip: 'Ingresos',
              icon: const Icon(Icons.bar_chart),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const IngresosView(),
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
            tabs: [
              Tab(text: 'POR CONFIRMAR'),
              Tab(text: 'AGENDA'),
              Tab(text: 'DÍAS ESPECIALES'),
            ],
          ),
        ),
        body: FondoYampi(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: TabBarView(
                children: [
                  _TabReservas(
                    stream: firestore.todasLasReservas(),
                    filtro: (r) => r.estado == EstadoReserva.pendiente,
                    vacio: 'No hay horas por confirmar.',
                    firestore: firestore,
                  ),
                  _TabReservas(
                    stream: firestore.todasLasReservas(),
                    filtro: (r) => r.estado != EstadoReserva.pendiente,
                    vacio:
                        'Todavía no hay horas confirmadas ni rechazadas.',
                    firestore: firestore,
                  ),
                  _TabDiasEspeciales(firestore: firestore),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Una pestaña con lista de reservas, filtrada por estado.
class _TabReservas extends StatelessWidget {
  final Stream<List<Reserva>> stream;
  final bool Function(Reserva) filtro;
  final String vacio;
  final FirestoreService firestore;

  const _TabReservas({
    required this.stream,
    required this.filtro,
    required this.vacio,
    required this.firestore,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Reserva>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: YampiColors.dorado),
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

        final reservas = (snapshot.data ?? []).where(filtro).toList();
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
      },
    );
  }
}

/// Pestaña donde el barbero cierra días, abre feriados y administra ambos.
class _TabDiasEspeciales extends StatelessWidget {
  final FirestoreService firestore;

  const _TabDiasEspeciales({required this.firestore});

  Future<void> _cerrarDia(BuildContext context) async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: '¿Qué día quieres cerrar?',
    );
    if (fecha == null || !context.mounted) return;

    final motivo = await showDialog<String>(
      context: context,
      builder: (_) => const _DialogoMotivo(
        titulo: '¿Por qué cierras ese día?',
        pista: 'Ej: Vacaciones, feriado, sin atención',
        boton: 'CERRAR DÍA',
      ),
    );
    if (motivo == null) return;

    debugPrint('>>> panel: cerrando ${DateFormat('d/M/yyyy').format(fecha)}');
    await firestore.bloquearDia(fecha, motivo: motivo);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Día ${DateFormat('d/M/yyyy').format(fecha)} cerrado.',
        ),
        backgroundColor: YampiColors.rechazado,
      ),
    );
  }

  Future<void> _abrirDia(BuildContext context) async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: '¿Qué día quieres abrir?',
    );
    if (fecha == null || !context.mounted) return;

    final horas = await showDialog<Map<String, String>>(
      context: context,
      builder: (_) => const _DialogoHorasEspeciales(),
    );
    if (horas == null) return;

    debugPrint('>>> panel: abriendo ${DateFormat('d/M/yyyy').format(fecha)} '
        '${horas['horaInicio']}-${horas['horaFin']}');
    await firestore.abrirDia(
      fecha,
      horaInicio: horas['horaInicio']!,
      horaFin: horas['horaFin']!,
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Día ${DateFormat('d/M/yyyy').format(fecha)} abierto.',
        ),
        backgroundColor: YampiColors.confirmado,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        ElevatedButton.icon(
          onPressed: () => _cerrarDia(context),
          icon: const Icon(Icons.event_busy),
          label: const Text('CERRAR UN DÍA COMPLETO'),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => _abrirDia(context),
          icon: const Icon(Icons.event_available),
          label: const Text('ABRIR UN DÍA ESPECIAL'),
        ),
        const SizedBox(height: 28),
        const Text(
          'DÍAS CERRADOS',
          style: TextStyle(
            fontSize: 12,
            letterSpacing: 1.5,
            color: YampiColors.grisTexto,
          ),
        ),
        const SizedBox(height: 10),
        StreamBuilder<List<DiaBloqueado>>(
          stream: firestore.streamDiasBloqueados(),
          builder: (context, snapshot) {
            final dias = snapshot.data ?? [];
            debugPrint('>>> panel: días cerrados = ${dias.length}');
            if (dias.isEmpty) {
              return const Text(
                'No hay días cerrados.',
                style: TextStyle(
                  fontSize: 13,
                  color: YampiColors.grisTexto,
                ),
              );
            }
            return Column(
              children: dias
                  .map((d) => _FilaDia(
                        titulo: DateFormat("EEEE d 'de' MMMM", 'es')
                            .format(d.fecha),
                        detalle: d.motivo.isEmpty ? 'Sin motivo' : d.motivo,
                        icono: Icons.block,
                        color: YampiColors.rechazado,
                        onQuitar: () => firestore.desbloquearDia(d.fecha),
                      ))
                  .toList(),
            );
          },
        ),
        const SizedBox(height: 28),
        const Text(
          'DÍAS ABIERTOS ESPECIALES',
          style: TextStyle(
            fontSize: 12,
            letterSpacing: 1.5,
            color: YampiColors.grisTexto,
          ),
        ),
        const SizedBox(height: 10),
        StreamBuilder<List<DiaAbierto>>(
          stream: firestore.streamDiasAbiertos(),
          builder: (context, snapshot) {
            final dias = snapshot.data ?? [];
            debugPrint('>>> panel: días abiertos = ${dias.length}');
            if (dias.isEmpty) {
              return const Text(
                'No hay días especiales abiertos.',
                style: TextStyle(
                  fontSize: 13,
                  color: YampiColors.grisTexto,
                ),
              );
            }
            return Column(
              children: dias
                  .map((d) => _FilaDia(
                        titulo: DateFormat("EEEE d 'de' MMMM", 'es')
                            .format(d.fecha),
                        detalle: '${d.horaInicio} a ${d.horaFin}',
                        icono: Icons.event_available,
                        color: YampiColors.confirmado,
                        onQuitar: () => firestore.quitarDiaAbierto(d.fecha),
                      ))
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}

/// Una fila de día, cerrado o abierto, con su botón de quitar.
class _FilaDia extends StatelessWidget {
  final String titulo;
  final String detalle;
  final IconData icono;
  final Color color;
  final VoidCallback onQuitar;

  const _FilaDia({
    required this.titulo,
    required this.detalle,
    required this.icono,
    required this.color,
    required this.onQuitar,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        child: ListTile(
          leading: Icon(icono, color: color),
          title: Text(
            titulo,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: YampiColors.negroSuave,
            ),
          ),
          subtitle: Text(
            detalle,
            style: const TextStyle(color: YampiColors.grisTexto),
          ),
          trailing: TextButton(
            onPressed: onQuitar,
            child: const Text('QUITAR'),
          ),
        ),
      ),
    );
  }
}

/// Pregunta un motivo. Se usa para cerrar un día, rechazar o anular.
class _DialogoMotivo extends StatefulWidget {
  final String titulo;
  final String pista;
  final String boton;

  const _DialogoMotivo({
    required this.titulo,
    required this.pista,
    required this.boton,
  });

  @override
  State<_DialogoMotivo> createState() => _DialogoMotivoState();
}

class _DialogoMotivoState extends State<_DialogoMotivo> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.titulo),
      content: TextField(
        controller: _ctrl,
        maxLines: 2,
        autofocus: true,
        decoration: InputDecoration(hintText: widget.pista),
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
          child: Text(widget.boton),
        ),
      ],
    );
  }
}

/// Pide las horas de un día especial. Usa la misma grilla de 45 minutos.
class _DialogoHorasEspeciales extends StatefulWidget {
  const _DialogoHorasEspeciales();

  @override
  State<_DialogoHorasEspeciales> createState() =>
      _DialogoHorasEspecialesState();
}

class _DialogoHorasEspecialesState extends State<_DialogoHorasEspeciales> {
  TimeOfDay _inicio = const TimeOfDay(hour: 10, minute: 0);
  TimeOfDay _fin = const TimeOfDay(hour: 23, minute: 30);

  String _texto(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:'
      '${t.minute.toString().padLeft(2, '0')}';

  Future<void> _elegir(bool esInicio) async {
    final elegida = await showTimePicker(
      context: context,
      initialTime: esInicio ? _inicio : _fin,
      builder: (ctx, child) => MediaQuery(
        data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (elegida == null) return;
    setState(() {
      if (esInicio) {
        _inicio = elegida;
      } else {
        _fin = elegida;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Horario de ese día'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Apertura'),
            trailing: Text(
              _texto(_inicio),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: YampiColors.doradoOscuro,
              ),
            ),
            onTap: () => _elegir(true),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Última hora'),
            trailing: Text(
              _texto(_fin),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: YampiColors.doradoOscuro,
              ),
            ),
            onTap: () => _elegir(false),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('CANCELAR'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, {
            'horaInicio': _texto(_inicio),
            'horaFin': _texto(_fin),
          }),
          child: const Text('ABRIR DÍA'),
        ),
      ],
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
    debugPrint('>>> panel: confirmando ${reserva.clienteNombre}');
    await firestore.confirmarReserva(reserva.id);
    try {
      await EmailService.confirmarAlCliente(reserva);
    } catch (e) {
      debugPrint('>>> ERROR CORREO CONFIRMACIÓN: $e');
    }
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
      builder: (_) => const _DialogoMotivo(
        titulo: '¿Por qué rechazas esta hora?',
        pista: 'Ej: Ese día no puedo atender, ¿te sirve el domingo?',
        boton: 'RECHAZAR',
      ),
    );
    if (motivo == null) return;

    debugPrint('>>> panel: rechazando ${reserva.clienteNombre}');
    await firestore.rechazarReserva(reserva.id, motivo);
    try {
      await EmailService.rechazarAlCliente(
        reserva.copyWith(
          estado: EstadoReserva.rechazada,
          motivoRechazo: motivo,
        ),
      );
    } catch (e) {
      debugPrint('>>> ERROR CORREO RECHAZO: $e');
    }
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Hora de ${reserva.clienteNombre} rechazada.'),
        backgroundColor: YampiColors.rechazado,
      ),
    );
  }

  /// Mueve una reserva confirmada a otro día y hora.
  Future<void> _cambiarHora(BuildContext context) async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: reserva.fechaHora,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: '¿A qué día la mueves?',
    );
    if (fecha == null || !context.mounted) return;

    final hora = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(reserva.fechaHora),
      builder: (ctx, child) => MediaQuery(
        data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (hora == null) return;

    final anterior = reserva.fechaHora;
    final nueva = DateTime(
      fecha.year,
      fecha.month,
      fecha.day,
      hora.hour,
      hora.minute,
    );

    debugPrint('>>> panel: cambiando hora de ${reserva.clienteNombre} '
        'de $anterior a $nueva');

    await firestore.cambiarHoraReserva(reserva.id, nueva);

    try {
      await EmailService.avisarCambioDeHora(
        reserva.copyWith(
          fechaHora: nueva,
          estado: EstadoReserva.pendiente,
        ),
        anterior,
      );
    } catch (e) {
      debugPrint('>>> ERROR CORREO CAMBIO DE HORA: $e');
    }

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Hora cambiada. El cliente fue avisado.'),
        backgroundColor: YampiColors.confirmado,
      ),
    );
  }

  /// Anula una reserva confirmada. No se borra: queda el registro y la
  /// hora vuelve a quedar libre.
  Future<void> _anular(BuildContext context) async {
    final motivo = await showDialog<String>(
      context: context,
      builder: (_) => const _DialogoMotivo(
        titulo: '¿Por qué anulas esta reserva?',
        pista: 'Ej: Me surgió algo, ¿reagendamos?',
        boton: 'ANULAR',
      ),
    );
    if (motivo == null) return;

    debugPrint('>>> panel: anulando reserva de ${reserva.clienteNombre} '
        'motivo="$motivo"');

    await firestore.anularReserva(reserva.id, motivo);

    try {
      await EmailService.avisarAnulacion(
        reserva.copyWith(
          estado: EstadoReserva.rechazada,
          motivoRechazo: motivo,
        ),
      );
    } catch (e) {
      debugPrint('>>> ERROR CORREO ANULACIÓN: $e');
    }

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Reserva anulada. El cliente fue avisado.'),
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
    final fecha =
        DateFormat("EEEE d 'de' MMMM", 'es').format(reserva.fechaHora);
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
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => HistorialClienteView(
                      email: reserva.clienteEmail,
                    ),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        reserva.clienteNombre,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: YampiColors.negroSuave,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.history,
                      size: 18,
                      color: YampiColors.doradoOscuro,
                    ),
                  ],
                ),
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
                        side:
                            const BorderSide(color: YampiColors.rechazado),
                        minimumSize: const Size(0, 44),
                      ),
                    ),
                  ),
                ],
              ),
            ],
            if (reserva.estado == EstadoReserva.confirmada) ...[
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _cambiarHora(context),
                      icon: const Icon(Icons.schedule, size: 18),
                      label: const Text('CAMBIAR HORA'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: YampiColors.dorado,
                        side: const BorderSide(color: YampiColors.dorado),
                        minimumSize: const Size(0, 44),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _anular(context),
                      icon: const Icon(Icons.event_busy, size: 18),
                      label: const Text('ANULAR'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: YampiColors.rechazado,
                        side:
                            const BorderSide(color: YampiColors.rechazado),
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



