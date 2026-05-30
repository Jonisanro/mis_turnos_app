import 'dart:ui';

import 'package:syncfusion_flutter_calendar/calendar.dart';

class CustomAppointment extends Appointment {
  final String id;
  final String service;
  final String status;
  final String owner;
  final String phone;
  final bool hasPaid;
  final double deposit;

  CustomAppointment({
    required this.id,
    required this.service,
    required this.status,
    required this.owner,
    required this.phone,
    required this.hasPaid,
    required this.deposit,
    required String subject,
    required DateTime startTime,
    required DateTime endTime,
    required Color color,
    String? notes,
    bool isAllDay = false,
  }) : super(
          subject: subject,
          startTime: startTime,
          endTime: endTime,
          color: color,
          notes: notes,
          isAllDay: isAllDay,
        );
}
