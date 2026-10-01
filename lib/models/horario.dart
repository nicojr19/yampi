/// Representa un bloque de atención de la barbería.
///
/// Solo existen dos documentos en la colección `horarios`: sábado y domingo.
/// Los lunes a viernes simplemente no tienen horario cargado, y por eso el
/// calendario los bloquea — la regla vive en los datos, no en el código.
///
/// `diaSemana` sigue la numeración de Dart: 0 = domingo, 1 = lunes, ...
/// 6 = sábado.
class Horario {
  final String id;
  final int diaSemana;

  /// Hora de apertura en formato "HH:mm", por ejemplo "10:00".
  final String horaInicio;

  /// Hora de cierre en formato "HH:mm", por ejemplo "20:00".
  final String horaFin;

  /// Si está en false, ese día deja de ofrecerse aunque siga cargado.
  final bool habilitado;

  const Horario({
    required this.id,
    required this.diaSemana,
    required this.horaInicio,
    required this.horaFin,
    required this.habilitado,
  });

  factory Horario.fromFirestore(String id, Map<String, dynamic> data) {
    return Horario(
      id: id,
      diaSemana: (data['diaSemana'] ?? 0).toInt(),
      horaInicio: data['horaInicio'] ?? '10:00',
      horaFin: data['horaFin'] ?? '23:00',
      habilitado: data['habilitado'] ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'diaSemana': diaSemana,
      'horaInicio': horaInicio,
      'horaFin': horaFin,
      'habilitado': habilitado,
    };
  }

  /// Nombre legible del día, para mostrar en pantalla.
  String get nombreDia {
    const dias = [
      'Domingo',
      'Lunes',
      'Martes',
      'Miércoles',
      'Jueves',
      'Viernes',
      'Sábado',
    ];
    return dias[diaSemana % 7];
  }

  /// Hora de inicio convertida a minutos desde medianoche.
  /// "10:30" se convierte en 630. Sirve para generar los slots.
  int get inicioEnMinutos => _aMinutos(horaInicio);

  /// Hora de cierre convertida a minutos desde medianoche.
  int get finEnMinutos => _aMinutos(horaFin);

  static int _aMinutos(String hhmm) {
    final partes = hhmm.split(':');
    if (partes.length != 2) return 0;
    final horas = int.tryParse(partes[0]) ?? 0;
    final minutos = int.tryParse(partes[1]) ?? 0;
    return horas * 60 + minutos;
  }
}
