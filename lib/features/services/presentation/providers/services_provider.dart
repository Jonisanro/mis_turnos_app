import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mis_turnos_app/features/login/presentation/providers/login_provider.dart';
import 'package:mis_turnos_app/features/services/data/datasources/services_data_source.dart';
import 'package:mis_turnos_app/features/services/data/models/service_model.dart';
import 'package:mis_turnos_app/features/services/data/repositories/services_repository_impl.dart';
import 'package:mis_turnos_app/features/services/domain/entities/service.dart';
import 'package:mis_turnos_app/features/services/domain/repositories/services_repository.dart';

final servicesDataSourceProvider = Provider<ServicesDataSource>((ref) {
  return ServicesRemoteDataSourceImpl();
});

final servicesRepositoryProvider = Provider<ServicesRepository>((ref) {
  return ServicesRepositoryImpl(
      dataSource: ref.watch(servicesDataSourceProvider));
});

final servicesProvider =
    AsyncNotifierProvider<ServicesNotifier, List<Service>>(
        ServicesNotifier.new);

class ServicesNotifier extends AsyncNotifier<List<Service>> {
  String? get _ownerId => ref.read(loginProvider).currentUser?.uid;

  @override
  Future<List<Service>> build() async {
    final user = ref.watch(authStateProvider).value;
    if (user == null) return [];
    return ref.read(servicesRepositoryProvider).getServices(user.uid);
  }

  Future<void> _reload() async {
    final ownerId = _ownerId;
    if (ownerId == null) {
      state = const AsyncData([]);
      return;
    }
    state = const AsyncLoading();
    state = await AsyncValue.guard(
        () => ref.read(servicesRepositoryProvider).getServices(ownerId));
  }

  /// Crea o actualiza un servicio del usuario autenticado.
  Future<void> saveService(ServiceModel service) async {
    await ref.read(servicesRepositoryProvider).saveService(service);
    await _reload();
  }

  Future<void> deleteService(String id) async {
    await ref.read(servicesRepositoryProvider).deleteService(id);
    await _reload();
  }
}
