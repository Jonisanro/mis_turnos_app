import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mis_turnos_app/core/theme/app_theme.dart';
import 'package:mis_turnos_app/core/constants/breakpoints.dart';
import 'package:mis_turnos_app/features/home/domain/entities/appointment.dart'
    as model;
import 'package:mis_turnos_app/features/home/presentation/models/custom_appointment_model.dart';
import 'package:mis_turnos_app/features/home/presentation/pages/widgets/custom_appointment_widget.dart';
import 'package:mis_turnos_app/features/home/presentation/pages/widgets/new_appointment_dialog_widget.dart';
import 'package:mis_turnos_app/features/home/presentation/providers/appointments_provider.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

class CalendarWidget extends ConsumerStatefulWidget {
  const CalendarWidget({super.key});

  @override
  _TurnosPageState createState() => _TurnosPageState();
}

class _TurnosPageState extends ConsumerState<CalendarWidget> {
  Future<void> _openNewAppointmentDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (context) => const NewAppointmentDialogWidget(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final turnosState = ref.watch(appointmentsProvider);

    return turnosState.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (turnos) {
        if (turnos.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('No hay turnos disponibles.'),
                const SizedBox(height: 20),
                if (!context.isMobile)
                  ElevatedButton(
                    onPressed: () => _openNewAppointmentDialog(context),
                    child: const Text('Agendar Turno'),
                  ),
              ],
            ),
          );
        }

        return SfCalendarWidget(
          appointments: turnos,
          headerTrailing: context.isMobile
              ? null
              : ElevatedButton(
                  onPressed: () => _openNewAppointmentDialog(context),
                  child: const Text('Agendar Turno'),
                ),
        );
      },
    );
  }
}

class SfCalendarWidget extends StatefulWidget {
  final List<model.Appointment> appointments;
  final Widget? headerTrailing;

  const SfCalendarWidget({
    required this.appointments,
    this.headerTrailing,
    super.key,
  });

  @override
  State<SfCalendarWidget> createState() => _SfCalendarWidgetState();
}

class _SfCalendarWidgetState extends State<SfCalendarWidget> {
  final CalendarController _calendarController = CalendarController();
  late DateTime _visibleDate;

  /// Vista actual. `null` = usar el default responsive (day en mobile, week en desktop).
  CalendarView? _currentView;

  @override
  void initState() {
    super.initState();
    _visibleDate = DateTime.now();
  }

  @override
  void dispose() {
    _calendarController.dispose();
    super.dispose();
  }

  CalendarView _effectiveView(BuildContext context) =>
      _currentView ?? (context.isMobile ? CalendarView.day : CalendarView.week);

  void _setView(CalendarView view) {
    // Cambiar el controller ES la forma correcta de cambiar la vista en Syncfusion.
    // Actualizar solo la prop `view:` del widget no es suficiente cuando hay controller.
    _calendarController.view = view;
    setState(() => _currentView = view);
  }

