import 'package:flutter_test/flutter_test.dart';
import 'package:mis_turnos_app/core/routes/routes.dart';

void main() {
  group('AppRoutes.computeRedirect', () {
    test('sin sesión en ruta protegida → redirige a /', () {
      expect(
        AppRoutes.computeRedirect(loggedIn: false, matchedLocation: '/home'),
        '/',
      );
    });

    test('sin sesión en ruta pública → no redirige', () {
      expect(
        AppRoutes.computeRedirect(loggedIn: false, matchedLocation: '/'),
        isNull,
      );
      expect(
        AppRoutes.computeRedirect(
            loggedIn: false, matchedLocation: '/register'),
        isNull,
      );
    });

    test('con sesión en ruta pública → redirige a /home', () {
      expect(
        AppRoutes.computeRedirect(loggedIn: true, matchedLocation: '/'),
        '/home',
      );
    });

    test('con sesión en ruta protegida → no redirige', () {
      expect(
        AppRoutes.computeRedirect(loggedIn: true, matchedLocation: '/home'),
        isNull,
      );
      expect(
        AppRoutes.computeRedirect(loggedIn: true, matchedLocation: '/services'),
        isNull,
      );
    });
  });
}
