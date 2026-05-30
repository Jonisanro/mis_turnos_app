import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:mis_turnos_app/features/login/presentation/providers/login_provider.dart';
import 'package:mis_turnos_app/features/services/domain/entities/service.dart';
import 'package:mis_turnos_app/features/services/presentation/providers/services_provider.dart';

/// [MockUser] con valores por defecto.
MockUser buildMockUser({
  String uid = 'uid-1',
  String email = 'test@example.com',
}) {
  return MockUser(uid: uid, email: email, displayName: 'Test User');
}

/// [MockFirebaseAuth] con un usuario logueado (por defecto) o sin sesión.
MockFirebaseAuth buildMockAuth({
  bool signedIn = true,
  String uid = 'uid-1',
  String email = 'test@example.com',
}) {
  return MockFirebaseAuth(
    signedIn: signedIn,
    mockUser: buildMockUser(uid: uid, email: email),
  );
}

/// [AuthService] respaldado por un [MockFirebaseAuth], para overridear
/// `loginProvider` en tests.
AuthService buildAuthService({
  bool signedIn = true,
  String uid = 'uid-1',
}) {
  return AuthService(buildMockAuth(signedIn: signedIn, uid: uid));
}

/// Notifier de servicios que devuelve una lista fija sin tocar Firestore.
/// Útil para overridear `servicesProvider` en los tests del diálogo de turno.
class FakeServicesNotifier extends ServicesNotifier {
  FakeServicesNotifier(this._services);

  final List<Service> _services;

  @override
  Future<List<Service>> build() async => _services;
}
