import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mis_turnos_app/core/routes/routes.dart';
import 'package:mis_turnos_app/core/shared_widgets/splash_screen.dart';
import 'package:mis_turnos_app/core/theme/app_theme.dart';
import 'package:mis_turnos_app/features/login/presentation/providers/login_provider.dart';
import 'package:mis_turnos_app/firebase_options.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:responsive_breakpoints/responsive_breakpoints.dart';

void main() async {
  setUrlStrategy(PathUrlStrategy());
  WidgetsFlutterBinding.ensureInitialized();

  // Necesario para DateFormat con locale 'es' (ej: nombres de meses en el calendario).
  await initializeDateFormatting('es');

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // En web: usar SESSION persistence (sessionStorage) en vez del default LOCAL
  // (IndexedDB). Efecto: la sesión se limpia al cerrar la pestaña/browser,
  // requiriendo login en la próxima apertura.
  // kIsWeb guard: setPersistence no existe en Android/iOS y lanzaría UnsupportedError.
  if (kIsWeb) {
    await FirebaseAuth.instance.setPersistence(Persistence.SESSION);
  }

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Observamos el estado de autenticación para detectar el window de carga
    // inicial en que Firebase restaura la sesión desde sessionStorage.
    final authState = ref.watch(authStateProvider);

    return MaterialApp.router(
      theme: AppTheme.light.copyWith(
        extensions: [
          ResponsiveBreakpointTheme<MaterialUIBreakpoint>(
            breakpoints: MaterialUIBreakpoint.values,
          ),
        ],
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('es'),
      ],
      debugShowCheckedModeBanner: false,
      title: 'Mis Turnos',
      routerConfig: AppRoutes.router,
      // builder intercepta el widget del router: muestra el SplashScreen
      // mientras Firebase restaura la sesión desde storage (AsyncLoading).
      // Una vez conocido el estado, el GoRouterRefreshStream dispara el redirect
      // y el router navega a /home o / según corresponda — sin ningún flash.
      builder: (context, child) {
        if (authState.isLoading) return const SplashScreen();
        return child ?? const SplashScreen();
      },
    );
  }
}
