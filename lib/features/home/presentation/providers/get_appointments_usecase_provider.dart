import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:mis_turnos_app/features/home/domain/usecases/get_appointments_usecase.dart';
import 'appointments_repository_provider.dart';

part 'get_appointments_usecase_provider.g.dart';

@riverpod
class GetAppointmentsUsecaseProvider extends _$GetAppointmentsUsecaseProvider {
  @override
  GetAppointmentsUsecase build() {
    return GetAppointmentsUsecase(
        repository: ref.watch(appointmentsRepositoryProvider));
  }
}
