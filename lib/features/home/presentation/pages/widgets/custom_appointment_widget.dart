import 'package:flutter/material.dart';
import 'package:mis_turnos_app/core/theme/app_theme.dart';

class CustomAppointmentWidget extends StatelessWidget {
  final String clientName;
  final Color color; // color de estado (success / warning / error)
  final String owner;
  final String service;
  final double deposit;

  const CustomAppointmentWidget({
    super.key,
    required this.owner,
    required this.clientName,
    required this.deposit,
    required this.color,
    required this.service,
  });

  String get _tooltipMessage =>
      '$clientName\n$service${deposit > 0 ? '\nSeña: \$${deposit.toStringAsFixed(0)}' : ''}';

  static const double _minHeightForFullContent = 52.0;
  static const double _minWidthForFullContent = 100.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxHeight < _minHeightForFullContent ||
            constraints.maxWidth < _minWidthForFullContent;

        final content = Container(
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(6),
            border: Border(
              left: BorderSide(color: color, width: 3),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          child: compact
              ? Text(
                  clientName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color.withValues(alpha: 0.9),
                  ),
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      clientName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: color.withValues(alpha: 0.9),
                      ),
                    ),
                    if (service.isNotEmpty)
                      Text(
                        service,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.secondary,
                        ),
                      ),
                    if (deposit > 0)
                      Text(
                        'Seña \$${deposit.toStringAsFixed(0)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.secondary,
                        ),
                      ),
                  ],
                ),
        );

        if (compact) {
          return Tooltip(
            triggerMode: TooltipTriggerMode.tap,
            message: _tooltipMessage,
            preferBelow: false,
            child: content,
          );
        }
        return content;
      },
    );
  }
}
