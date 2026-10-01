import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'views/cliente/seleccionar_servicio_view.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
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
      theme: AppTheme.light,
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

/// Pantalla inicial: el cliente elige si viene a reservar o si es el barbero.
class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const _LogoYampi(),
                const SizedBox(height: 56),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SeleccionarServicioView(),
                      ),
                    );
                  },
                  child: const Text('RESERVAR HORA'),
                ),
                const SizedBox(height: 14),
                                OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const LoginView(),
                      ),
                    );
                  },
                  child: const Text('SOY EL BARBERO'),
                ),
                const SizedBox(height: 40),
                const Text(
                  'Atendemos sábados y domingos',
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
    );
  }
}

/// El logo real de Yampi. Como el archivo tiene fondo oscuro, va sobre una
/// tarjeta oscura redondeada con un resplandor dorado: así se ve como parte
/// del diseño y no como un recorte pegado sobre el blanco.
class _LogoYampi extends StatelessWidget {
  const _LogoYampi();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: YampiColors.negroSuave,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: YampiColors.dorado.withValues(alpha: 0.3),
            blurRadius: 24,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Image.asset(
        'assets/images/yampi.png',
        width: 220,
        fit: BoxFit.contain,
      ),
    );
  }
}
