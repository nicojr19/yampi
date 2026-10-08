import 'package:cloud_firestore/cloud_firestore.dart';

/// Un día completo sin atención: vacaciones, feriado, o simplemente
/// el barbero decidió no atender.
///
/// El id del documento en Firestore es la fecha en formato `2026-10-06`,
/// así que cada día existe una sola vez y buscar es directo.
class DiaBloqueado {
  /// Fecha del día cerrado, normalizada a medianoche.
  final DateTime fecha;

  /// Por qué se cerró. Puede ir vacío.
  final String motivo;

  /// Cuándo se bloqueó. Sirve para ordenar en el panel.
  final DateTime creadoEn;

  const DiaBloqueado({
    required this.fecha,
    this.motivo = '',
    required this.creadoEn,
  });

  /// Clave del documento: `2026-10-06`. Un documento por día.
  static String claveDe(DateTime fecha) {
    final y = fecha.year.toString().padLeft(4, '0');
    final m = fecha.month.toString().padLeft(2, '0');
    final d = fecha.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  factory DiaBloqueado.fromFirestore(String id, Map<String, dynamic> data) {
    return DiaBloqueado(
      fecha: DateTime.parse(id),
      motivo: data['motivo'] ?? '',
      creadoEn: _aDateTime(data['creadoEn']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'motivo': motivo,
      'creadoEn': Timestamp.fromDate(creadoEn),
    };
  }

  static DateTime _aDateTime(dynamic valor) {
    if (valor is Timestamp) return valor.toDate();
    if (valor is DateTime) return valor;
    return DateTime.now();
  }
}
