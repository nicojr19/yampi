import 'package:cloud_firestore/cloud_firestore.dart';

/// Un día que la barbería abre fuera de su horario normal: un feriado,
/// un miércoles especial, lo que sea.
///
/// El id del documento es la fecha en formato `2026-10-07`, igual que en
/// `diasBloqueados`, así que cada fecha existe una sola vez.
class DiaAbierto {
  final DateTime fecha;
  final String horaInicio;
  final String horaFin;
  final String motivo;
  final DateTime creadoEn;

  const DiaAbierto({
    required this.fecha,
    required this.horaInicio,
    required this.horaFin,
    this.motivo = '',
    required this.creadoEn,
  });

  static String claveDe(DateTime fecha) {
    final y = fecha.year.toString().padLeft(4, '0');
    final m = fecha.month.toString().padLeft(2, '0');
    final d = fecha.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  factory DiaAbierto.fromFirestore(
    String id,
    Map<String, dynamic> data,
  ) {
    return DiaAbierto(
      fecha: DateTime.parse(id),
      horaInicio: data['horaInicio'] ?? '10:00',
      horaFin: data['horaFin'] ?? '23:30',
      motivo: data['motivo'] ?? '',
      creadoEn: _aDateTime(data['creadoEn']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'horaInicio': horaInicio,
      'horaFin': horaFin,
      'motivo': motivo,
      'creadoEn': Timestamp.fromDate(creadoEn),
    };
  }
  static bool idValido(String id) => DateTime.tryParse(id) != null;

  static DateTime _aDateTime(dynamic valor) {
    if (valor is Timestamp) return valor.toDate();
    if (valor is DateTime) return valor;
    return DateTime.now();
  }
}

