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
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                  ),
                  onPressed: () => _openNewAppointmentDialog(context),
                  child: const Text('Agendar Turno'),
                ),
              ],
            ),
          );
        }

        return SfCalendarWidget(
          appointments: turnos,
          headerTrailing: ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
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
    final defaultView =
        context.isMobile ? CalendarView.day : CalendarView.week;
    final monthYearLabel = DateFormat('MMMM yyyy', 'es').format(_visibleDate);
    // Capitalizar primera letra del mes
    final monthYearDisplay =
        '${monthYearLabel[0].toUpperCase()}${monthYearLabel.substring(1)}';

    return Column(
      children: [
        // Header: mes centrado, botón a la derecha
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            children: [
              Expanded(child: const SizedBox.shrink()),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: () => _calendarController.backward?.call(),
                    icon: const Icon(Icons.arrow_back_ios),
                    tooltip: 'Semana/día anterior',
                    padding: const EdgeInsets.all(8.0),
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    monthYearDisplay,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    onPressed: () => _calendarController.forward?.call(),
                    icon: const Icon(Icons.arrow_forward_ios),
                    tooltip: 'Semana/día siguiente',
                    padding: const EdgeInsets.all(8.0),
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: widget.headerTrailing ?? const SizedBox.shrink(),
                ),
              ),
            ],
          ),
        ),
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
            view: defaultView,
            allowedViews: const [CalendarView.week, CalendarView.day],
            dataSource: AppointmentsDataSource(widget.appointments),
            appointmentBuilder: _buildAppointment,
            onTap: _handleTap,
            onViewChanged: (ViewChangedDetails details) {
              if (details.visibleDates.isEmpty) return;
              final newDate = details.visibleDates.first;
              // Diferir setState: onViewChanged puede dispararse durante el build del calendario.
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

Widget _buildAppointment(BuildContext context,
    CalendarAppointmentDetails calendarAppointmentDetails) {
  final CustomAppointment customAppointment =
      calendarAppointmentDetails.appointments.first as CustomAppointment;

  return CustomAppointmentWidget(
    service: customAppointment.service,
    clientName: customAppointment.subject,
    deposit: customAppointment.deposit,
    color: customAppointment.color,
    owner: customAppointment.owner,
  );
}
