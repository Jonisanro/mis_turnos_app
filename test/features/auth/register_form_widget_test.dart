import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mis_turnos_app/features/login/presentation/providers/login_provider.dart';
import 'package:mis_turnos_app/features/login/presentation/widgets/register_form.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/fakes.dart';
import '../../helpers/test_harness.dart';

class _MockFirebaseAuth extends Mock implements FirebaseAuth {}

Widget _app({required List<Override> overrides}) {
  final router = GoRouter(
    initialLocation: '/register',
    routes: [
      GoRoute(
        path: '/register',
        builder: (_, __) => const Scaffold(
          body: SingleChildScrollView(child: RegisterCard()),
        ),
      ),
      GoRoute(
        path: '/',
        builder: (_, __) => const Scaffold(body: Text('LOGIN PAGE')),
      ),
      GoRoute(
        path: '/home',
        builder: (_, __) => const Scaffold(body: Text('HOME PAGE')),
      ),
    ],
  );
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp.router(theme: testTheme(), routerConfig: router),
  );
}

void main() {
  testWidgets('registro OK navega a /home', (tester) async {
    await tester.pumpWidget(_app(
      overrides: [
        loginProvider.overrideWithValue(buildAuthService(uid: 'uid-1')),
      ],
    ));

    await tester.enterText(find.byType(TextFormField).at(0), 'nuevo@a.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'secret');
    await tester.enterText(find.byType(TextFormField).at(2), 'secret');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Crear cuenta'));
    await tester.pumpAndSettle();

    expect(find.text('HOME PAGE'), findsOneWidget);
  });

  testWidgets('contraseñas que no coinciden muestran error', (tester) async {
    await tester.pumpWidget(_app(
      overrides: [
        loginProvider.overrideWithValue(buildAuthService(uid: 'uid-1')),
      ],
    ));

    await tester.enterText(find.byType(TextFormField).at(0), 'nuevo@a.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'secret');
    await tester.enterText(find.byType(TextFormField).at(2), 'otra');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Crear cuenta'));
    await tester.pump();

    expect(find.text('Las contraseñas no coinciden'), findsOneWidget);
    expect(find.text('HOME PAGE'), findsNothing);
  });

  testWidgets('registro con email en uso muestra el mensaje mapeado',
      (tester) async {
    final auth = _MockFirebaseAuth();
    when(() => auth.createUserWithEmailAndPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        )).thenThrow(FirebaseAuthException(code: 'email-already-in-use'));

    await tester.pumpWidget(_app(
      overrides: [loginProvider.overrideWithValue(AuthService(auth))],
    ));

    await tester.enterText(find.byType(TextFormField).at(0), 'repe@a.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'secret');
    await tester.enterText(find.byType(TextFormField).at(2), 'secret');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Crear cuenta'));
    await tester.pump();
    await tester.pump();

    expect(find.text('Ya existe una cuenta con ese email.'), findsOneWidget);
  });
}
