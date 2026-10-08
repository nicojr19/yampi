/// Representa un bloque de atención de la barbería.
///
/// Solo existen dos documentos en la colección `horarios`: sábado y domingo.
///
/// `diaSemana` sigue la numeración de Dart: 0 = domingo, 1 = lunes, ...
/// 6 = sábado.
class Horario {
  final String id;
  final int diaSemana;
  final String horaInicio;
  final String horaFin;
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
      diaSemana: _aInt(data['diaSemana']),
      horaInicio: _aTexto(data['horaInicio'], '10:00'),
      horaFin: _aTexto(data['horaFin'], '23:00'),
      habilitado: _aBool(data['habilitado']),
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

  int get inicioEnMinutos => _aMinutos(horaInicio);
  int get finEnMinutos => _aMinutos(horaFin);

  static int _aMinutos(String hhmm) {
    final partes = hhmm.split(':');
    if (partes.length != 2) return 0;
    final horas = int.tryParse(partes[0]) ?? 0;
    final minutos = int.tryParse(partes[1]) ?? 0;
    return horas * 60 + minutos;
  }

  // --- Conversores tolerantes ---
  // Firestore puede devolver un número como int, double o texto.
  // Estos helpers aceptan los tres casos sin lanzar excepción.

  static int _aInt(dynamic valor) {
    if (valor is int) return valor;
    if (valor is double) return valor.toInt();
    if (valor is String) return int.tryParse(valor) ?? 0;
    return 0;
  }

  static String _aTexto(dynamic valor, String porDefecto) {
    if (valor is String && valor.isNotEmpty) return valor;
    return porDefecto;
  }

  static bool _aBool(dynamic valor) {
    if (valor is bool) return valor;
    if (valor is String) return valor.toLowerCase() == 'true';
    if (valor is int) return valor != 0;
    return true;
  }
}

