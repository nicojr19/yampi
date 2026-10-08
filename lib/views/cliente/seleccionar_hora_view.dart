import 'package:flutter/material.dart';
import '../../models/dia_abierto.dart';
import '../../models/horario.dart';
import '../../models/servicio.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/fondo_yampi.dart';
import 'datos_cliente_view.dart';

/// Columnas del calendario: lunes primero, domingo al final.
const List<String> _diasSemana = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];

class SeleccionarHoraView extends StatefulWidget {
  final Servicio servicio;

  const SeleccionarHoraView({super.key, required this.servicio});

  @override
  State<SeleccionarHoraView> createState() => _SeleccionarHoraViewState();
}

class _SeleccionarHoraViewState extends State<SeleccionarHoraView> {
  final FirestoreService _firestore = FirestoreService();

  List<Horario> _horarios = [];
  Set<int> _diasAtencion = {};
  Set<String> _diasBloqueados = {};
  Map<String, DiaAbierto> _diasAbiertos = {};

  DateTime? _fechaElegida;
  String? _horaElegida;
  List<String> _slots = [];
  bool _cargandoSlots = false;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  /// Cada lectura va en su try: si una falla, las demás siguen.
  Future<void> _cargarDatos() async {
    List<Horario> horarios = [];
    Set<String> bloqueados = {};
    Map<String, DiaAbierto> abiertos = {};

    try {
      horarios = await _firestore.horarios();
    } catch (e) {
      debugPrint('>>> cargar: fallo horarios: $e');
    }
    try {
      bloqueados = await _firestore.diasBloqueadosFuturos();
    } catch (e) {
      debugPrint('>>> cargar: fallo bloqueados: $e');
    }
    try {
      abiertos = await _firestore.diasAbiertosFuturos();
    } catch (e) {
      debugPrint('>>> cargar: fallo abiertos: $e');
    }

    debugPrint('>>> cargar: horarios=${horarios.length} '
        'bloqueados=${bloqueados.length} abiertos=${abiertos.length}');
    debugPrint('>>> cargar: dias abiertos = ${abiertos.keys.toList()}');

    if (!mounted) return;
    setState(() {
      _horarios = horarios;
      _diasAtencion = horarios.map((h) => h.diaSemana).toSet();
      _diasBloqueados = bloqueados;
      _diasAbiertos = abiertos;
    });
  }

  bool _diaHabilitado(DateTime dia) {
    final hoy = DateTime.now();
    final inicioHoy = DateTime(hoy.year, hoy.month, hoy.day);
    if (dia.isBefore(inicioHoy)) return false;

    final clave = DiaAbierto.claveDe(dia);

    // Un día cerrado manda sobre todo.
    if (_diasBloqueados.contains(clave)) return false;

    // Un día abierto puntual (feriado) se habilita aunque no sea su día.
    if (_diasAbiertos.containsKey(clave)) return true;

    final diaSemana = dia.weekday % 7; // 0 = domingo, 6 = sábado
    final atencion = _diasAtencion.isEmpty ? const {6, 0} : _diasAtencion;
    return atencion.contains(diaSemana);
  }

