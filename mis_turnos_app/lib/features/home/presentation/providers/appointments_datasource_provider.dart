import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:mis_turnos_app/features/home/data/datasources/appointments_data_source.dart';

part 'appointments_datasource_provider.g.dart';

@riverpod
AppointmentsDataSource appointmentsDatasource(Ref ref) {
  return AppointmentRemoteDataSourceImpl();
}
