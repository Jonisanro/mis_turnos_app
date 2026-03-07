import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

final loginProvider = Provider<AuthService>((ref) {
  return AuthService(FirebaseAuth.instance);
});

class AuthService {
  final FirebaseAuth _auth;

  AuthService(this._auth);

  Future<User?> signInWithEmail(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        print('⚠️ No existe un usuario con ese email.');
      } else if (e.code == 'wrong-password') {
        print('⚠️ Contraseña incorrecta.');
      } else if (e.code == 'invalid-credential') {
        print('⚠️ Credencial inválida, malformada o vencida.');
      } else {
        print('⚠️ Error desconocido: ${e.code} - ${e.message}');
      }
      return null;
    } catch (e) {
      print('❌ Error inesperado: $e');
      return null;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