  Future<void> _elegirFecha(DateTime fecha) async {
    setState(() {
      _fechaElegida = fecha;
      _horaElegida = null;
      _cargandoSlots = true;
      _slots = [];
    });

    final slots = await _firestore.slotsDisponibles(
      fecha,
      horariosCargados: _horarios,
      bloqueadosCargados: _diasBloqueados,
      abiertosCargados: _diasAbiertos,
    );
    if (!mounted) return;
    setState(() {
      _slots = slots;
      _cargandoSlots = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: const Text('Elige día y hora')),
      body: FondoYampi(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _Calendario(
                  fechaElegida: _fechaElegida,
                  estaHabilitado: _diaHabilitado,
                  onElegir: _elegirFecha,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Los días apagados corresponden a días sin atención.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: YampiColors.grisTexto,
                  ),
                ),
                const SizedBox(height: 24),
                if (_cargandoSlots)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(
                        color: YampiColors.dorado,
                      ),
                    ),
                  )
                else if (_fechaElegida != null && _slots.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'No quedan horas disponibles ese día.',
                        style: TextStyle(color: YampiColors.grisTexto),
                      ),
                    ),
                  )
                else if (_slots.isNotEmpty)
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    alignment: WrapAlignment.center,
                    children: _slots.map((hora) {
                      final elegida = _horaElegida == hora;
                      return ChoiceChip(
                        label: Text(hora),
                        selected: elegida,
                        onSelected: (_) =>
                            setState(() => _horaElegida = hora),
                      );
                    }).toList(),
                  ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: (_fechaElegida != null && _horaElegida != null)
                      ? () {
                          final partes = _horaElegida!.split(':');
                          final fechaHora = DateTime(
                            _fechaElegida!.year,
                            _fechaElegida!.month,
                            _fechaElegida!.day,
                            int.parse(partes[0]),
                            int.parse(partes[1]),
                          );
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DatosClienteView(
                                servicio: widget.servicio,
                                fechaHora: fechaHora,
                              ),
                            ),
                          );
                        }
                      : null,
                  child: const Text('CONTINUAR'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Calendario mensual: lunes primero, domingo al final.
class _Calendario extends StatefulWidget {
  final DateTime? fechaElegida;
  final bool Function(DateTime) estaHabilitado;
  final ValueChanged<DateTime> onElegir;

  const _Calendario({
    required this.fechaElegida,
    required this.estaHabilitado,
    required this.onElegir,
  });

  @override
  State<_Calendario> createState() => _CalendarioState();
}

class _CalendarioState extends State<_Calendario> {
  late DateTime _mesVisible;

  @override
  void initState() {
    super.initState();
    final hoy = DateTime.now();
    _mesVisible = DateTime(hoy.year, hoy.month);
  }

  @override
  Widget build(BuildContext context) {
    final primerDia = DateTime(_mesVisible.year, _mesVisible.month, 1);
    final diasEnMes = DateTime(_mesVisible.year, _mesVisible.month + 1, 0).day;

    // weekday: 1 = lunes … 7 = domingo. Semana empieza en lunes.
    final offset = primerDia.weekday - 1;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: () => setState(() {
                _mesVisible =
                    DateTime(_mesVisible.year, _mesVisible.month - 1);
              }),
            ),
            Text(
              '${_nombreMes(_mesVisible.month)} ${_mesVisible.year}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: YampiColors.negroSuave,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: () => setState(() {
                _mesVisible =
                    DateTime(_mesVisible.year, _mesVisible.month + 1);
              }),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: _diasSemana
              .map((d) => Expanded(
                    child: Center(
                      child: Text(
                        d,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: YampiColors.grisTexto,
                        ),
                      ),
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: offset + diasEnMes,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
          ),
          itemBuilder: (context, index) {
            if (index < offset) return const SizedBox.shrink();

            final dia = index - offset + 1;
            final fecha = DateTime(_mesVisible.year, _mesVisible.month, dia);
            final habilitado = widget.estaHabilitado(fecha);
            final elegido = widget.fechaElegida != null &&
                widget.fechaElegida!.year == fecha.year &&
                widget.fechaElegida!.month == fecha.month &&
                widget.fechaElegida!.day == fecha.day;

            return InkWell(
              onTap: habilitado ? () => widget.onElegir(fecha) : null,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                decoration: BoxDecoration(
                  color: elegido
                      ? YampiColors.dorado
                      : habilitado
                          ? YampiColors.superficieClara
                          : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: elegido
                        ? YampiColors.dorado
                        : YampiColors.doradoClaro,
                  ),
                ),
                child: Center(
                  child: Text(
                    '$dia',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight:
                          elegido ? FontWeight.bold : FontWeight.normal,
                      color: elegido
                          ? YampiColors.blanco
                          : habilitado
                              ? YampiColors.negroSuave
                              : YampiColors.grisTexto.withValues(alpha: 0.4),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  static String _nombreMes(int mes) {
    const meses = [
      'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
      'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre',
    ];
    return meses[mes - 1];
  }
}











