import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mis_turnos_app/core/constants/breakpoints.dart';
import 'package:mis_turnos_app/features/home/presentation/pages/widgets/calendar_widget.dart';
import 'package:mis_turnos_app/features/home/presentation/pages/widgets/day_summary_widget.dart';
import 'package:mis_turnos_app/features/home/presentation/pages/widgets/new_appointment_dialog_widget.dart';
import 'package:mis_turnos_app/features/login/presentation/providers/login_provider.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  void _openNewAppointmentDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => const NewAppointmentDialogWidget(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMobile = context.isMobile;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Turnos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.design_services_outlined),
            tooltip: 'Mis servicios',
            onPressed: () => context.push('/services'),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Cerrar sesión',
            onPressed: () async {
              await ref.read(loginProvider).signOut();
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: isMobile
          ? FloatingActionButton(
              onPressed: () => _openNewAppointmentDialog(context),
              tooltip: 'Agendar Turno',
              child: const Icon(Icons.add_rounded),
            )
          : null,
      body: isMobile ? _mobileLayout() : _desktopLayout(),
    );
  }

  /// Mobile: calendario ocupa 3/4 de la pantalla, info/totalizadores 1/4.
  Widget _mobileLayout() => Column(
        children: [
          const Divider(height: 1),
          // Calendario — 3/4 del espacio disponible
          const Expanded(
            flex: 3,
            child: CalendarWidget(),
          ),
          const Divider(height: 1),
          // Zona de info — 1/4 del espacio disponible
          const Expanded(
            flex: 1,
            child: DaySummaryWidget(),
          ),
        ],
      );

  /// Desktop: resumen en la parte superior (altura natural) + calendario expandido.
  Widget _desktopLayout() => const Column(
        children: [
          Divider(height: 1),
          DaySummaryWidget(),
          SizedBox(height: 8),
          Expanded(child: CalendarWidget()),
        ],
      );
}
