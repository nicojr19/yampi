import 'reserva.dart';

/// Resumen de la relación con un cliente.
class HistorialCliente {
  final String nombre;
  final String email;
  final String telefono;

  /// Cuántos cortes efectivos lleva (sin contar las rechazadas).
  final int visitas;

  /// Cuánto ha gastado en cortes confirmados.
  final int totalGastado;

  /// Cuándo fue su última visita efectiva.
  final DateTime? ultimaVisita;

  /// El servicio que más ha pedido.
  final String servicioFavorito;

  /// Todas sus reservas, la más reciente primero.
  final List<Reserva> reservas;

  const HistorialCliente({
    required this.nombre,
    required this.email,
    required this.telefono,
    required this.visitas,
    required this.totalGastado,
    required this.ultimaVisita,
    required this.servicioFavorito,
    required this.reservas,
  });

  /// Un cliente es "recurrente" si ya vino más de dos veces.
  bool get esRecurrente => visitas >= 3;

  /// Texto legible de la última visita.
  String get ultimaVisitaTexto {
    if (ultimaVisita == null) return 'Sin visitas';
    final d = ultimaVisita!;
    return '${d.day}/${d.month}/${d.year}';
  }
}
