import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/horario.dart';
import '../models/reserva.dart';
import '../models/servicio.dart';

/// Único punto de contacto con Firestore. Ninguna pantalla habla con la
/// base de datos directamente: todas pasan por aquí. Así, si algo cambia
/// en la estructura de datos, se arregla en un solo archivo.
class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ---------------------------------------------------------------------
  // SERVICIOS
  // ---------------------------------------------------------------------

  /// Los servicios activos, para que el cliente elija qué se va a cortar.
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

  /// Los días de atención. Solo vienen sábado y domingo, porque los lunes
  /// a viernes no tienen documento cargado.
  Future<List<Horario>> horarios() async {
    final snap = await _db.collection('horarios').get();
    return snap.docs
        .map((d) => Horario.fromFirestore(d.id, d.data()))
        .where((h) => h.habilitado)
        .toList();
  }

  /// Los horarios disponibles para una fecha concreta, ya en formato
  /// "HH:mm". Devuelve lista vacía si ese día no se atiende.
  Future<List<String>> slotsDisponibles(DateTime fecha) async {
    final todos = await horarios();
    final dia = fecha.weekday % 7; // DateTime: 7 = domingo → 0 = domingo

    final delDia = todos.where((h) => h.diaSemana == dia).toList();
    if (delDia.isEmpty) return [];

    final horario = delDia.first;
    final ocupadas = await _horasOcupadas(fecha, horario.diaSemana);

    final slots = <String>[];
    for (var min = horario.inicioEnMinutos;
        min + 30 <= horario.finEnMinutos;
        min += 30) {
      final hora = _aTexto(min);
      if (!ocupadas.contains(hora)) slots.add(hora);
    }
    return slots;
  }

  /// Horas ya tomadas ese día: confirmadas y pendientes cuentan. Una
  /// reserva rechazada libera su hora.
  ///
  /// Filtramos en Dart en vez de encadenar dos `where` sobre `fechaHora`,
  /// porque esa consulta exigiría un índice compuesto en Firestore.
  Future<Set<String>> _horasOcupadas(DateTime fecha, int diaSemana) async {
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

  /// Crea una reserva nueva. Siempre nace en estado `pendiente`: la regla
  /// de seguridad de Firestore rechaza cualquier otro valor.
  Future<String> crearReserva({
    required String clienteNombre,
    required String clienteEmail,
    required String clienteTelefono,
    required Servicio servicio,
    required DateTime fechaHora,
  }) async {
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
    return doc.id;
  }

  /// Todas las reservas, para el panel del barbero. Se ordenan por fecha
  /// del corte, no por cuándo se crearon.
  Stream<List<Reserva>> todasLasReservas() {
    return _db
        .collection('reservas')
        .orderBy('fechaHora')
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => Reserva.fromFirestore(d.id, d.data()))
            .toList());
  }

  /// El barbero aprueba una hora.
  Future<void> confirmarReserva(String reservaId) {
    return _db.collection('reservas').doc(reservaId).update({
      'estado': 'confirmada',
      'motivoRechazo': '',
    });
  }

  /// El barbero rechaza una hora, con el motivo.
  Future<void> rechazarReserva(String reservaId, String motivo) {
    return _db.collection('reservas').doc(reservaId).update({
      'estado': 'rechazada',
      'motivoRechazo': motivo,
    });
  }

  /// El barbero mueve una reserva a otra hora (editar horas de corte).
  Future<void> cambiarHoraReserva(String reservaId, DateTime nuevaFecha) {
    return _db.collection('reservas').doc(reservaId).update({
      'fechaHora': Timestamp.fromDate(nuevaFecha),
      'estado': 'pendiente',
      'motivoRechazo': '',
    });
  }

  // ---------------------------------------------------------------------
  // HORARIOS DEL BARBERO (editar horas de corte)
  // ---------------------------------------------------------------------

  /// El barbero cambia la hora de apertura o cierre de un día.
  Future<void> actualizarHorario({
    required String horarioId,
    required String horaInicio,
    required String horaFin,
    required bool habilitado,
  }) {
    return _db.collection('horarios').doc(horarioId).update({
      'horaInicio': horaInicio,
      'horaFin': horaFin,
      'habilitado': habilitado,
    });
  }

  // ---------------------------------------------------------------------
  // HELPERS DE FECHA
  // ---------------------------------------------------------------------

  static DateTime _inicioDelDia(DateTime f) => DateTime(f.year, f.month, f.day);

  static DateTime _inicioDelDiaSiguiente(DateTime f) =>
      DateTime(f.year, f.month, f.day).add(const Duration(days: 1));

  static String _aTexto(int minutosDesdeMedianoche) {
    final h = (minutosDesdeMedianoche ~/ 60).toString().padLeft(2, '0');
    final m = (minutosDesdeMedianoche % 60).toString().padLeft(2, '0');
    return '$h:$m';
  }
}
