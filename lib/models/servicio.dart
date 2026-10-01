/// Representa un servicio de la barbería: corte, corte + ceja, corte + barba.
///
/// Los datos viven en la colección `servicios` de Firestore. El ID del
/// documento es el que se guarda en cada reserva, en el campo `servicioId`.
class Servicio {
  final String id;
  final String nombre;

  /// Precio en pesos chilenos, sin decimales. Se guarda crudo (8000) y se
  /// formatea como $8.000 recién al mostrarlo en pantalla.
  final int precio;

  /// Duración en minutos. El barbero demora 30, pero queda configurable.
  final int duracionMin;

  /// Si está en false, el servicio deja de aparecer a los clientes.
  final bool activo;

  const Servicio({
    required this.id,
    required this.nombre,
    required this.precio,
    required this.duracionMin,
    required this.activo,
  });

  /// Construye un Servicio desde un documento de Firestore.
  factory Servicio.fromFirestore(String id, Map<String, dynamic> data) {
    return Servicio(
      id: id,
      nombre: data['nombre'] ?? '',
      precio: (data['precio'] ?? 0).toInt(),
      duracionMin: (data['duracionMin'] ?? 30).toInt(),
      activo: data['activo'] ?? true,
    );
  }

  /// Convierte el Servicio a un mapa para guardarlo en Firestore.
  Map<String, dynamic> toFirestore() {
    return {
      'nombre': nombre,
      'precio': precio,
      'duracionMin': duracionMin,
      'activo': activo,
    };
  }
}
