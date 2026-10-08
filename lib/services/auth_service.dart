import 'package:firebase_auth/firebase_auth.dart';

/// Maneja el acceso del barbero con su cuenta de Google.
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get usuarioActual => _auth.currentUser;
  bool get estaLogueado => _auth.currentUser != null;
  String? get emailActual => _auth.currentUser?.email;

  /// Abre la ventana de Google. Solo deja pasar a los correos autorizados.
  Future<String?> entrarConGoogle(List<String> emailsAutorizados) async {
    final provider = GoogleAuthProvider();
    final resultado = await _auth.signInWithPopup(provider);
    final user = resultado.user;

    if (user == null) return 'No se pudo iniciar sesión.';

    final correo = (user.email ?? '').toLowerCase().trim();
    final permitidos =
        emailsAutorizados.map((e) => e.toLowerCase().trim()).toSet();

    if (!permitidos.contains(correo)) {
      await _auth.signOut();
      return 'Esta cuenta no tiene permiso para el panel.';
    }

    return null; // null = todo bien
  }

  Future<void> salir() => _auth.signOut();
}

