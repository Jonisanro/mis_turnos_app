import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mis_turnos_app/core/routes/routes.dart';
import 'package:mis_turnos_app/core/theme/app_theme.dart';
import 'package:mis_turnos_app/firebase_options.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:responsive_breakpoints/responsive_breakpoints.dart';

void main() async {
  setUrlStrategy(PathUrlStrategy());
  WidgetsFlutterBinding.ensureInitialized();
  // Necesario para DateFormat con locale 'es' (ej: nombres de meses en el calendario).
  await initializeDateFormatting('es');
  await Firebase.initializeApp(
      options:
          DefaultFirebaseOptions.currentPlatform); // Aquí se pasan las opciones
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      // Tema con breakpoints responsive (mobile / tablet / desktop) para toda la app.
      theme: AppTheme.light.copyWith(
        extensions: [
          ResponsiveBreakpointTheme<MaterialUIBreakpoint>(
            breakpoints: MaterialUIBreakpoint.values,
          ),
        ],
      ),
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [
        Locale('en'), // Inglés
        Locale('es'), // Español
      ],
      debugShowCheckedModeBanner: false,
      title: 'Mis turnos',
      routerConfig: AppRoutes.router,
    );
  }
}
