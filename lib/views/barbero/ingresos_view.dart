import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/resumen_ingresos.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/fondo_yampi.dart';

enum Periodo { dia, semana, mes }

/// Módulo de ingresos: totales por día, semana y mes, con desglose diario.
class IngresosView extends StatefulWidget {
  const IngresosView({super.key});

  @override
  State<IngresosView> createState() => _IngresosViewState();
}

class _IngresosViewState extends State<IngresosView> {
  final FirestoreService _firestore = FirestoreService();

  Periodo _periodo = Periodo.mes;
  ResumenIngresos _resumen = ResumenIngresos.vacio;
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  /// Calcula el rango de fechas según el período elegido.
  (DateTime, DateTime) _rango() {
    final ahora = DateTime.now();
    final hoy = DateTime(ahora.year, ahora.month, ahora.day);

    switch (_periodo) {
      case Periodo.dia:
        return (hoy, hoy.add(const Duration(days: 1)));

      case Periodo.semana:
        // Semana que empieza el lunes.
        final lunes = hoy.subtract(Duration(days: hoy.weekday - 1));
        return (lunes, lunes.add(const Duration(days: 7)));

      case Periodo.mes:
        final primero = DateTime(ahora.year, ahora.month, 1);
        final siguiente = DateTime(ahora.year, ahora.month + 1, 1);
        return (primero, siguiente);
    }
  }

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    final (desde, hasta) = _rango();
    final resumen = await _firestore.resumenIngresos(desde, hasta);
    if (!mounted) return;
    setState(() {
      _resumen = resumen;
      _cargando = false;
    });
  }

  void _cambiarPeriodo(Periodo p) {
    setState(() => _periodo = p);
    _cargar();
  }

  @override
  Widget build(BuildContext context) {
    final pesos = NumberFormat.currency(
      locale: 'es_CL',
      symbol: '\$',
      decimalDigits: 0,
    );

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: const Text('Ingresos')),
      body: FondoYampi(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Selector de período.
                SegmentedButton<Periodo>(
                  segments: const [
                    ButtonSegment(value: Periodo.dia, label: Text('DÍA')),
                    ButtonSegment(
                      value: Periodo.semana,
                      label: Text('SEMANA'),
                    ),
                    ButtonSegment(value: Periodo.mes, label: Text('MES')),
                  ],
                  selected: {_periodo},
                  onSelectionChanged: (s) => _cambiarPeriodo(s.first),
                ),
                const SizedBox(height: 24),

                if (_cargando)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator(
                        color: YampiColors.dorado,
                      ),
                    ),
                  )
                else ...[
                  // Tarjeta grande con el total.
                  _TarjetaTotal(
                    titulo: _tituloPeriodo(),
                    total: pesos.format(_resumen.total),
                    cantidad: _resumen.cantidad,
                    promedio: pesos.format(_resumen.promedio),
                  ),
                  const SizedBox(height: 24),

                  if (_resumen.porDia.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Text(
                          'No hay cortes confirmados en este período.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: YampiColors.grisTexto),
                        ),
                      ),
                    )
                  else ...[
                    const Text(
                      'Desglose por día',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: YampiColors.negroSuave,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _GraficoBarras(resumen: _resumen, pesos: pesos),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _tituloPeriodo() {
    switch (_periodo) {
      case Periodo.dia:
        return 'Hoy';
      case Periodo.semana:
        return 'Esta semana';
      case Periodo.mes:
        return DateFormat('MMMM yyyy', 'es').format(DateTime.now());
    }
  }
}

class _TarjetaTotal extends StatelessWidget {
  final String titulo;
  final String total;
  final int cantidad;
  final String promedio;

  const _TarjetaTotal({
    required this.titulo,
    required this.total,
    required this.cantidad,
    required this.promedio,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              titulo.toUpperCase(),
              style: const TextStyle(
                fontSize: 12,
                letterSpacing: 1.5,
                color: YampiColors.grisTexto,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              total,
              style: const TextStyle(
                fontSize: 38,
                fontWeight: FontWeight.w800,
                color: YampiColors.doradoOscuro,
              ),
            ),
            const SizedBox(height: 18),
            const Divider(height: 1),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _Dato(etiqueta: 'Cortes', valor: '$cantidad'),
                ),
                Expanded(
                  child: _Dato(etiqueta: 'Promedio', valor: promedio),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Dato extends StatelessWidget {
  final String etiqueta;
  final String valor;

  const _Dato({required this.etiqueta, required this.valor});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          etiqueta.toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
            letterSpacing: 1.2,
            color: YampiColors.grisTexto,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          valor,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: YampiColors.negroSuave,
          ),
        ),
      ],
    );
  }
}

/// Gráfico de barras dibujado a mano: sin dependencias nuevas.
class _GraficoBarras extends StatelessWidget {
  final ResumenIngresos resumen;
  final NumberFormat pesos;

  const _GraficoBarras({required this.resumen, required this.pesos});

  @override
  Widget build(BuildContext context) {
    final datos = resumen.porDia;
    final maximo =
        datos.map((e) => e.value).fold<int>(0, (a, b) => a > b ? a : b);

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
        child: Column(
          children: [
            SizedBox(
              // 144 de barra + 18 del monto + 18 de la fecha + 40 de aire.
              height: 220,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: datos.map((e) {
                  // La barra más alta deja 16 px libres arriba para su monto.
                  final alto = maximo == 0 ? 0.0 : (e.value / maximo) * 144;

                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // El monto solo se muestra si la barra es alta:
                          // en barras bajas se montaría sobre la fecha.
                          if (alto > 40)
                            Text(
                              pesos.format(e.value),
                              style: const TextStyle(
                                fontSize: 10,
                                color: YampiColors.grisTexto,
                              ),
                              maxLines: 1,
                            )
                          else
                            const SizedBox(height: 13),
                          const SizedBox(height: 6),
                          Container(
                            height: alto,
                            decoration: BoxDecoration(
                              gradient: YampiColors.degradadoDorado,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(6),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            e.key,
                            style: const TextStyle(
                              fontSize: 11,
                              color: YampiColors.grisTexto,
                            ),
                            maxLines: 1,
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


