import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mis_turnos_app/core/theme/app_theme.dart';
import 'package:responsive_breakpoints/responsive_breakpoints.dart';

/// Tema usado en tests: replica el de [main.dart] incluyendo la extensión de
/// breakpoints, para que `context.isMobile` y compañía funcionen.
ThemeData testTheme() => AppTheme.light.copyWith(
      extensions: [
        ResponsiveBreakpointTheme<MaterialUIBreakpoint>(
          breakpoints: MaterialUIBreakpoint.values,
        ),
      ],
    );

/// Envuelve [child] en un [ProviderScope] + [MaterialApp] listo para widget tests.
Widget wrapWithProviders(
  Widget child, {
  List<Override> overrides = const [],
}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      theme: testTheme(),
      home: child,
    ),
  );
}

/// Crea un [ProviderContainer] con los overrides dados. El test es responsable
/// de llamar `addTearDown(container.dispose)`.
ProviderContainer makeContainer({List<Override> overrides = const []}) {
  return ProviderContainer(overrides: overrides);
}
