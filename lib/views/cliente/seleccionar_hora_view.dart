import 'package:flutter/material.dart';
import '../../models/servicio.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';
import 'datos_cliente_view.dart';


/// Paso 2 del cliente: elegir día y hora.
///
/// El calendario solo deja elegir sábado y domingo. No hay una lista de
/// días bloqueados en el código: simplemente los días que no tienen horario
/// en Firestore se ven deshabilitados. Si el barbero agrega un día desde la
/// consola, el calendario lo habilita solo.
class SeleccionarHoraView extends StatefulWidget {
  final Servicio servicio;

  const SeleccionarHoraView({super.key, required this.servicio});

  @override
  State<SeleccionarHoraView> createState() => _SeleccionarHoraViewState();
}

class _SeleccionarHoraViewState extends State<SeleccionarHoraView> {
  final FirestoreService _firestore = FirestoreService();

  /// Días que la barbería atiende: 6 = sábado, 0 = domingo.
  Set<int> _diasAtencion = {};

  DateTime? _fechaElegida;
  String? _horaElegida;
  List<String> _slots = [];
  bool _cargandoSlots = false;

  @override
  void initState() {
    super.initState();
    _cargarDiasAtencion();
  }

  /// Lee de Firestore qué días abre la barbería.
  Future<void> _cargarDiasAtencion() async {
    final horarios = await _firestore.horarios();
    if (!mounted) return;
    setState(() {
      _diasAtencion = horarios.map((h) => h.diaSemana).toSet();
    });
  }

  /// Un día es seleccionable solo si la barbería atiende ese día.
  bool _esDiaValido(DateTime dia) {
    final numeroDia = dia.weekday % 7; // DateTime: 7=dom → 0=dom
    return _diasAtencion.contains(numeroDia);
  }

    Future<void> _elegirFecha(DateTime fecha) async {
    setState(() {
      _fechaElegida = fecha;
      _horaElegida = null;
      _cargandoSlots = true;
      _slots = [];
    });

    try {
      final slots = await _firestore.slotsDisponibles(fecha);
      if (!mounted) return;
      setState(() {
        _slots = slots;
        _cargandoSlots = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _cargandoSlots = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No pudimos cargar las horas: $e'),
          backgroundColor: YampiColors.rechazado,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Elige día y hora')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _ResumenServicio(servicio: widget.servicio),
              const SizedBox(height: 24),
              const Text(
                'Días de atención',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: YampiColors.negroSuave,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Atendemos solo sábados y domingos',
                style: TextStyle(
                  fontSize: 13,
                  color: YampiColors.grisTexto,
                ),
              ),
              const SizedBox(height: 12),
              _Calendario(
                diasAtencion: _diasAtencion,
                fechaElegida: _fechaElegida,
                esDiaValido: _esDiaValido,
                onElegirFecha: _elegirFecha,
              ),
              const SizedBox(height: 24),
              if (_cargandoSlots)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(
                      color: YampiColors.dorado,
                    ),
                  ),
                )
              else if (_fechaElegida != null && _slots.isEmpty)
                _Aviso(
                  icono: Icons.event_busy,
                  texto: 'No quedan horas libres ese día.',
                )
              else if (_slots.isNotEmpty) ...[
                const Text(
                  'Horas disponibles',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: YampiColors.negroSuave,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _slots.map((hora) {
                    final elegida = hora == _horaElegida;
                    return ChoiceChip(
                      label: Text(hora),
                      selected: elegida,
                      onSelected: (_) {
                        setState(() => _horaElegida = hora);
                      },
                      selectedColor: YampiColors.dorado,
                      backgroundColor: YampiColors.blancoHueso,
                      labelStyle: TextStyle(
                        color: elegida
                            ? YampiColors.blanco
                            : YampiColors.negroSuave,
                        fontWeight:
                            elegida ? FontWeight.bold : FontWeight.normal,
                      ),
                      side: const BorderSide(color: YampiColors.doradoClaro),
                    );
                  }).toList(),
                ),
              ],
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
    );
  }
}

/// Calendario propio: en vez del DatePicker de Material, armamos una grilla
/// simple donde los días que la barbería no atiende se ven apagados y no se
/// pueden tocar. Así el cliente ve de inmediato que lunes a viernes no hay
/// atención, en lugar de descubrirlo al intentar reservar.
class _Calendario extends StatefulWidget {
  final Set<int> diasAtencion;
  final DateTime? fechaElegida;
  final bool Function(DateTime) esDiaValido;
  final void Function(DateTime) onElegirFecha;

