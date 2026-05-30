import 'package:mis_turnos_app/features/home/data/models/appointment_model.dart';
import 'package:mis_turnos_app/features/home/domain/entities/appointment.dart';
import 'package:mis_turnos_app/features/services/domain/entities/service.dart';

/// Builder de [AppointmentModel] para tests, con valores por defecto razonables.
AppointmentModel makeAppointmentModel({
  String id = 'appt-1',
  String clientName = 'Soledad',
  String phone = '',
  DateTime? dateTime,
  int duration = 60,
  bool hasPaid = false,
  double deposit = 0,
  String service = 'Corte de pelo',
  String status = 'pendiente',
  String comments = '',
  String owner = 'uid-1',
}) {
  return AppointmentModel(
    id: id,
    clientName: clientName,
    phone: phone,
    dateTime: dateTime ?? DateTime(2026, 5, 30, 10, 0),
    duration: duration,
    hasPaid: hasPaid,
    deposit: deposit,
    service: service,
    status: status,
    comments: comments,
    owner: owner,
  );
}

/// Builder de la entidad [Appointment] para tests (modo edición del diálogo, etc.).
Appointment makeAppointment({
  String id = 'appt-1',
  String clientName = 'Soledad',
  String phone = '',
  DateTime? dateTime,
  int duration = 60,
  bool hasPaid = false,
  double deposit = 0,
  String service = 'Corte de pelo',
  String status = 'pendiente',
  String comments = '',
  String owner = 'uid-1',
}) {
  return Appointment(
    id: id,
    clientName: clientName,
    phone: phone,
    dateTime: dateTime ?? DateTime(2026, 5, 30, 10, 0),
    duration: duration,
    hasPaid: hasPaid,
    deposit: deposit,
    service: service,
    status: status,
    comments: comments,
    owner: owner,
  );
}

/// Builder de [Service] para poblar el selector del diálogo.
Service makeService({
  String id = 'svc-1',
  String name = 'Corte de pelo',
  double price = 3000,
  int durationMinutes = 60,
  String owner = 'uid-1',
}) {
  return Service(
    id: id,
    name: name,
    price: price,
    durationMinutes: durationMinutes,
    owner: owner,
  );
}
