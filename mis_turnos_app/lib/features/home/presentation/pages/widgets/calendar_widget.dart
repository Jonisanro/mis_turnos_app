import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(appointmentsProvider.notifier).reload();
    });
  }

  Future<void> _openNewAppointmentDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (context) => const NewAppointmentDialogWidget(),
    );

    // Recargar turnos después de cerrar el diálogo
    if (mounted) {
      ref.read(appointmentsProvider.notifier).reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    final turnosState = ref.watch(appointmentsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Turnos')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (turnosState is AsyncLoading) const LinearProgressIndicator(),
          Expanded(
            child: turnosState.when(
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

                return Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                          ),
                          onPressed: () => _openNewAppointmentDialog(context),
                          child: const Text('Agendar Turno'),
                        ),
                      ],
                    ),
                    Expanded(
                      child: SfCalendarWidget(appointments: turnos),
                    ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ref.read(appointmentsProvider.notifier).reload();
        },
        child: const Icon(Icons.refresh),
      ),
    );
  }
}

class SfCalendarWidget extends StatelessWidget {
  final List<model.Appointment> appointments;
  const SfCalendarWidget({required this.appointments, super.key});

  @override
  Widget build(BuildContext context) {
    return SfCalendar(
      cellBorderColor: Colors.black,
      backgroundColor: Colors.pink[50],
      scheduleViewMonthHeaderBuilder:
          (BuildContext buildContext, ScheduleViewMonthHeaderDetails details) {
        return Container(
          color: Colors.red,
          child: Text(
            '${details.date.month} / ${details.date.year}',
            style: const TextStyle(color: Colors.white),
          ),
        );
      },
      timeSlotViewSettings: const TimeSlotViewSettings(
        timeInterval: Duration(minutes: 30),
      ),
      view: CalendarView.week,
      allowedViews: const [CalendarView.week, CalendarView.day],
      dataSource: AppointmentsDataSource(appointments),
      appointmentBuilder: _buildAppointment,
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
        subject: appointment.clientName,
        startTime: appointment.dateTime,
        deposit: appointment.deposit,
        endTime:
            appointment.dateTime.add(Duration(minutes: appointment.duration)),
        color: appointment.hasPaid ? Colors.green : Colors.red,
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
