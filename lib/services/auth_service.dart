import 'package:firebase_auth/firebase_auth.dart';

/// Maneja el acceso del barbero.
///
/// Usamos autenticación con Google: el barbero entra con su propia cuenta de
/// Gmail, sin inventar una contraseña nueva. Ese mismo correo es el que
/// después recibe las notificaciones de reservas.
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// El barbero actualmente logueado, o null si nadie entró.
  User? get usuarioActual => _auth.currentUser;

  /// Si hay alguien con sesión iniciada.
  bool get estaLogueado => _auth.currentUser != null;

  /// El correo del barbero logueado.
  String? get emailActual => _auth.currentUser?.email;

  /// Abre la ventana de Google para que el barbero entre.
  ///
  /// Solo deja pasar al correo autorizado: si entra cualquier otra cuenta,
  /// se le cierra la sesión de inmediato. Así nadie más puede ver el panel,
  /// aunque descubra la dirección.
  Future<String?> entrarConGoogle(String emailAutorizado) async {
    final provider = GoogleAuthProvider();
    final resultado = await _auth.signInWithPopup(provider);
    final user = resultado.user;

    if (user == null) return 'No se pudo iniciar sesión.';

    final correo = (user.email ?? '').toLowerCase().trim();
    if (correo != emailAutorizado.toLowerCase().trim()) {
      await _auth.signOut();
      return 'Esta cuenta no tiene permiso para el panel.';
    }

    return null; // null = todo bien
  }

  /// Cierra la sesión del barbero.
  Future<void> salir() => _auth.signOut();
}
