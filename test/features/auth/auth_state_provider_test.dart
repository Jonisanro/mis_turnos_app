import 'package:flutter_test/flutter_test.dart';
import 'package:mis_turnos_app/features/login/presentation/providers/login_provider.dart';

import '../../helpers/fakes.dart';
import '../../helpers/test_harness.dart';

void main() {
  test('authStateProvider refleja el AuthService overrideado (login/logout)',
      () async {
    // Arrancamos sin sesión para no perder la emisión inicial del broadcast
    // stream; nos suscribimos ANTES de loguear.
    final auth = buildMockAuth(signedIn: false, uid: 'uid-1');
    final container = makeContainer(
      overrides: [loginProvider.overrideWithValue(AuthService(auth))],
    );
    addTearDown(container.dispose);

    // Suscripción activa para capturar emisiones del stream.
    final sub = container.listen(authStateProvider, (_, __) {});
    addTearDown(sub.close);

    await auth.signInWithEmailAndPassword(email: 'a@a.com', password: 'secret');
    await Future<void>.delayed(Duration.zero);
    expect(container.read(authStateProvider).value?.uid, 'uid-1');

    await auth.signOut();
    await Future<void>.delayed(Duration.zero);
    expect(container.read(authStateProvider).value, isNull);
  });
}
