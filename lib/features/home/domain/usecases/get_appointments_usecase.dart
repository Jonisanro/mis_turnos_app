import 'package:mis_turnos_app/features/home/domain/entities/appointment.dart';
import 'package:mis_turnos_app/features/home/domain/repositories/appointments_repository.dart';

class GetAppointmentsUsecase {
  final AppointmentsRepository repository;

  GetAppointmentsUsecase({required this.repository});

  Future<List<Appointment>> call(String ownerId) async {
    return await repository.obtenerTurnos(ownerId);
  }

  /// Stream en tiempo real de los turnos del usuario.
  Stream<List<Appointment>> watch(String ownerId) {
    return repository.watchTurnos(ownerId);
  }
}
