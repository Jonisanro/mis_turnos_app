import 'package:mis_turnos_app/features/services/data/datasources/services_data_source.dart';
import 'package:mis_turnos_app/features/services/data/models/service_model.dart';
import 'package:mis_turnos_app/features/services/domain/entities/service.dart';
import 'package:mis_turnos_app/features/services/domain/repositories/services_repository.dart';

class ServicesRepositoryImpl implements ServicesRepository {
  final ServicesDataSource dataSource;

  ServicesRepositoryImpl({required this.dataSource});

  @override
  Future<List<Service>> getServices(String ownerId) {
    return dataSource.getServices(ownerId);
  }

  @override
  Future<void> saveService(ServiceModel service) {
    return dataSource.saveService(service);
  }

  @override
  Future<void> deleteService(String id) {
    return dataSource.deleteService(id);
  }
}
