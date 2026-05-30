import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:mis_turnos_app/firebase_options.dart';

/// Host de los emuladores. En Android emulador usar 10.0.2.2; en web/desktop
/// localhost. Configurable por --dart-define=EMULATOR_HOST=...
const String emulatorHost =
    String.fromEnvironment('EMULATOR_HOST', defaultValue: 'localhost');

const int authEmulatorPort = 9099;
const int firestoreEmulatorPort = 8080;

bool _initialized = false;

/// Inicializa Firebase apuntando a los emuladores de Auth y Firestore.
/// Idempotente: seguro de llamar en cada `testWidgets`.
Future<void> setUpEmulators() async {
  if (_initialized) return;
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await FirebaseAuth.instance.useAuthEmulator(emulatorHost, authEmulatorPort);
  FirebaseFirestore.instance
      .useFirestoreEmulator(emulatorHost, firestoreEmulatorPort);
  _initialized = true;
}

/// Borra el usuario actual y los turnos sembrados, para aislar cada test.
Future<void> resetEmulatorState() async {
  final appointments =
      await FirebaseFirestore.instance.collection('appointment').get();
  for (final doc in appointments.docs) {
    await doc.reference.delete();
  }
  await FirebaseAuth.instance.signOut();
}
