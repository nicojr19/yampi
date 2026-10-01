import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/servicio.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';
import 'confirmacion_view.dart';
import 'package:intl/intl.dart';


/// Paso 3 del cliente: sus datos personales y el envío de la reserva.
///
/// Al guardar, la reserva nace en estado `pendiente` y queda esperando que
/// el barbero la apruebe o la rechace.
class DatosClienteView extends StatefulWidget {
  final Servicio servicio;
  final DateTime fechaHora;

  const DatosClienteView({
    super.key,
    required this.servicio,
    required this.fechaHora,
  });

  @override
  State<DatosClienteView> createState() => _DatosClienteViewState();
}

class _DatosClienteViewState extends State<DatosClienteView> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  final FirestoreService _firestore = FirestoreService();

  bool _enviando = false;

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _emailCtrl.dispose();
    _telefonoCtrl.dispose();
    super.dispose();
  }

  Future<void> _enviarReserva() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _enviando = true);

    try {
      await _firestore.crearReserva(
        clienteNombre: _nombreCtrl.text.trim(),
        clienteEmail: _emailCtrl.text.trim(),
        clienteTelefono: _telefonoCtrl.text.trim(),
        servicio: widget.servicio,
        fechaHora: widget.fechaHora,
      );

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ConfirmacionView(
            servicio: widget.servicio,
            fechaHora: widget.fechaHora,
            emailCliente: _emailCtrl.text.trim(),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _enviando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No pudimos guardar tu reserva. Inténtalo de nuevo.'),
          backgroundColor: YampiColors.rechazado,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
        final pesos = NumberFormat.currency(
      locale: 'es_CL',
      symbol: '\$',
      decimalDigits: 0,
    );
    final fecha = DateFormat("EEEE d 'de' MMMM", 'es').format(widget.fechaHora);
    final hora = DateFormat('HH:mm').format(widget.fechaHora);

    return Scaffold(
      appBar: AppBar(title: const Text('Tus datos')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _ResumenReserva(
                  servicio: widget.servicio,
                  fecha: fecha,
                  hora: hora,
                ),
                const SizedBox(height: 28),
                const Text(
                  '¿A nombre de quién?',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: YampiColors.negroSuave,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Te enviaremos la confirmación a tu correo.',
                  style: TextStyle(
                    fontSize: 13,
                    color: YampiColors.grisTexto,
                  ),
                ),
                const SizedBox(height: 18),
                TextFormField(
                  controller: _nombreCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Nombre completo',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().length < 3) {
                      return 'Escribe tu nombre completo';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Correo electrónico',
                    prefixIcon: Icon(Icons.mail_outline),
                  ),
                  validator: (v) {
                    final correo = v?.trim() ?? '';
                    final valido = RegExp(
                      r'^[\w\.\-]+@[\w\-]+\.[\w\.\-]+$',
                    ).hasMatch(correo);
                    if (!valido) return 'Escribe un correo válido';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _telefonoCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Teléfono',
                    prefixIcon: Icon(Icons.phone_outlined),
                    hintText: '+56 9 1234 5678',
                  ),
                  validator: (v) {
                    final tel = (v ?? '').replaceAll(RegExp(r'\D'), '');
                    if (tel.length < 8) return 'Escribe un teléfono válido';
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _enviando ? null : _enviarReserva,
                  child: _enviando
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: YampiColors.blanco,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Text('RESERVAR'),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Tu hora queda pendiente hasta que el barbero la confirme.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: YampiColors.grisTexto,
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

class _ResumenReserva extends StatelessWidget {
  final Servicio servicio;
  final String fecha;
  final String hora;

  const _ResumenReserva({
    required this.servicio,
    required this.fecha,
    required this.hora,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: YampiColors.blancoHueso,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: YampiColors.doradoClaro),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.content_cut,
                color: YampiColors.doradoOscuro,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  servicio.nombre,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: YampiColors.negroSuave,
                  ),
                ),
              ),
                            Text(
                NumberFormat.currency(
                  locale: 'es_CL',
                  symbol: '\$',
                  decimalDigits: 0,
                ).format(servicio.precio),

                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: YampiColors.doradoOscuro,
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            children: [
              const Icon(
                Icons.calendar_today,
                color: YampiColors.doradoOscuro,
                size: 18,
              ),
              const SizedBox(width: 10),
              Text(
                fecha,
                style: const TextStyle(
                  fontSize: 14,
                  color: YampiColors.negroSuave,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.access_time,
                color: YampiColors.doradoOscuro,
                size: 18,
              ),
              const SizedBox(width: 10),
              Text(
                '$hora hrs',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: YampiColors.negroSuave,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
