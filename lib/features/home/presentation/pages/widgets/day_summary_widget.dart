import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mis_turnos_app/features/home/domain/entities/appointment.dart';
import 'package:mis_turnos_app/features/home/presentation/providers/appointments_provider.dart';

/// Resumen del día: cantidad de turnos de hoy, próximo turno y total de señas.
class DaySummaryWidget extends ConsumerWidget {
  const DaySummaryWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final turnos = ref.watch(appointmentsProvider).valueOrNull ?? [];

    final now = DateTime.now();
    final today = turnos.where((t) =>
        t.dateTime.year == now.year &&
        t.dateTime.month == now.month &&
        t.dateTime.day == now.day).toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

    final totalSenias =
        today.fold<double>(0, (sum, t) => sum + t.deposit);

    Appointment? next;
    for (final t in today) {
      if (t.dateTime.isAfter(now)) {
        next = t;
        break;
      }
    }

    final nextLabel = next == null
        ? 'Sin próximos hoy'
        : '${DateFormat('HH:mm').format(next.dateTime)} · ${next.clientName}';

    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _SummaryItem(
              icon: Icons.event_available,
              label: 'Turnos hoy',
              value: '${today.length}',
            ),
            _SummaryItem(
              icon: Icons.schedule,
              label: 'Próximo',
              value: nextLabel,
            ),
            _SummaryItem(
              icon: Icons.attach_money,
              label: 'Señas hoy',
              value: '\$${totalSenias.toStringAsFixed(0)}',
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.pink[300]),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 2),
          Text(
            value,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
