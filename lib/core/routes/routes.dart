import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:mis_turnos_app/features/home/presentation/pages/home_page.dart';
import 'package:mis_turnos_app/features/login/presentation/pages/login_page.dart';
import 'package:mis_turnos_app/features/login/presentation/pages/register_page.dart';
import 'package:mis_turnos_app/features/services/presentation/pages/services_page.dart';

/// Notifica al router cada vez que cambia el estado de autenticación, para que
/// reevalúe el [GoRouter.redirect] al hacer login / logout.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

class AppRoutes {
  /// Rutas públicas (accesibles sin sesión iniciada).
  static const _publicRoutes = {'/', '/register'};

  /// Lógica pura del guard de rutas, extraída para poder testearla sin Firebase.
  /// Devuelve la ruta a la que redirigir, o `null` si no hay que redirigir.
  static String? computeRedirect({
    required bool loggedIn,
    required String matchedLocation,
  }) {
    final isPublic = _publicRoutes.contains(matchedLocation);

    // Sin sesión y queriendo entrar a una ruta protegida → al login.
    if (!loggedIn && !isPublic) return '/';
    // Con sesión y parado en login/registro → a la home.
    if (loggedIn && isPublic) return '/home';
    return null;
  }

  static final GoRouter router = GoRouter(
    initialLocation: '/',
    refreshListenable:
        GoRouterRefreshStream(FirebaseAuth.instance.authStateChanges()),
    redirect: (context, state) => computeRedirect(
      loggedIn: FirebaseAuth.instance.currentUser != null,
      matchedLocation: state.matchedLocation,
    ),
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: '/services',
        builder: (context, state) => const ServicesPage(),
      ),
    ],
  );
}
