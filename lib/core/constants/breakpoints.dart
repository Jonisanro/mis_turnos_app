import 'package:flutter/material.dart';
import 'package:responsive_breakpoints/responsive_breakpoints.dart';

/// Breakpoints usando el paquete [responsive_breakpoints] (MaterialUIBreakpoint).
///
/// La app debe tener [ResponsiveBreakpointTheme] en el tema (ver [main.dart]).
/// Uso: `context.screenType`, `context.isMobile`, `context.isTablet`, etc.
class Breakpoints {
  Breakpoints._();

  /// Límites en píxeles (Material 3: small &lt;600, medium 600–839, large ≥840).
  static const double mobileMax = 599;
  static const double tabletMin = 600;
  static const double tabletMax = 839;
  static const double desktopMin = 840;
}

/// Tipo de pantalla (equivalente a small/medium/large de MaterialUIBreakpoint).
enum ScreenType {
  mobile,
  tablet,
  desktop,
}

extension BreakpointsContext on BuildContext {
  /// Breakpoint actual del paquete: small (móvil), medium (tablet), large (escritorio).
  MaterialUIBreakpoint get materialBreakpoint =>
      ResponsiveBreakpointTheme.of<MaterialUIBreakpoint>(this);

  /// Ancho actual de la pantalla (o ventana en web).
  double get screenWidth => MediaQuery.sizeOf(this).width;

  /// Tipo de pantalla según Material 3 (mobile / tablet / desktop).
  ScreenType get screenType {
    switch (materialBreakpoint) {
      case MaterialUIBreakpoint.small:
        return ScreenType.mobile;
      case MaterialUIBreakpoint.medium:
        return ScreenType.tablet;
      case MaterialUIBreakpoint.large:
        return ScreenType.desktop;
    }
  }

  /// True si es móvil (ancho &lt; 600).
  bool get isMobile => materialBreakpoint == MaterialUIBreakpoint.small;

  /// True si es tablet (600 ≤ ancho &lt; 840).
  bool get isTablet => materialBreakpoint == MaterialUIBreakpoint.medium;

  /// True si es escritorio (ancho ≥ 840).
  bool get isDesktop => materialBreakpoint == MaterialUIBreakpoint.large;

  /// True si es tablet o escritorio (pantalla “grande”).
  bool get isMediumOrLarger => isTablet || isDesktop;
}
