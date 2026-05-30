// lib/features/turnos/domain/repositories/turnos_repository.dart

import 'package:mis_turnos_app/features/home/data/models/appointment_model.dart';
import 'package:mis_turnos_app/features/home/domain/entities/appointment.dart';

abstract class AppointmentsRepository {
  Future<List<Appointment>> obtenerTurnos(String ownerId);
  Stream<List<Appointment>> watchTurnos(String ownerId);
  Future<void> agregarTurno(AppointmentModel turno);
  Future<void> editarTurno(AppointmentModel turno);
  Future<void> eliminarTurno(String id);
}
