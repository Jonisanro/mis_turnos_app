import 'package:mis_turnos_app/features/home/data/models/appointment_model.dart';
import 'package:mis_turnos_app/features/home/presentation/providers/appointments_repository_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:mis_turnos_app/features/home/domain/entities/appointment.dart';
import 'package:mis_turnos_app/features/home/presentation/providers/get_appointments_usecase_provider.dart';

part 'appointments_provider.g.dart';

@riverpod
class Appointments extends _$Appointments {
  @override
  FutureOr<List<Appointment>> build() async {
    final usecase = ref.watch(getAppointmentsUsecaseProviderProvider);
    return usecase();
  }

  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final usecase = ref.watch(getAppointmentsUsecaseProviderProvider);
      return await usecase();
    });
  }

  Future<void> addAppointment(AppointmentModel newTurno) async {
    final repo = ref.watch(appointmentsRepositoryProvider);
    await repo.agregarTurno(newTurno);
    await reload(); // actualiza lista
  }
}
