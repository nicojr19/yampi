import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/servicio.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/fondo_yampi.dart';
import 'seleccionar_hora_view.dart';

/// Primer paso del cliente: elegir qué se va a cortar.
///
/// Los servicios se leen en vivo desde Firestore, así que si el barbero
/// cambia un precio desde la consola, la app lo refleja solo.
class SeleccionarServicioView extends StatelessWidget {
  const SeleccionarServicioView({super.key});

  @override
  Widget build(BuildContext context) {
    final firestore = FirestoreService();
    // Formato chileno: 8000 → $8.000
    final pesos = NumberFormat.currency(
      locale: 'es_CL',
      symbol: '\$',
      decimalDigits: 0,
    );

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: const Text('Elige tu servicio')),
      body: FondoYampi(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: StreamBuilder<List<Servicio>>(
              stream: firestore.servicios(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: YampiColors.dorado,
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return const _Mensaje(
                    icono: Icons.error_outline,
                    titulo: 'No pudimos cargar los servicios',
                    detalle: 'Revisa tu conexión e inténtalo de nuevo.',
                  );
                }

                final servicios = snapshot.data ?? [];

                if (servicios.isEmpty) {
                  return const _Mensaje(
                    icono: Icons.content_cut,
                    titulo: 'Sin servicios disponibles',
                    detalle: 'El barbero todavía no cargó sus precios.',
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: servicios.length + 1,
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return const Padding(
                        padding: EdgeInsets.only(bottom: 8),
                        child: Text(
                          '¿Qué te vas a hacer?',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            color: YampiColors.negroSuave,
                          ),
                        ),
                      );
                    }

                    final servicio = servicios[index - 1];
                    return _TarjetaServicio(
                      servicio: servicio,
                      precioFormateado: pesos.format(servicio.precio),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                SeleccionarHoraView(servicio: servicio),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _TarjetaServicio extends StatelessWidget {
  final Servicio servicio;
  final String precioFormateado;
  final VoidCallback onTap;

  const _TarjetaServicio({
    required this.servicio,
    required this.precioFormateado,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: const BoxDecoration(
                  gradient: YampiColors.degradadoDorado,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.content_cut,
                  color: YampiColors.blanco,
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      servicio.nombre,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: YampiColors.negroSuave,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${servicio.duracionMin} minutos',
                      style: const TextStyle(
                        fontSize: 13,
                        color: YampiColors.grisTexto,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                precioFormateado,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: YampiColors.doradoOscuro,
                ),
              ),
              const SizedBox(width: 6),
              const Icon(
                Icons.chevron_right,
                color: YampiColors.dorado,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Mensaje centrado para los casos en que no hay nada que mostrar.
class _Mensaje extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String detalle;

  const _Mensaje({
    required this.icono,
    required this.titulo,
    required this.detalle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icono, size: 56, color: YampiColors.doradoClaro),
            const SizedBox(height: 20),
            Text(
              titulo,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: YampiColors.negroSuave,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              detalle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: YampiColors.grisTexto,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