  /// Al tocar un turno existente, abre el diálogo en modo edición.
  void _handleTap(CalendarTapDetails details) {
    if (details.targetElement != CalendarElement.appointment) return;
    final tapped = details.appointments;
    if (tapped == null || tapped.isEmpty) return;
    final ca = tapped.first as CustomAppointment;

    final appointment = model.Appointment(
      id: ca.id,
      clientName: ca.subject,
      phone: ca.phone,
      dateTime: ca.startTime,
      duration: ca.endTime.difference(ca.startTime).inMinutes,
      hasPaid: ca.hasPaid,
      deposit: ca.deposit,
      service: ca.service,
      status: ca.status,
      comments: ca.notes ?? '',
      owner: ca.owner,
    );

    showDialog(
      context: context,
      builder: (_) => NewAppointmentDialogWidget(appointment: appointment),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = context.isMobile;
    final effectiveView = _effectiveView(context);
    final monthYearLabel = DateFormat('MMMM yyyy', 'es').format(_visibleDate);
    final monthYearDisplay =
        '${monthYearLabel[0].toUpperCase()}${monthYearLabel.substring(1)}';

    return Column(
      children: [
        // ── Header ────────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            children: [
              // Toggle día / semana
              _ViewToggle(
                current: effectiveView,
                onChanged: _setView,
                compact: isMobile,
              ),
              // Fecha centrada con navegación
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: () => _calendarController.backward?.call(),
                      icon: const Icon(Icons.arrow_back_ios, size: 16),
                      tooltip: effectiveView == CalendarView.day
                          ? 'Día anterior'
                          : 'Semana anterior',
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      monthYearDisplay,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () => _calendarController.forward?.call(),
                      icon: const Icon(Icons.arrow_forward_ios, size: 16),
                      tooltip: effectiveView == CalendarView.day
                          ? 'Día siguiente'
                          : 'Semana siguiente',
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
              // Botón acción (desktop) o espacio equivalente (mobile)
              SizedBox(
                // mismo ancho que el toggle para que la fecha quede centrada
                width: isMobile ? _ViewToggle.compactWidth : _ViewToggle.fullWidth,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: widget.headerTrailing,
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        // ── Calendario ────────────────────────────────────────────────────
        Expanded(
          child: SfCalendar(
            controller: _calendarController,
            initialDisplayDate: DateTime.now(),
            headerHeight: 0,
            cellBorderColor: AppColors.border,
            backgroundColor: AppColors.background,
            todayHighlightColor: AppColors.accent,
            selectionDecoration: BoxDecoration(
              border: Border.all(color: AppColors.accent, width: 2),
              borderRadius: BorderRadius.circular(4),
            ),
            timeSlotViewSettings: const TimeSlotViewSettings(
              timeInterval: Duration(minutes: 60),
              timeIntervalHeight: 80,
              timeTextStyle: TextStyle(
                fontSize: 12,
                color: AppColors.secondary,
                fontWeight: FontWeight.w400,
              ),
            ),
            view: effectiveView,
            dataSource: AppointmentsDataSource(widget.appointments),
            appointmentBuilder: _buildAppointment,
            onTap: _handleTap,
            onViewChanged: (ViewChangedDetails details) {
              if (details.visibleDates.isEmpty) return;
              final newDate = details.visibleDates.first;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted && _visibleDate != newDate) {
                  setState(() => _visibleDate = newDate);
                }
              });
            },
          ),
        ),
      ],
    );
  }
}

/// Toggle segmentado para cambiar entre vista día y semana.
class _ViewToggle extends StatelessWidget {
  const _ViewToggle({
    required this.current,
    required this.onChanged,
    this.compact = false,
  });

  final CalendarView current;
  final ValueChanged<CalendarView> onChanged;

  /// Si `true` muestra solo íconos (mobile); si `false` muestra ícono + texto.
  final bool compact;

  static const double compactWidth = 80;
  static const double fullWidth = 140;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<CalendarView>(
      style: SegmentedButton.styleFrom(
        backgroundColor: AppColors.surface,
        selectedBackgroundColor: AppColors.accentLight,
        selectedForegroundColor: AppColors.accent,
        foregroundColor: AppColors.secondary,
        side: const BorderSide(color: AppColors.border),
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 8 : 12,
          vertical: 6,
        ),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        visualDensity: VisualDensity.compact,
      ),
      segments: [
        ButtonSegment<CalendarView>(
          value: CalendarView.day,
          icon: const Icon(Icons.view_day_outlined, size: 16),
          label: compact ? null : const Text('Día'),
          tooltip: 'Vista diaria',
        ),
        ButtonSegment<CalendarView>(
          value: CalendarView.week,
          icon: const Icon(Icons.view_week_outlined, size: 16),
          label: compact ? null : const Text('Semana'),
          tooltip: 'Vista semanal',
        ),
      ],
      selected: {current},
      onSelectionChanged: (selection) => onChanged(selection.first),
      showSelectedIcon: false,
    );
  }
}

class AppointmentsDataSource extends CalendarDataSource {
  AppointmentsDataSource(List<model.Appointment> appointments) {
    this.appointments = appointments.map((appointment) {
      return CustomAppointment(
        hasPaid: appointment.hasPaid,
        id: appointment.id,
        service: appointment.service,
        status: appointment.status,
        owner: appointment.owner,
        phone: appointment.phone,
        subject: appointment.clientName,
        startTime: appointment.dateTime,
        deposit: appointment.deposit,
        endTime:
            appointment.dateTime.add(Duration(minutes: appointment.duration)),
        color: appointmentColor(appointment.hasPaid, appointment.deposit),
        notes: appointment.comments,
      );
    }).toList();
  }
}

Widget _buildAppointment(
  BuildContext context,
  CalendarAppointmentDetails calendarAppointmentDetails,
) {
  final CustomAppointment ca =
      calendarAppointmentDetails.appointments.first as CustomAppointment;

  return CustomAppointmentWidget(
    service: ca.service,
    clientName: ca.subject,
    deposit: ca.deposit,
    color: ca.color,
    owner: ca.owner,
  );
}
