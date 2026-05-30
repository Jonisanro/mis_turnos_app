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
        title: const Text('Mis turnos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.design_services),
            tooltip: 'Mis servicios',
            onPressed: () => context.push('/services'),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: () async {
              // El guard del router redirige a / al cerrar sesión.
              await ref.read(loginProvider).signOut();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          const DaySummaryWidget(),
          Expanded(child: CalendarWidget()),
        ],
      ),
    );
  }
}
