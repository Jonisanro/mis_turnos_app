import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mis_turnos_app/features/home/domain/repositories/appointments_repository.dart';
import 'package:mis_turnos_app/features/home/data/repositories/appointments_repository_impl.dart';
import 'appointments_datasource_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'appointments_repository_provider.g.dart';

@riverpod
AppointmentsRepository appointmentsRepository(Ref ref) {
  final datasource = ref.watch(appointmentsDatasourceProvider);
  return AppointmentsRepositoryImpl(remoteDataSource: datasource);
}
