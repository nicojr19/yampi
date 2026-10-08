import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/reserva.dart';

class EmailService {
  // Pega aquí la URL que copies de Supabase.
  static const String _url =
      'https://rbfncxhdqeehbmsxvave.supabase.co/functions/v1/quick-task';

  static const String _emailBarbero = 'barberyampi@gmail.com';

  /// Formatea un DateTime como "sábado 10 de octubre, 16:30".
  static String _formatearFecha(DateTime f) {
    const dias = [
      'lunes', 'martes', 'miércoles', 'jueves',
      'viernes', 'sábado', 'domingo',
    ];
    const meses = [
      'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
      'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre',
    ];
    final hh = f.hour.toString().padLeft(2, '0');
    final mm = f.minute.toString().padLeft(2, '0');
    return '${dias[f.weekday - 1]} ${f.day} de ${meses[f.month - 1]}, $hh:$mm';
  }

  /// Envío genérico: llama a la función de Supabase, que habla con Brevo.
  static Future<bool> _enviar({
    required String to,
    required String subject,
    required String html,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(_url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'to': to, 'subject': subject, 'html': html}),
      );
      if (response.statusCode >= 200 && response.statusCode < 300) {
        print('>>> correo: OK para $to');
        print('>>> correo: ${response.body}');
        return true;
      }
      print('>>> correo: ERROR ${response.statusCode} para $to');
      print('>>> correo: ${response.body}');
      return false;
    } catch (e) {
      print('>>> correo: EXCEPCIÓN para $to: $e');
      return false;
    }
  }

  /// Reserva nueva → aviso al barbero.
  static Future<bool> avisarReservaNueva(Reserva reserva) async {
    final cuando = _formatearFecha(reserva.fechaHora);
    print('>>> correo: avisarReservaNueva a $_emailBarbero');
    return _enviar(
      to: _emailBarbero,
      subject: 'Nueva reserva — ${reserva.clienteNombre}',
      html: '''
        <h2>Nueva reserva</h2>
        <ul>
          <li><strong>Cliente:</strong> ${reserva.clienteNombre}</li>
          <li><strong>Email:</strong> ${reserva.clienteEmail}</li>
          <li><strong>Teléfono:</strong> ${reserva.clienteTelefono}</li>
          <li><strong>Servicio:</strong> ${reserva.servicioNombre}</li>
          <li><strong>Cuándo:</strong> $cuando</li>
          <li><strong>Precio:</strong> \$${reserva.precio}</li>
        </ul>
      ''',
    );
  }

  /// Reserva confirmada → al cliente.
  static Future<bool> confirmarAlCliente(Reserva reserva) async {
    final cuando = _formatearFecha(reserva.fechaHora);
    print('>>> correo: confirmarAlCliente a ${reserva.clienteEmail}');
    return _enviar(
      to: reserva.clienteEmail,
      subject: 'Reserva confirmada — $cuando',
      html: '''
        <h2>Hola ${reserva.clienteNombre}</h2>
        <p>Tu reserva quedó confirmada:</p>
        <ul>
          <li><strong>Servicio:</strong> ${reserva.servicioNombre}</li>
          <li><strong>Cuándo:</strong> $cuando</li>
          <li><strong>Precio:</strong> \$${reserva.precio}</li>
        </ul>
        <p>Te esperamos en Yampi. Si necesitas cambiarla,
           respóndenos a este correo.</p>
      ''',
    );
  }

  /// Reserva rechazada → al cliente.
  static Future<bool> rechazarAlCliente(Reserva reserva) async {
    final cuando = _formatearFecha(reserva.fechaHora);
    final motivo = reserva.motivoRechazo.isEmpty
        ? ''
        : '<p><strong>Motivo:</strong> ${reserva.motivoRechazo}</p>';
    print('>>> correo: rechazarAlCliente a ${reserva.clienteEmail}');
    return _enviar(
      to: reserva.clienteEmail,
      subject: 'Sobre tu reserva del $cuando',
      html: '''
        <h2>Hola ${reserva.clienteNombre}</h2>
        <p>No pudimos confirmar tu reserva de
           <strong>${reserva.servicioNombre}</strong> para el
           <strong>$cuando</strong>.</p>
        $motivo
        <p>Te invitamos a elegir otro horario en la app.</p>
      ''',
    );
  }

  /// El barbero cambió la hora de una reserva ya confirmada.
  /// Se le avisa al cliente con la hora vieja y la nueva.
  static Future<bool> avisarCambioDeHora(
    Reserva reserva,
    DateTime horaAnterior,
  ) async {
    final antes = _formatearFecha(horaAnterior);
    final ahora = _formatearFecha(reserva.fechaHora);
    print('>>> correo: avisarCambioDeHora a ${reserva.clienteEmail}');
    print('>>> correo: antes=$antes ahora=$ahora');
    return _enviar(
      to: reserva.clienteEmail,
      subject: 'Cambiamos la hora de tu reserva',
      html: '''
        <h2>Hola ${reserva.clienteNombre}</h2>
        <p>Tu reserva cambió de hora:</p>
        <ul>
          <li><strong>Antes:</strong> $antes</li>
          <li><strong>Ahora:</strong> $ahora</li>
          <li><strong>Servicio:</strong> ${reserva.servicioNombre}</li>
        </ul>
        <p>La hora nueva queda <strong>pendiente de confirmación</strong>.
           Te avisamos en cuanto el barbero la apruebe.</p>
      ''',
    );
  }

  /// El barbero anuló una reserva ya confirmada.
  static Future<bool> avisarAnulacion(Reserva reserva) async {
    final cuando = _formatearFecha(reserva.fechaHora);
    final motivo = reserva.motivoRechazo.isEmpty
        ? ''
        : '<p><strong>Motivo:</strong> ${reserva.motivoRechazo}</p>';
    print('>>> correo: avisarAnulacion a ${reserva.clienteEmail}');
    return _enviar(
      to: reserva.clienteEmail,
      subject: 'Tu reserva del $cuando fue anulada',
      html: '''
        <h2>Hola ${reserva.clienteNombre}</h2>
        <p>Lamentablemente tuvimos que anular tu reserva de
           <strong>${reserva.servicioNombre}</strong> para el
           <strong>$cuando</strong>.</p>
        $motivo
        <p>Te invitamos a elegir otro horario en la app.</p>
      ''',
    );
  }
}
