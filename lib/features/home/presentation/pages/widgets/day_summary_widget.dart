import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mis_turnos_app/core/constants/breakpoints.dart';
import 'package:mis_turnos_app/core/theme/app_theme.dart';
import 'package:mis_turnos_app/features/home/domain/entities/appointment.dart';
import 'package:mis_turnos_app/features/home/presentation/providers/appointments_provider.dart';

/// Panel informativo adaptativo:
/// - Mobile (1/4 de pantalla): 2 paneles compactos — próximo turno + semana.
/// - Desktop (barra superior): 3 cards — turnos hoy + próximo + semana.
class DaySummaryWidget extends ConsumerWidget {
  const DaySummaryWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final turnos = ref.watch(appointmentsProvider).valueOrNull ?? [];
    final now = DateTime.now();

    // ── Datos de hoy ────────────────────────────────────────────────────────
    final today = turnos
        .where((t) =>
            t.dateTime.year == now.year &&
            t.dateTime.month == now.month &&
            t.dateTime.day == now.day)
        .toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

    Appointment? next;
    for (final t in today) {
      if (t.dateTime.isAfter(now)) {
        next = t;
        break;
      }
    }

    // ── Datos de la semana ──────────────────────────────────────────────────
    // Lunes de la semana actual como inicio.
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final startOfWeek =
        DateTime(monday.year, monday.month, monday.day);
    final endOfWeek = startOfWeek.add(const Duration(days: 7));

    final weekTurnos = turnos
        .where((t) =>
            !t.dateTime.isBefore(startOfWeek) &&
            t.dateTime.isBefore(endOfWeek))
        .toList();

    final weekCount = weekTurnos.length;
    final weekDeposits =
        weekTurnos.fold<double>(0, (sum, t) => sum + t.deposit);

    return context.isMobile
        ? _MobilePanel(
            next: next,
            weekCount: weekCount,
            weekDeposits: weekDeposits,
          )
        : _DesktopPanel(
            todayCount: today.length,
            next: next,
            weekCount: weekCount,
            weekDeposits: weekDeposits,
          );
  }
}

// ── Layout mobile ─────────────────────────────────────────────────────────────

class _MobilePanel extends StatelessWidget {
  const _MobilePanel({
    required this.next,
    required this.weekCount,
    required this.weekDeposits,
  });

  final Appointment? next;
  final int weekCount;
  final double weekDeposits;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Próximo turno
        Expanded(
          child: _Panel(
            icon: Icons.schedule_rounded,
            label: 'Próximo turno',
            content: next == null
                ? _PanelText('Sin más turnos hoy',
                    color: AppColors.secondary)
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _PanelText(
                        DateFormat('HH:mm').format(next!.dateTime),
                        bold: true,
                      ),
                      _PanelText(
                        next!.clientName,
                        maxLines: 1,
                      ),
                      _PanelText(
                        next!.service,
                        color: AppColors.secondary,
                        maxLines: 1,
                      ),
                    ],
                  ),
          ),
        ),
        const VerticalDivider(width: 1),
        // Esta semana
        Expanded(
          child: _Panel(
            icon: Icons.bar_chart_rounded,
            label: 'Esta semana',
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _PanelText('$weekCount turnos', bold: true),
                if (weekDeposits > 0)
                  _PanelText(
                    '\$${_fmt(weekDeposits)} en señas',
                    color: AppColors.secondary,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Layout desktop ────────────────────────────────────────────────────────────

class _DesktopPanel extends StatelessWidget {
  const _DesktopPanel({
    required this.todayCount,
    required this.next,
    required this.weekCount,
    required this.weekDeposits,
  });

  final int todayCount;
  final Appointment? next;
  final int weekCount;
  final double weekDeposits;

  @override
  Widget build(BuildContext context) {
    final nextLine1 = next == null
        ? 'Sin más turnos hoy'
        : DateFormat('HH:mm').format(next!.dateTime);
    final nextLine2 = next == null ? null : next!.clientName;
    final nextLine3 = next == null ? null : next!.service;

    final weekValue = weekDeposits > 0
        ? '$weekCount turnos · \$${_fmt(weekDeposits)}'
        : '$weekCount turnos';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          // Turnos hoy — Expanded obligatorio: _SummaryCard tiene Expanded interno
          Expanded(
            child: _SummaryCard(
              icon: Icons.event_available_rounded,
              label: 'Turnos hoy',
              value: '$todayCount',
            ),
          ),
          const SizedBox(width: 10),
          // Próximo turno — flex 2 para darle más espacio al texto
          Expanded(
            flex: 2,
            child: _SummaryCard(
              icon: Icons.schedule_rounded,
              label: 'Próximo turno',
              value: nextLine1,
              subtitle: nextLine2,
              caption: nextLine3,
            ),
          ),
          const SizedBox(width: 10),
          // Esta semana
          Expanded(
            child: _SummaryCard(
              icon: Icons.bar_chart_rounded,
              label: 'Esta semana',
              value: weekValue,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Componentes compartidos ──────────────────────────────────────────────────

/// Card para desktop: borde izquierdo violeta + ícono + textos.
class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.icon,
    required this.label,
    required this.value,
    this.subtitle,
    this.caption,
  });

  final IconData icon;
  final String label;
  final String value;
  final String? subtitle;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.accentLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.accent, size: 17),
          ),
          const SizedBox(width: 10),
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
                Text(value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary)),
                if (subtitle != null)
                  Text(subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.primary)),
                if (caption != null)
                  Text(caption!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.secondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Panel para mobile: fondo plano con ícono + label + contenido flexible.
class _Panel extends StatelessWidget {
  const _Panel({
    required this.icon,
    required this.label,
    required this.content,
  });

  final IconData icon;
  final String label;
  final Widget content;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: AppColors.accent),
              const SizedBox(width: 5),
              Text(label,
                  style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.accent,
                      fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 6),
          content,
        ],
      ),
    );
  }
}

class _PanelText extends StatelessWidget {
  const _PanelText(
    this.text, {
    this.bold = false,
    this.color,
    this.maxLines,
  });

  final String text;
  final bool bold;
  final Color? color;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: maxLines,
      overflow: maxLines != null ? TextOverflow.ellipsis : null,
      style: TextStyle(
        fontSize: bold ? 15 : 12,
        fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
        color: color ?? AppColors.primary,
      ),
    );
  }
}

/// Formatea un monto sin decimales. Ej: 2500.0 → "2.500"
String _fmt(double v) {
  final s = v.toStringAsFixed(0);
  // Insertar puntos de miles cada 3 dígitos desde la derecha.
  final buffer = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buffer.write('.');
    buffer.write(s[i]);
  }
  return buffer.toString();
}
