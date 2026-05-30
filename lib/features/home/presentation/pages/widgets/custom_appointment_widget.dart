import 'package:flutter/material.dart';

class CustomAppointmentWidget extends StatelessWidget {
  final String clientName;
  final Color color;
  final String owner;
  final String service;
  final double deposit;

  const CustomAppointmentWidget({
    Key? key,
    required this.owner,
    required this.clientName,
    required this.deposit,
    required this.color,
    required this.service,
  }) : super(key: key);

  String get _tooltipMessage =>
      '$clientName\nServicio: $service\nSeña: \$${deposit.toStringAsFixed(0)}\nProfesional: $owner';

  /// Altura mínima aproximada para mostrar los 3 textos sin overflow (padding + 3 líneas).
  static const double _minHeightForFullContent = 58.0;

  /// Ancho mínimo para mostrar los 3 textos en columna sin overflow.
  static const double _minWidthForFullContent = 120.0;

  Widget _buildContent({required bool compact}) {
    final container = Container(
      padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(8.0),
      ),
      alignment: compact ? Alignment.centerLeft : null,
      child: compact
          ? Text(
              clientName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
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
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  service,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, color: Colors.white70),
                ),
                Text(
                  'Seña: \$${deposit.toStringAsFixed(0)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, color: Colors.white70),
                ),
              ],
            ),
    );

    if (compact) {
      return Tooltip(
        triggerMode: TooltipTriggerMode.tap,
        message: _tooltipMessage,
        preferBelow: false,
        child: container,
      );
    }
    return container;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final hasEnoughHeight =
            constraints.maxHeight >= _minHeightForFullContent;
        final hasEnoughWidth = constraints.maxWidth >= _minWidthForFullContent;
        final useCompact = !hasEnoughHeight || !hasEnoughWidth;
        return _buildContent(compact: useCompact);
      },
    );
  }
}
