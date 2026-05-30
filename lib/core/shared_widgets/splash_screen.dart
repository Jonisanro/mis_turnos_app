import 'package:flutter/material.dart';
import 'package:mis_turnos_app/core/theme/app_theme.dart';

/// Pantalla de carga mostrada mientras Firebase restaura el estado de sesión
/// desde sessionStorage al arrancar la app.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Mismo ícono que el login para consistencia visual
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.accentLight,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.calendar_month_rounded,
                color: AppColors.accent,
                size: 38,
              ),
            ),
            const SizedBox(height: 32),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppColors.accent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
