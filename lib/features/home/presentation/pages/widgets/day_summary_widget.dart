import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mis_turnos_app/core/theme/app_theme.dart';
import 'package:mis_turnos_app/features/home/domain/entities/appointment.dart';
import 'package:mis_turnos_app/features/home/presentation/providers/appointments_provider.dart';

/// Resumen del día: 3 mini-cards con acento violeta.
class DaySummaryWidget extends ConsumerWidget {
  const DaySummaryWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final turnos = ref.watch(appointmentsProvider).valueOrNull ?? [];
    final now = DateTime.now();

    final today = turnos
        .where((t) =>
            t.dateTime.year == now.year &&
            t.dateTime.month == now.month &&
            t.dateTime.day == now.day)
        .toList()
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
        ? '—'
        : '${DateFormat('HH:mm').format(next.dateTime)}  ${next.clientName}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // En pantallas muy angostas apilamos en columna
          if (constraints.maxWidth < 400) {
            return Column(
              children: [
                _SummaryCard(
                  icon: Icons.event_available_rounded,
                  label: 'Turnos hoy',
                  value: '${today.length}',
                ),
                const SizedBox(height: 8),
                _SummaryCard(
                  icon: Icons.schedule_rounded,
                  label: 'Próximo',
                  value: nextLabel,
                ),
                const SizedBox(height: 8),
                _SummaryCard(
                  icon: Icons.payments_outlined,
                  label: 'Señas hoy',
                  value: '\$${totalSenias.toStringAsFixed(0)}',
                ),
              ],
            );
          }
          return Row(
            children: [
              Expanded(
                child: _SummaryCard(
                  icon: Icons.event_available_rounded,
                  label: 'Turnos hoy',
                  value: '${today.length}',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: _SummaryCard(
                  icon: Icons.schedule_rounded,
                  label: 'Próximo',
                  value: nextLabel,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SummaryCard(
                  icon: Icons.payments_outlined,
                  label: 'Señas hoy',
                  value: '\$${totalSenias.toStringAsFixed(0)}',
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: const Border(
          left: BorderSide(color: AppColors.accent, width: 3),
          top: BorderSide(color: AppColors.border),
          right: BorderSide(color: AppColors.border),
          bottom: BorderSide(color: AppColors.border),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.accentLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.accent, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.secondary,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
