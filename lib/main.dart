import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'widgets/fondo_yampi.dart';
import 'views/cliente/seleccionar_servicio_view.dart';
import 'views/barbero/login_view.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const YampiApp());
}

class YampiApp extends StatelessWidget {
  const YampiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Barbería Yampi',
      debugShowCheckedModeBanner: false,
      // Sin transición en iOS: el cambio de página es instantáneo.
      theme: AppTheme.dark.copyWith(
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.iOS: _SinTransicion(),
            TargetPlatform.macOS: _SinTransicion(),
          },
        ),
      ),
      locale: const Locale('es', 'CL'),
      supportedLocales: const [Locale('es', 'CL'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const HomeView(),
    );
  }
}

/// Reemplaza la animación de cambio de página por un corte directo.
class _SinTransicion extends PageTransitionsBuilder {
  const _SinTransicion();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return child;
  }
}

/// Pantalla inicial: el cliente elige si viene a reservar, con acceso de
/// barbero arriba a la derecha.
class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: FondoYampi(
        child: Stack(
          children: [
            // 1. Contenido principal centrado (logo, botón y texto).
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const _LogoYampi(),
                      const SizedBox(height: 48),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  const SeleccionarServicioView(),
                            ),
                          );
                        },
                        child: const Text('RESERVAR HORA'),
                      ),
                      const SizedBox(height: 40),
                      const Text(
                        'Disponibilidad sábados y domingos',
                        style: TextStyle(
                          fontSize: 13,
                          color: YampiColors.grisTexto,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // 2. Acceso del barbero, arriba a la derecha.
            Positioned(
              top: 24,
              right: 24,
              child: TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: YampiColors.grisTexto,
                  backgroundColor: Colors.black.withValues(alpha: 0.4),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: const BorderSide(color: Colors.white12, width: 1),
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginView()),
                  );
                },
                icon: const Icon(Icons.lock_outline, size: 16),
                label: const Text(
                  'BARBERO',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// El logo de Yampi sobre el fondo oscuro.
class _LogoYampi extends StatelessWidget {
  const _LogoYampi();

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/yampi.png',
      width: 280,
      fit: BoxFit.contain,
    );
  }
}

