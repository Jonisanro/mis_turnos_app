import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mis_turnos_app/features/services/data/models/service_model.dart';

abstract class ServicesDataSource {
  Future<List<ServiceModel>> getServices(String ownerId);
  Future<void> saveService(ServiceModel service);
  Future<void> deleteService(String id);
}

class ServicesRemoteDataSourceImpl implements ServicesDataSource {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('services');

  @override
  Future<List<ServiceModel>> getServices(String ownerId) async {
    try {
      final snapshot =
          await _collection.where('owner', isEqualTo: ownerId).get();
      return snapshot.docs
          .map((doc) => ServiceModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener servicios: $e');
    }
  }

  @override
  Future<void> saveService(ServiceModel service) async {
    await _collection.doc(service.id).set(service.toMap());
  }

  @override
  Future<void> deleteService(String id) async {
    await _collection.doc(id).delete();
  }
}
