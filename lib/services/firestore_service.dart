import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/dia_abierto.dart';
import '../models/dia_bloqueado.dart';
import '../models/historial_cliente.dart';
import '../models/horario.dart';
import '../models/reserva.dart';
import '../models/resumen_ingresos.dart';
import '../models/servicio.dart';

/// Único punto de contacto con Firestore.
class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Duración de cada franja de atención, en minutos.
  static const int _minutosPorFranja = 45;

  // ---------------------------------------------------------------------
  // SERVICIOS
  // ---------------------------------------------------------------------

  Stream<List<Servicio>> servicios() {
    return _db
        .collection('servicios')
        .where('activo', isEqualTo: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => Servicio.fromFirestore(d.id, d.data()))
            .toList());
  }

  // ---------------------------------------------------------------------
  // HORARIOS
  // ---------------------------------------------------------------------

  /// Los días de atención de la barbería.
  Future<List<Horario>> horarios() async {
    final snap = await _db.collection('horarios').get();
    debugPrint('>>> horarios: docs = ${snap.docs.length}');

    final lista = snap.docs
        .map((d) => Horario.fromFirestore(d.id, d.data()))
        .toList();

    debugPrint('>>> horarios: dias = '
        '${lista.map((h) => h.diaSemana).toList()}');
    debugPrint('>>> horarios: habilitado = '
        '${lista.map((h) => h.habilitado).toList()}');
    debugPrint('>>> horarios: horas = '
        '${lista.map((h) => "${h.horaInicio}-${h.horaFin}").toList()}');

    return lista.where((h) => h.habilitado).toList();
  }

  /// Los horarios disponibles para una fecha concreta, en formato "HH:mm".
  ///
  /// Orden de prioridad:
  ///   1. Si el día está bloqueado, no hay nada.
  ///   2. Si es un día abierto puntual (un feriado), se usan sus horas.
  ///   3. Si no, se usa el horario de la semana (sábado o domingo).
  ///
  /// Cada lectura va en su propio try: si una falla por permisos, el
  /// cálculo sigue con las demás en vez de dejar la pantalla vacía.
  Future<List<String>> slotsDisponibles(
    DateTime fecha, {
    List<Horario>? horariosCargados,
    Set<String>? bloqueadosCargados,
    Map<String, DiaAbierto>? abiertosCargados,
  }) async {
    final clave = DiaAbierto.claveDe(fecha);
    debugPrint('>>> slots: consultando $clave');

    // --- Días bloqueados ---
    Set<String> bloqueados = {};
    try {
      bloqueados = (bloqueadosCargados == null || bloqueadosCargados.isEmpty)
          ? await diasBloqueadosFuturos()
          : bloqueadosCargados;
    } catch (e) {
      debugPrint('>>> slots: no se pudieron leer los bloqueados: $e');
    }

    if (bloqueados.contains(clave)) {
      debugPrint('>>> slots: el día está bloqueado');
      return [];
    }

    // --- Días abiertos puntuales ---
    Map<String, DiaAbierto> abiertos = {};
    try {
      abiertos = (abiertosCargados == null || abiertosCargados.isEmpty)
          ? await diasAbiertosFuturos()
          : abiertosCargados;
    } catch (e) {
      debugPrint('>>> slots: no se pudieron leer los abiertos: $e');
    }

    debugPrint('>>> slots: bloqueados=${bloqueados.length} '
        'abiertos=${abiertos.length}');

    // --- Horas de ese día ---
    int inicio;
    int fin;

    final abierto = abiertos[clave];
    if (abierto != null) {
      inicio = _aMinutos(abierto.horaInicio);
      fin = _aMinutos(abierto.horaFin);
      debugPrint('>>> slots: día abierto ${abierto.horaInicio}-${abierto.horaFin}');
    } else {
      List<Horario> todos = [];
      try {
        todos = (horariosCargados == null || horariosCargados.isEmpty)
            ? await horarios()
            : horariosCargados;
      } catch (e) {
        debugPrint('>>> slots: no se pudieron leer los horarios: $e');
      }

      final dia = fecha.weekday % 7; // 0 = domingo, 6 = sábado
      debugPrint('>>> slots: sin día abierto, uso el día $dia');

      final delDia = todos.where((h) => h.diaSemana == dia).toList();
      if (delDia.isEmpty) {
        debugPrint('>>> slots: no hay horario para el día $dia');
        return [];
      }
      inicio = delDia.first.inicioEnMinutos;
      fin = delDia.first.finEnMinutos;
    }

    // --- Horas ocupadas ---
    Set<String> ocupadas = {};
    try {
      ocupadas = await _horasOcupadas(fecha);
    } catch (e) {
      debugPrint('>>> slots: no se pudieron leer las reservas: $e');
    }
    debugPrint('>>> slots: ocupadas=$ocupadas');

    final slots = <String>[];
    for (var min = inicio; min <= fin; min += _minutosPorFranja) {
      final hora = _aTexto(min);
      if (!ocupadas.contains(hora)) slots.add(hora);
    }

    debugPrint('>>> slots: generados=${slots.length}');
    return slots;
  }

  /// Horas ya tomadas ese día. Una reserva rechazada libera su hora.
  Future<Set<String>> _horasOcupadas(DateTime fecha) async {
    final snap = await _db.collection('reservas').get();

    return snap.docs
        .map((d) => Reserva.fromFirestore(d.id, d.data()))
        .where((r) =>
            r.estado != EstadoReserva.rechazada &&
            r.fechaHora.year == fecha.year &&
            r.fechaHora.month == fecha.month &&
            r.fechaHora.day == fecha.day)
        .map((r) => _aTexto(r.fechaHora.hour * 60 + r.fechaHora.minute))
        .toSet();
  }

  // ---------------------------------------------------------------------
  // RESERVAS
  // ---------------------------------------------------------------------

  Future<String> crearReserva({
    required String clienteNombre,
    required String clienteEmail,
    required String clienteTelefono,
    required Servicio servicio,
    required DateTime fechaHora,
  }) async {
    debugPrint('>>> crearReserva: ${servicio.nombre} para $fechaHora');
    final doc = await _db.collection('reservas').add({
      'clienteNombre': clienteNombre,
      'clienteEmail': clienteEmail,
      'clienteTelefono': clienteTelefono,
      'servicioId': servicio.id,
      'servicioNombre': servicio.nombre,
      'precio': servicio.precio,
      'fechaHora': Timestamp.fromDate(fechaHora),
      'estado': 'pendiente',
      'creadaEn': Timestamp.fromDate(DateTime.now()),
      'motivoRechazo': '',
    });
    debugPrint('>>> crearReserva: guardada con id ${doc.id}');
    return doc.id;
  }

  Stream<List<Reserva>> todasLasReservas() {
    return _db
        .collection('reservas')
        .orderBy('fechaHora')
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => Reserva.fromFirestore(d.id, d.data()))
            .toList());
  }

  Future<void> confirmarReserva(String reservaId) {
    debugPrint('>>> confirmarReserva: $reservaId');
    return _db.collection('reservas').doc(reservaId).update({
      'estado': 'confirmada',
      'motivoRechazo': '',
    });
  }

  Future<void> rechazarReserva(String reservaId, String motivo) {
    debugPrint('>>> rechazarReserva: $reservaId motivo="$motivo"');
    return _db.collection('reservas').doc(reservaId).update({
      'estado': 'rechazada',
      'motivoRechazo': motivo,
    });
  }

  /// El barbero mueve una reserva a otra hora. Vuelve a quedar pendiente.
  Future<void> cambiarHoraReserva(String reservaId, DateTime nuevaFecha) {
    debugPrint('>>> cambiarHoraReserva: $reservaId -> $nuevaFecha');
    return _db.collection('reservas').doc(reservaId).update({
      'fechaHora': Timestamp.fromDate(nuevaFecha),
      'estado': 'pendiente',
      'motivoRechazo': '',
    });
  }

  /// El barbero anula una reserva ya confirmada. No se borra: queda el
  /// registro con estado `rechazada` y la hora vuelve a quedar libre.
  Future<void> anularReserva(String reservaId, String motivo) {
    debugPrint('>>> anularReserva: $reservaId motivo="$motivo"');
    return _db.collection('reservas').doc(reservaId).update({
      'estado': 'rechazada',
      'motivoRechazo': motivo,
    });
  }

  // ---------------------------------------------------------------------
  // HORARIOS DEL BARBERO
  // ---------------------------------------------------------------------

  Future<void> actualizarHorario({
    required String horarioId,
    required String horaInicio,
    required String horaFin,
    required bool habilitado,
  }) {
    debugPrint('>>> actualizarHorario: $horarioId '
        '$horaInicio-$horaFin habilitado=$habilitado');
    return _db.collection('horarios').doc(horarioId).update({
      'horaInicio': horaInicio,
      'horaFin': horaFin,
      'habilitado': habilitado,
    });
  }

  // ---------------------------------------------------------------------
  // DÍAS BLOQUEADOS
  // ---------------------------------------------------------------------

  Future<void> bloquearDia(DateTime fecha, {String motivo = ''}) async {
    final clave = DiaBloqueado.claveDe(fecha);
    debugPrint('>>> bloquearDia: $clave motivo="$motivo"');
    await _db.collection('diasBloqueados').doc(clave).set({
      'motivo': motivo,
      'creadoEn': FieldValue.serverTimestamp(),
    });
    debugPrint('>>> bloquearDia: guardado');
  }

  Future<void> desbloquearDia(DateTime fecha) async {
    final clave = DiaBloqueado.claveDe(fecha);
    debugPrint('>>> desbloquearDia: $clave');
    await _db.collection('diasBloqueados').doc(clave).delete();
    debugPrint('>>> desbloquearDia: eliminado');
  }

  Future<Set<String>> diasBloqueadosFuturos() async {
    final hoy = DateTime.now();
    final desde = DiaBloqueado.claveDe(hoy);
    final snap = await _db
        .collection('diasBloqueados')
        .where(FieldPath.documentId, isGreaterThanOrEqualTo: desde)
        .get();
    debugPrint('>>> diasBloqueadosFuturos: ${snap.docs.length} días');
    return snap.docs.map((d) => d.id).toSet();
  }

  Stream<List<DiaBloqueado>> streamDiasBloqueados() {
    return _db
        .collection('diasBloqueados')
        .orderBy(FieldPath.documentId)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => DiaBloqueado.fromFirestore(d.id, d.data()))
            .toList());
  }

  // ---------------------------------------------------------------------
  // DÍAS ABIERTOS PUNTUALES (feriados y días especiales)
  // ---------------------------------------------------------------------

  /// Abre una fecha que normalmente no se atiende.
  Future<void> abrirDia(
    DateTime fecha, {
    required String horaInicio,
    required String horaFin,
    String motivo = '',
  }) async {
    final clave = DiaAbierto.claveDe(fecha);
    debugPrint('>>> abrirDia: $clave de $horaInicio a $horaFin');
    await _db.collection('diasAbiertos').doc(clave).set({
      'horaInicio': horaInicio,
      'horaFin': horaFin,
      'motivo': motivo,
      'creadoEn': FieldValue.serverTimestamp(),
    });
    debugPrint('>>> abrirDia: guardado');
  }

  /// Cierra un día abierto: esa fecha vuelve a su horario normal.
  Future<void> quitarDiaAbierto(DateTime fecha) async {
    final clave = DiaAbierto.claveDe(fecha);
    debugPrint('>>> quitarDiaAbierto: $clave');
    await _db.collection('diasAbiertos').doc(clave).delete();
    debugPrint('>>> quitarDiaAbierto: eliminado');
  }

  /// Los días abiertos desde hoy en adelante, indexados por su clave.
  Future<Map<String, DiaAbierto>> diasAbiertosFuturos() async {
    final hoy = DateTime.now();
    final desde = DiaAbierto.claveDe(hoy);
    final snap = await _db
        .collection('diasAbiertos')
        .where(FieldPath.documentId, isGreaterThanOrEqualTo: desde)
        .get();
    debugPrint('>>> diasAbiertosFuturos: ${snap.docs.length} días');
    return {
      for (final d in snap.docs)
        if (DiaAbierto.idValido(d.id))
          d.id: DiaAbierto.fromFirestore(d.id, d.data()),
    };
  }

  Stream<List<DiaAbierto>> streamDiasAbiertos() {
    return _db
        .collection('diasAbiertos')
        .orderBy(FieldPath.documentId)
        .snapshots()
        .map((snap) => snap.docs
            .where((d) => DiaAbierto.idValido(d.id))
            .map((d) => DiaAbierto.fromFirestore(d.id, d.data()))
            .toList());
  }

  // ---------------------------------------------------------------------
  // HELPERS
  // ---------------------------------------------------------------------

  static String _aTexto(int minutosDesdeMedianoche) {
    final h = (minutosDesdeMedianoche ~/ 60).toString().padLeft(2, '0');
    final m = (minutosDesdeMedianoche % 60).toString().padLeft(2, '0');
    return '$h:$m';
  }

  static int _aMinutos(String hhmm) {
    final partes = hhmm.split(':');
    if (partes.length != 2) return 0;
    final h = int.tryParse(partes[0]) ?? 0;
    final m = int.tryParse(partes[1]) ?? 0;
    return h * 60 + m;
  }

  // ---------------------------------------------------------------------
  // INGRESOS
  // ---------------------------------------------------------------------

  Future<List<Reserva>> reservasConfirmadas() async {
    final snap = await _db.collection('reservas').get();
    return snap.docs
        .map((d) => Reserva.fromFirestore(d.id, d.data()))
        .where((r) => r.estado == EstadoReserva.confirmada)
        .toList();
  }

  Future<ResumenIngresos> resumenIngresos(
    DateTime desde,
    DateTime hasta,
  ) async {
    final todas = await reservasConfirmadas();
    debugPrint('>>> resumenIngresos: ${todas.length} confirmadas');

    final enRango = todas.where((r) {
      final f = r.fechaHora;
      return !f.isBefore(desde) && !f.isAfter(hasta);
    }).toList();

    final total = enRango.fold<int>(0, (suma, r) => suma + r.precio);
    final cantidad = enRango.length;
    final promedio = cantidad == 0 ? 0 : total ~/ cantidad;

    debugPrint('>>> resumenIngresos: $cantidad cortes, total \$$total');

    final mapa = <String, int>{};
    for (final r in enRango) {
      final f = r.fechaHora;
      final clave = '${f.year}'
          '${f.month.toString().padLeft(2, '0')}'
          '${f.day.toString().padLeft(2, '0')}';
      mapa[clave] = (mapa[clave] ?? 0) + r.precio;
    }

    final claves = mapa.keys.toList()..sort();
    final porDia = claves.map((k) {
      final d = '${k.substring(6, 8)}/${k.substring(4, 6)}';
      return MapEntry(d, mapa[k]!);
    }).toList();

    return ResumenIngresos(
      total: total,
      cantidad: cantidad,
      promedio: promedio,
      porDia: porDia,
    );
  }

  // ---------------------------------------------------------------------
  // HISTORIAL DEL CLIENTE
  // ---------------------------------------------------------------------

  Future<List<Reserva>> reservasDeCliente(String email) async {
    final snap = await _db.collection('reservas').get();
    final correo = email.trim().toLowerCase();

    final suyas = snap.docs
        .map((d) => Reserva.fromFirestore(d.id, d.data()))
        .where((r) => r.clienteEmail.trim().toLowerCase() == correo)
        .toList();

    debugPrint('>>> reservasDeCliente: $correo tiene ${suyas.length}');
    suyas.sort((a, b) => b.fechaHora.compareTo(a.fechaHora));
    return suyas;
  }

  Future<HistorialCliente> historialCliente(String email) async {
    final suyas = await reservasDeCliente(email);

    final validas =
        suyas.where((r) => r.estado != EstadoReserva.rechazada).toList();

    final total = validas
        .where((r) => r.estado == EstadoReserva.confirmada)
        .fold<int>(0, (suma, r) => suma + r.precio);

    final conteo = <String, int>{};
    for (final r in validas) {
      conteo[r.servicioNombre] = (conteo[r.servicioNombre] ?? 0) + 1;
    }
    String favorito = '';
    var maximo = 0;
    conteo.forEach((nombre, veces) {
      if (veces > maximo) {
        maximo = veces;
        favorito = nombre;
      }
    });

    debugPrint('>>> historialCliente: ${validas.length} visitas, '
        'total \$$total');

    return HistorialCliente(
      nombre: suyas.isEmpty ? '' : suyas.first.clienteNombre,
      email: email,
      telefono: suyas.isEmpty ? '' : suyas.first.clienteTelefono,
      visitas: validas.length,
      totalGastado: total,
      ultimaVisita: validas.isEmpty ? null : validas.first.fechaHora,
      servicioFavorito: favorito.isEmpty ? '—' : favorito,
      reservas: suyas,
    );
  }
}







