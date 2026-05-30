import 'package:mis_turnos_app/features/services/data/models/service_model.dart';
import 'package:mis_turnos_app/features/services/domain/entities/service.dart';

abstract class ServicesRepository {
  Future<List<Service>> getServices(String ownerId);
  Future<void> saveService(ServiceModel service);
  Future<void> deleteService(String id);
}
