import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Provider del servicio de autenticación.
final loginProvider = Provider<AuthService>((ref) {
  return AuthService(FirebaseAuth.instance);
});

/// Estado de autenticación reactivo. Emite el [User] actual (o null si no hay
/// sesión) cada vez que cambia el login/logout.
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(loginProvider).authStateChanges;
});

/// Resultado de una operación de autenticación.
/// [user] no es null en caso de éxito; [error] tiene un mensaje legible si falló.
class AuthResult {
  final User? user;
  final String? error;

  const AuthResult({this.user, this.error});

  bool get isSuccess => user != null;
}

class AuthService {
  final FirebaseAuth _auth;

  AuthService(this._auth);

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<AuthResult> signInWithEmail(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return AuthResult(user: credential.user);
    } on FirebaseAuthException catch (e) {
      return AuthResult(error: _mapError(e));
    } catch (_) {
      return const AuthResult(error: 'Error inesperado. Intentá de nuevo.');
    }
  }

  Future<AuthResult> registerWithEmail(String email, String password) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return AuthResult(user: credential.user);
    } on FirebaseAuthException catch (e) {
      return AuthResult(error: _mapError(e));
    } catch (_) {
      return const AuthResult(error: 'Error inesperado. Intentá de nuevo.');
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Traduce los códigos de error de Firebase a mensajes legibles en español.
  String _mapError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No existe un usuario con ese email.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Email o contraseña incorrectos.';
      case 'email-already-in-use':
        return 'Ya existe una cuenta con ese email.';
      case 'weak-password':
        return 'La contraseña es muy débil (mínimo 6 caracteres).';
      case 'invalid-email':
        return 'El email no es válido.';
      case 'too-many-requests':
        return 'Demasiados intentos. Probá de nuevo en unos minutos.';
      default:
        return 'Error de autenticación: ${e.message ?? e.code}';
    }
  }
}
