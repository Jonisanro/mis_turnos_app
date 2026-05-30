import 'package:mis_turnos_app/features/home/data/models/appointment_model.dart';
import 'package:mis_turnos_app/features/home/presentation/providers/appointments_repository_provider.dart';
import 'package:mis_turnos_app/features/login/presentation/providers/login_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:mis_turnos_app/features/home/domain/entities/appointment.dart';
import 'package:mis_turnos_app/features/home/presentation/providers/get_appointments_usecase_provider.dart';

part 'appointments_provider.g.dart';

@riverpod
class Appointments extends _$Appointments {
  @override
  Stream<List<Appointment>> build() {
    // Se reconstruye al cambiar la sesión (login / logout) y emite en tiempo
    // real al cambiar los turnos en Firestore.
    final user = ref.watch(authStateProvider).value;
    if (user == null) return Stream.value(<Appointment>[]);
    final usecase = ref.watch(getAppointmentsUsecaseProviderProvider);
    return usecase.watch(user.uid);
  }

  // Las mutaciones no necesitan recargar: el stream de Firestore actualiza la
  // lista automáticamente.
  Future<void> addAppointment(AppointmentModel newTurno) {
    return ref.read(appointmentsRepositoryProvider).agregarTurno(newTurno);
  }

  Future<void> editAppointment(AppointmentModel turno) {
    return ref.read(appointmentsRepositoryProvider).editarTurno(turno);
  }

  Future<void> deleteAppointment(String id) {
    return ref.read(appointmentsRepositoryProvider).eliminarTurno(id);
  }
}
