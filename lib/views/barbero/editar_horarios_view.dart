import 'package:flutter/material.dart';
import '../../models/horario.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/fondo_yampi.dart';

/// El barbero ajusta sus horas de atención: apertura, cierre y si el día
/// queda habilitado o no. Los cambios se guardan en Firestore y el
/// calendario del cliente los toma automáticamente.
class EditarHorariosView extends StatefulWidget {
  const EditarHorariosView({super.key});

  @override
  State<EditarHorariosView> createState() => _EditarHorariosViewState();
}

class _EditarHorariosViewState extends State<EditarHorariosView> {
  final FirestoreService _firestore = FirestoreService();
  List<Horario> _horarios = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final lista = await _firestore.horarios();
    if (!mounted) return;
    setState(() {
      _horarios = lista;
      _cargando = false;
    });
  }

  Future<void> _editar(Horario horario) async {
    final resultado = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _DialogoHorario(horario: horario),
    );
    if (resultado == null) return;

    await _firestore.actualizarHorario(
      horarioId: horario.id,
      horaInicio: resultado['horaInicio'],
      horaFin: resultado['horaFin'],
      habilitado: resultado['habilitado'],
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${horario.nombreDia} actualizado.'),
        backgroundColor: YampiColors.confirmado,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: const Text('Mis horarios')),
      body: FondoYampi(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: _cargando
                ? const Center(
                    child: CircularProgressIndicator(
                      color: YampiColors.dorado,
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      const Text(
                        'Días de atención',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: YampiColors.negroSuave,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Cambia las horas y el calendario de los clientes '
                        'se ajusta solo.',
                        style: TextStyle(
                          fontSize: 13,
                          color: YampiColors.grisTexto,
                        ),
                      ),
                      const SizedBox(height: 20),
                      ..._horarios.map(
                        (h) => Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: _TarjetaHorario(
                            horario: h,
                            onEditar: () => _editar(h),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _TarjetaHorario extends StatelessWidget {
  final Horario horario;
  final VoidCallback onEditar;

  const _TarjetaHorario({required this.horario, required this.onEditar});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: horario.habilitado
                ? YampiColors.doradoClaro
                : YampiColors.blancoHueso,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.schedule,
            color: YampiColors.doradoOscuro,
            size: 22,
          ),
        ),
        title: Text(
          horario.nombreDia,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: YampiColors.negroSuave,
          ),
        ),
        subtitle: Text(
          horario.habilitado
              ? '${horario.horaInicio} a ${horario.horaFin}'
              : 'Cerrado',
          style: TextStyle(
            fontSize: 13,
            color: horario.habilitado
                ? YampiColors.grisTexto
                : YampiColors.rechazado,
          ),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.edit, color: YampiColors.doradoOscuro),
          onPressed: onEditar,
        ),
      ),
    );
  }
}

class _DialogoHorario extends StatefulWidget {
  final Horario horario;

  const _DialogoHorario({required this.horario});

  @override
  State<_DialogoHorario> createState() => _DialogoHorarioState();
}

class _DialogoHorarioState extends State<_DialogoHorario> {
  late String _inicio;
  late String _fin;
  late bool _habilitado;

  @override
  void initState() {
    super.initState();
    _inicio = widget.horario.horaInicio;
    _fin = widget.horario.horaFin;
    _habilitado = widget.horario.habilitado;
  }

  Future<void> _elegirHora(bool esInicio) async {
    final actual = esInicio ? _inicio : _fin;
    final partes = actual.split(':');
    final inicial = TimeOfDay(
      hour: int.tryParse(partes[0]) ?? 10,
      minute: int.tryParse(partes.length > 1 ? partes[1] : '0') ?? 0,
    );

    final elegida = await showTimePicker(
      context: context,
      initialTime: inicial,
      builder: (ctx, child) => MediaQuery(
        data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (elegida == null) return;

    final hh = elegida.hour.toString().padLeft(2, '0');
    final mm = elegida.minute.toString().padLeft(2, '0');
    setState(() {
      if (esInicio) {
        _inicio = '$hh:$mm';
      } else {
        _fin = '$hh:$mm';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Horario de ${widget.horario.nombreDia}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Atender este día'),
            value: _habilitado,
            activeThumbColor: YampiColors.dorado,
            onChanged: (v) => setState(() => _habilitado = v),
          ),
          const SizedBox(height: 8),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Apertura'),
            trailing: Text(
              _inicio,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: YampiColors.doradoOscuro,
              ),
            ),
            onTap: () => _elegirHora(true),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Cierre'),
            trailing: Text(
              _fin,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: YampiColors.doradoOscuro,
              ),
            ),
            onTap: () => _elegirHora(false),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('CANCELAR'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context, {
              'horaInicio': _inicio,
              'horaFin': _fin,
              'habilitado': _habilitado,
            });
          },
          style: ElevatedButton.styleFrom(minimumSize: const Size(0, 44)),
          child: const Text('GUARDAR'),
        ),
      ],
    );
  }
}

