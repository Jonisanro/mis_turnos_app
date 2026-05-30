import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mis_turnos_app/features/home/data/datasources/appointments_data_source.dart';
import 'package:mis_turnos_app/features/home/data/models/appointment_model.dart';
import 'package:mis_turnos_app/features/home/domain/entities/appointment.dart';
import 'package:mis_turnos_app/features/home/domain/repositories/appointments_repository.dart';

class AppointmentsRepositoryImpl implements AppointmentsRepository {
  final AppointmentsDataSource remoteDataSource;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  AppointmentsRepositoryImpl({required this.remoteDataSource});

  Appointment _toEntity(AppointmentModel appointment) => Appointment(
        id: appointment.id,
        clientName: appointment.clientName,
        phone: appointment.phone,
        dateTime: appointment.dateTime,
        duration: appointment.duration,
        hasPaid: appointment.hasPaid,
        deposit: appointment.deposit,
        service: appointment.service,
        status: appointment.status,
        comments: appointment.comments,
        owner: appointment.owner,
      );

  @override
  Future<List<Appointment>> obtenerTurnos(String ownerId) async {
    try {
      final turnosModel = await remoteDataSource.getAppointments(ownerId);
      return turnosModel.map(_toEntity).toList();
    } catch (e) {
      throw Exception('Error al obtener turnos: $e');
    }
  }

  @override
  Stream<List<Appointment>> watchTurnos(String ownerId) {
    return remoteDataSource
        .watchAppointments(ownerId)
        .map((models) => models.map(_toEntity).toList());
  }

  @override
  Future<void> agregarTurno(AppointmentModel turno) async {
    await _firestore.collection('appointment').doc(turno.id).set(turno.toMap());
  }

  @override
  Future<void> editarTurno(AppointmentModel turno) async {
    await _firestore.collection('appointment').doc(turno.id).set(turno.toMap());
  }

  @override
  Future<void> eliminarTurno(String id) async {
    await _firestore.collection('appointment').doc(id).delete();
  }
}
