import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mis_turnos_app/features/login/presentation/providers/login_provider.dart';
import 'package:mis_turnos_app/features/login/presentation/widgets/login_form.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/fakes.dart';
import '../../helpers/test_harness.dart';

class _MockFirebaseAuth extends Mock implements FirebaseAuth {}

Widget _app({required List<Override> overrides}) {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => const Scaffold(
          body: SingleChildScrollView(child: LoginCard()),
        ),
      ),
      GoRoute(
        path: '/home',
        builder: (_, __) => const Scaffold(body: Text('HOME PAGE')),
      ),
      GoRoute(
        path: '/register',
        builder: (_, __) => const Scaffold(body: Text('REGISTER PAGE')),
      ),
    ],
  );
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp.router(theme: testTheme(), routerConfig: router),
  );
}

void main() {
  testWidgets('login OK navega a /home', (tester) async {
    await tester.pumpWidget(_app(
      overrides: [
        loginProvider.overrideWithValue(buildAuthService(uid: 'uid-1')),
      ],
    ));

    await tester.enterText(find.byType(TextFormField).at(0), 'a@a.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'secret');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Iniciar sesión'));
    await tester.pumpAndSettle();

    expect(find.text('HOME PAGE'), findsOneWidget);
  });

  testWidgets('login con error muestra el mensaje mapeado', (tester) async {
    final auth = _MockFirebaseAuth();
    when(() => auth.signInWithEmailAndPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        )).thenThrow(FirebaseAuthException(code: 'invalid-credential'));

    await tester.pumpWidget(_app(
      overrides: [loginProvider.overrideWithValue(AuthService(auth))],
    ));

    await tester.enterText(find.byType(TextFormField).at(0), 'a@a.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'mala');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Iniciar sesión'));
    await tester.pump(); // procesa el future
    await tester.pump(); // muestra el SnackBar

    expect(find.text('Email o contraseña incorrectos.'), findsOneWidget);
    expect(find.text('HOME PAGE'), findsNothing);
  });

  testWidgets('validadores: campos vacíos muestran mensajes', (tester) async {
    await tester.pumpWidget(_app(
      overrides: [
        loginProvider.overrideWithValue(buildAuthService(uid: 'uid-1')),
      ],
    ));

    await tester.tap(find.widgetWithText(ElevatedButton, 'Iniciar sesión'));
    await tester.pump();

    expect(find.text('Ingresá tu email'), findsOneWidget);
    expect(find.text('Ingresá tu contraseña'), findsOneWidget);
    expect(find.text('HOME PAGE'), findsNothing);
  });
}
