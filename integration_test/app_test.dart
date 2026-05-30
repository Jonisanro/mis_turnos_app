import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mis_turnos_app/main.dart';

import 'emulator_setup.dart';

/// E2E contra el Firebase Emulator Suite. Requiere los emuladores corriendo:
///   firebase emulators:start --only auth,firestore
/// y luego:
///   fvm flutter test integration_test            (con un device/emulador activo)
///   fvm flutter drive --driver=test_driver/integration_test.dart \
///     --target=integration_test/app_test.dart -d chrome
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const email = 'e2e@test.com';
  const password = 'secret123';

  setUpAll(() async {
    await initializeDateFormatting('es');
    await setUpEmulators();
  });

  setUp(() async {
    await resetEmulatorState();
  });

  /// Crea (o reusa) el usuario de prueba y devuelve su uid, dejándolo deslogueado.
  Future<String> seedUserSignedOut() async {
    final auth = FirebaseAuth.instance;
    String uid;
    try {
      final cred = await auth.createUserWithEmailAndPassword(
          email: email, password: password);
      uid = cred.user!.uid;
    } on FirebaseAuthException catch (e) {
      if (e.code != 'email-already-in-use') rethrow;
      final cred = await auth.signInWithEmailAndPassword(
          email: email, password: password);
      uid = cred.user!.uid;
    }
    await auth.signOut();
    return uid;
  }

  Future<void> seedAppointment({
    required String id,
    required String owner,
    required String clientName,
  }) async {
    final now = DateTime.now();
    final at = DateTime(now.year, now.month, now.day, 10, 0);
    await FirebaseFirestore.instance.collection('appointment').doc(id).set({
      'id': id,
      'clientName': clientName,
      'phone': '',
      'dateTime': at,
      'duration': 60,
      'deposit': 0,
      'hasPaid': false,
      'service': 'Corte de pelo',
      'status': 'pendiente',
      'comments': '',
      'owner': owner,
    });
  }

  Future<void> login(WidgetTester tester) async {
    await tester.enterText(find.byType(TextFormField).at(0), email);
    await tester.enterText(find.byType(TextFormField).at(1), password);
    await tester.tap(find.widgetWithText(ElevatedButton, 'Iniciar sesión'));
    await tester.pumpAndSettle();
  }

  testWidgets('login → el usuario ve su turno sembrado', (tester) async {
    final uid = await seedUserSignedOut();
    await seedAppointment(id: 'e2e-1', owner: uid, clientName: 'Soledad E2E');

    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    await tester.pumpAndSettle();

    await login(tester);

    expect(find.textContaining('Soledad E2E'), findsWidgets);
  });

  testWidgets('un turno agregado en Firestore aparece en tiempo real',
      (tester) async {
    final uid = await seedUserSignedOut();

    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    await tester.pumpAndSettle();
    await login(tester);

    // Aún no hay turnos del usuario.
    expect(find.textContaining('Marta E2E'), findsNothing);

    await seedAppointment(id: 'e2e-2', owner: uid, clientName: 'Marta E2E');
    await tester.pumpAndSettle();

    expect(find.textContaining('Marta E2E'), findsWidgets);
  });
}
