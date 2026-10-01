import 'package:cloud_firestore/cloud_firestore.dart';

/// Los tres estados posibles de una reserva. No hay más.
enum EstadoReserva {
  /// El cliente reservó y el barbero todavía no responde.
  pendiente,

  /// El barbero aprobó la hora.
  confirmada,

  /// El barbero no puede a esa hora.
  rechazada,
}

/// Una reserva de corte hecha por un cliente.
///
/// Vive en la colección `reservas` de Firestore. El ciclo es siempre el
/// mismo: nace `pendiente`, y el barbero la mueve a `confirmada` o a
/// `rechazada`. Nunca se crea ya confirmada — la regla de seguridad de
/// Firestore lo impide.
class Reserva {
  final String id;

  // --- Datos del cliente ---
  final String clienteNombre;
  final String clienteEmail;
  final String clienteTelefono;

  // --- Qué se va a cortar ---
  final String servicioId;
  final String servicioNombre;

  /// Precio en pesos chilenos, sin decimales. Se congela al momento de
  /// reservar: si mañana el barbero sube el precio, esta reserva mantiene
  /// el que tenía cuando se creó.
  final int precio;

  /// Fecha y hora del corte.
  final DateTime fechaHora;

  final EstadoReserva estado;

  /// Cuándo se hizo la reserva. Sirve para ordenarlas en el panel.
  final DateTime creadaEn;

  /// Si el barbero rechazó, por qué. Vacío cuando no aplica.
  final String motivoRechazo;

  const Reserva({
    required this.id,
    required this.clienteNombre,
    required this.clienteEmail,
    required this.clienteTelefono,
    required this.servicioId,
    required this.servicioNombre,
    required this.precio,
    required this.fechaHora,
    required this.estado,
    required this.creadaEn,
    this.motivoRechazo = '',
  });

  factory Reserva.fromFirestore(String id, Map<String, dynamic> data) {
    return Reserva(
      id: id,
      clienteNombre: data['clienteNombre'] ?? '',
      clienteEmail: data['clienteEmail'] ?? '',
      clienteTelefono: data['clienteTelefono'] ?? '',
      servicioId: data['servicioId'] ?? '',
      servicioNombre: data['servicioNombre'] ?? '',
      precio: (data['precio'] ?? 0).toInt(),
      fechaHora: _aDateTime(data['fechaHora']),
      estado: _estadoDesdeTexto(data['estado']),
      creadaEn: _aDateTime(data['creadaEn']),
      motivoRechazo: data['motivoRechazo'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'clienteNombre': clienteNombre,
      'clienteEmail': clienteEmail,
      'clienteTelefono': clienteTelefono,
      'servicioId': servicioId,
      'servicioNombre': servicioNombre,
      'precio': precio,
      'fechaHora': Timestamp.fromDate(fechaHora),
      'estado': estado.name,
      'creadaEn': Timestamp.fromDate(creadaEn),
      'motivoRechazo': motivoRechazo,
    };
  }

  /// Copia la reserva cambiando solo lo que se le pasa. Se usa en el panel
  /// del barbero para aprobar o rechazar sin tocar el resto de los datos.
  Reserva copyWith({
    DateTime? fechaHora,
    EstadoReserva? estado,
    String? motivoRechazo,
  }) {
    return Reserva(
      id: id,
      clienteNombre: clienteNombre,
      clienteEmail: clienteEmail,
      clienteTelefono: clienteTelefono,
      servicioId: servicioId,
      servicioNombre: servicioNombre,
      precio: precio,
      fechaHora: fechaHora ?? this.fechaHora,
      estado: estado ?? this.estado,
      creadaEn: creadaEn,
      motivoRechazo: motivoRechazo ?? this.motivoRechazo,
    );
  }

  /// Texto legible del estado, para mostrar en pantalla.
  String get estadoTexto {
    switch (estado) {
      case EstadoReserva.pendiente:
        return 'Pendiente';
      case EstadoReserva.confirmada:
        return 'Confirmada';
      case EstadoReserva.rechazada:
        return 'Rechazada';
    }
  }

  static EstadoReserva _estadoDesdeTexto(dynamic valor) {
    switch (valor) {
      case 'confirmada':
        return EstadoReserva.confirmada;
      case 'rechazada':
        return EstadoReserva.rechazada;
      default:
        return EstadoReserva.pendiente;
    }
  }

  /// Firestore devuelve las fechas como Timestamp, pero a veces llegan ya
  /// como DateTime. Este helper acepta ambos sin romperse.
  static DateTime _aDateTime(dynamic valor) {
    if (valor is Timestamp) return valor.toDate();
    if (valor is DateTime) return valor;
    return DateTime.now();
  }
}
