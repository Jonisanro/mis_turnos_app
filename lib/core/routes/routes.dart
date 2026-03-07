import 'package:go_router/go_router.dart';
import 'package:mis_turnos_app/features/home/presentation/pages/home_page.dart';
import 'package:mis_turnos_app/features/login/presentation/pages/login_page.dart';

class AppRoutes {
  static final GoRouter router = GoRouter(
    routes: [
      // Ruta principal
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomePage(),
      ),
      // Ruta de login
      GoRoute(
        path: '/',
        builder: (context, state) => const LoginPage(),
      ),
    ],
  );
}
