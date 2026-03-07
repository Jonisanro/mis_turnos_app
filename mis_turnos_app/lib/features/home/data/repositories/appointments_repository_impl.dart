import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mis_turnos_app/features/home/data/datasources/appointments_data_source.dart';
import 'package:mis_turnos_app/features/home/data/models/appointment_model.dart';
import 'package:mis_turnos_app/features/home/domain/entities/appointment.dart';
import 'package:mis_turnos_app/features/home/domain/repositories/appointments_repository.dart';

class AppointmentsRepositoryImpl implements AppointmentsRepository {
  final AppointmentsDataSource remoteDataSource;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  AppointmentsRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<Appointment>> obtenerTurnos() async {
    try {
      final turnosModel = await remoteDataSource.getAppointments();
      return turnosModel
          .map((appointment) => Appointment(
              deposit: appointment.deposit,
              id: appointment.id,
              clientName: appointment.clientName,
              dateTime: appointment.dateTime,
              duration: appointment.duration,
              hasPaid: appointment.hasPaid,
              service: appointment.service,
              status: appointment.status,
              comments: appointment.comments,
              owner: appointment.owner))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener turnos: $e');
    }
  }

  @override
  Future<void> agregarTurno(AppointmentModel turno) async {
    await _firestore.collection('appointment').doc(turno.id).set(turno.toMap());
  }
}