  const _Calendario({
    required this.diasAtencion,
    required this.fechaElegida,
    required this.esDiaValido,
    required this.onElegirFecha,
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

  void _cambiarMes(int delta) {
    setState(() {
      _mesVisible = DateTime(_mesVisible.year, _mesVisible.month + delta);
    });
  }

  @override
  Widget build(BuildContext context) {
    const nombresMes = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre',
    ];
    const iniciales = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];

    final primerDia = DateTime(_mesVisible.year, _mesVisible.month, 1);
    // DateTime.weekday: lunes = 1 ... domingo = 7
    final offset = primerDia.weekday - 1;
    final diasEnMes =
        DateTime(_mesVisible.year, _mesVisible.month + 1, 0).day;
    final hoy = DateTime.now();
    final hoySinHora = DateTime(hoy.year, hoy.month, hoy.day);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () => _cambiarMes(-1),
                  icon: const Icon(Icons.chevron_left),
                  color: YampiColors.doradoOscuro,
                ),
                Text(
                  '${nombresMes[_mesVisible.month - 1]} ${_mesVisible.year}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: YampiColors.negroSuave,
                  ),
                ),
                IconButton(
                  onPressed: () => _cambiarMes(1),
                  icon: const Icon(Icons.chevron_right),
                  color: YampiColors.doradoOscuro,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: iniciales
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
            const SizedBox(height: 6),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 4,
                crossAxisSpacing: 4,
              ),
              itemCount: offset + diasEnMes,
              itemBuilder: (context, index) {
                if (index < offset) return const SizedBox.shrink();

                final dia = index - offset + 1;
                final fecha =
                    DateTime(_mesVisible.year, _mesVisible.month, dia);
                final atendido = widget.esDiaValido(fecha);
                final pasado = fecha.isBefore(hoySinHora);
                final habilitado = atendido && !pasado;
                final elegido = widget.fechaElegida != null &&
                    widget.fechaElegida!.year == fecha.year &&
                    widget.fechaElegida!.month == fecha.month &&
                    widget.fechaElegida!.day == fecha.day;

                return _CeldaDia(
                  dia: dia,
                  habilitado: habilitado,
                  elegido: elegido,
                  onTap: habilitado
                      ? () => widget.onElegirFecha(fecha)
                      : null,
                );
              },
            ),
            const SizedBox(height: 12),
            const Text(
              'Los días apagados corresponden a días sin atención.',
              style: TextStyle(
                fontSize: 11,
                color: YampiColors.grisTexto,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CeldaDia extends StatelessWidget {
  final int dia;
  final bool habilitado;
  final bool elegido;
  final VoidCallback? onTap;

  const _CeldaDia({
    required this.dia,
    required this.habilitado,
    required this.elegido,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color fondo;
    final Color texto;
    final Color borde;

    if (!habilitado) {
      fondo = Colors.transparent;
      texto = YampiColors.grisTexto.withValues(alpha: 0.35);
      borde = Colors.transparent;
    } else if (elegido) {
      fondo = YampiColors.dorado;
      texto = YampiColors.blanco;
      borde = YampiColors.doradoOscuro;
    } else {
      fondo = YampiColors.blancoHueso;
      texto = YampiColors.negroSuave;
      borde = YampiColors.doradoClaro;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        decoration: BoxDecoration(
          color: fondo,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borde),
        ),
        child: Center(
          child: Text(
            '$dia',
            style: TextStyle(
              fontSize: 14,
              color: texto,
              fontWeight: elegido ? FontWeight.bold : FontWeight.normal,
              decoration: habilitado ? null : TextDecoration.lineThrough,
            ),
          ),
        ),
      ),
    );
  }
}

class _ResumenServicio extends StatelessWidget {
  final Servicio servicio;

  const _ResumenServicio({required this.servicio});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: YampiColors.degradadoDorado,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.content_cut, color: YampiColors.blanco),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              servicio.nombre,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: YampiColors.blanco,
              ),
            ),
          ),
          Text(
            '\$${servicio.precio}',
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: YampiColors.blanco,
            ),
          ),
        ],
      ),
    );
  }
}

class _Aviso extends StatelessWidget {
  final IconData icono;
  final String texto;

  const _Aviso({required this.icono, required this.texto});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: YampiColors.blancoHueso,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: YampiColors.doradoClaro),
      ),
      child: Row(
        children: [
          Icon(icono, color: YampiColors.doradoOscuro),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              texto,
              style: const TextStyle(
                fontSize: 14,
                color: YampiColors.grisTexto,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
