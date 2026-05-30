import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mis_turnos_app/features/home/presentation/pages/widgets/calendar_widget.dart';
import 'package:mis_turnos_app/features/home/presentation/pages/widgets/day_summary_widget.dart';
import 'package:mis_turnos_app/features/login/presentation/providers/login_provider.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
      body: Column(
        children: [
          const Divider(height: 1),
          const DaySummaryWidget(),
          const SizedBox(height: 8),
          Expanded(child: CalendarWidget()),
        ],
      ),
    );
  }
}
