/// Resultado del cálculo de ingresos para un período.
class ResumenIngresos {
  /// Suma de los cortes confirmados del período, en pesos.
  final int total;

  /// Cuántos cortes se hicieron.
  final int cantidad;

  /// Promedio por corte. 0 si no hubo ninguno.
  final int promedio;

  /// Ingresos por día, con la clave en formato "d/m" y ordenados.
  /// Por ejemplo: [("06/10", 24000), ("07/10", 16000)].
  final List<MapEntry<String, int>> porDia;

  const ResumenIngresos({
    required this.total,
    required this.cantidad,
    required this.promedio,
    required this.porDia,
  });

  static const ResumenIngresos vacio = ResumenIngresos(
    total: 0,
    cantidad: 0,
    promedio: 0,
    porDia: [],
  );
}

