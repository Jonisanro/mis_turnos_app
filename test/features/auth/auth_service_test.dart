import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mis_turnos_app/features/login/presentation/providers/login_provider.dart';
import 'package:mocktail/mocktail.dart';

class _MockFirebaseAuth extends Mock implements FirebaseAuth {}

void main() {
  group('AuthService — happy paths (MockFirebaseAuth)', () {
    test('signInWithEmail OK devuelve el usuario', () async {
      final auth = MockFirebaseAuth(
        mockUser: MockUser(uid: 'uid-1', email: 'a@a.com'),
      );
      final service = AuthService(auth);

      final result = await service.signInWithEmail('a@a.com', 'secret');

      expect(result.isSuccess, isTrue);
      expect(result.error, isNull);
      expect(result.user?.uid, 'uid-1');
    });

    test('registerWithEmail OK devuelve el usuario creado', () async {
      final auth = MockFirebaseAuth();
      final service = AuthService(auth);

      final result = await service.registerWithEmail('nuevo@a.com', 'secret');

      expect(result.isSuccess, isTrue);
      expect(result.user?.email, 'nuevo@a.com');
    });

    test('signOut deja currentUser en null', () async {
      final auth = MockFirebaseAuth(
        signedIn: true,
        mockUser: MockUser(uid: 'uid-1', email: 'a@a.com'),
      );
      final service = AuthService(auth);
      expect(service.currentUser?.uid, 'uid-1');

      await service.signOut();

      expect(service.currentUser, isNull);
    });

    test('authStateChanges emite null tras signOut', () async {
      final auth = MockFirebaseAuth(
        signedIn: true,
        mockUser: MockUser(uid: 'uid-1', email: 'a@a.com'),
      );
      final service = AuthService(auth);

      final emissions = <User?>[];
      final sub = service.authStateChanges.listen(emissions.add);
      await service.signOut();
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();

      expect(emissions.last, isNull);
    });
  });

  group('AuthService — mapeo de errores (mocktail)', () {
    test('invalid-credential → mensaje legible', () async {
      final auth = _MockFirebaseAuth();
      when(() => auth.signInWithEmailAndPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenThrow(FirebaseAuthException(code: 'invalid-credential'));
      final service = AuthService(auth);

      final result = await service.signInWithEmail('a@a.com', 'mala');

      expect(result.isSuccess, isFalse);
      expect(result.error, 'Email o contraseña incorrectos.');
    });

    test('email-already-in-use → mensaje legible', () async {
      final auth = _MockFirebaseAuth();
      when(() => auth.createUserWithEmailAndPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenThrow(FirebaseAuthException(code: 'email-already-in-use'));
      final service = AuthService(auth);

      final result = await service.registerWithEmail('repe@a.com', 'secret');

      expect(result.isSuccess, isFalse);
      expect(result.error, 'Ya existe una cuenta con ese email.');
    });

    test('error inesperado (no FirebaseAuthException) → mensaje genérico',
        () async {
      final auth = _MockFirebaseAuth();
      when(() => auth.signInWithEmailAndPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenThrow(Exception('boom'));
      final service = AuthService(auth);

      final result = await service.signInWithEmail('a@a.com', 'x');

      expect(result.error, 'Error inesperado. Intentá de nuevo.');
    });
  });
}
