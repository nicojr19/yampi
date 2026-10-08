import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/fondo_yampi.dart';
import 'panel_view.dart';

/// Pantalla de acceso del barbero. No es para clientes.
class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final AuthService _auth = AuthService();

  /// >>> REEMPLAZA ESTO POR EL GMAIL REAL DEL BARBERO <<<
  /// Mientras no lo tengas, pon aquí el tuyo para poder probar el panel.
  static const List<String> emailsAutorizados = [
    'barberyampi@gmail.com',
    'nicolassmaldonadop1@gmail.com',
  ];

  bool _cargando = false;
  String? _error;

  Future<void> _entrar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final error = await _auth.entrarConGoogle(emailsAutorizados);
      if (!mounted) return;

      if (error != null) {
        setState(() {
          _error = error;
          _cargando = false;
        });
        return;
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const PanelView()),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'No se pudo iniciar sesión. Inténtalo de nuevo.';
        _cargando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: const Text('Panel del barbero')),
      body: FondoYampi(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: const BoxDecoration(
                      gradient: YampiColors.degradadoDorado,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.lock_outline,
                      color: YampiColors.blanco,
                      size: 38,
                    ),
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    'Acceso del barbero',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: YampiColors.negroSuave,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Entra con tu cuenta de Gmail para ver y administrar '
                    'las reservas.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: YampiColors.grisTexto,
                    ),
                  ),
                  const SizedBox(height: 36),
                  if (_error != null) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: YampiColors.rechazado.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: YampiColors.rechazado),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: YampiColors.rechazado,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _error!,
                              style: const TextStyle(
                                fontSize: 13,
                                color: YampiColors.rechazado,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                  ElevatedButton.icon(
                    onPressed: _cargando ? null : _entrar,
                    icon: _cargando
                        ? const SizedBox.shrink()
                        : const Icon(Icons.login),
                    label: _cargando
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: YampiColors.blanco,
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Text('ENTRAR CON GOOGLE'),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Solo la cuenta autorizada puede acceder.',
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
      ),
    );
  }
}

