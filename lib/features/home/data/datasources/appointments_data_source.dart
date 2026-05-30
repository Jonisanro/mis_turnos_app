import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mis_turnos_app/features/home/data/models/appointment_model.dart';

abstract class AppointmentsDataSource {
  Future<List<AppointmentModel>> getAppointments(String ownerId);

  /// Stream en tiempo real de los turnos del usuario.
  Stream<List<AppointmentModel>> watchAppointments(String ownerId);
}

class AppointmentRemoteDataSourceImpl implements AppointmentsDataSource {
  final FirebaseFirestore _firebaseFirestore = FirebaseFirestore.instance;

  Query<Map<String, dynamic>> _ownerQuery(String ownerId) =>
      _firebaseFirestore
          .collection('appointment')
          .where('owner', isEqualTo: ownerId);

  @override
  Future<List<AppointmentModel>> getAppointments(String ownerId) async {
    try {
      final snapshot = await _ownerQuery(ownerId).get();
      return snapshot.docs
          .map((doc) => AppointmentModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener turnos: $e');
    }
  }

  @override
  Stream<List<AppointmentModel>> watchAppointments(String ownerId) {
    return _ownerQuery(ownerId).snapshots().map((snapshot) => snapshot.docs
        .map((doc) => AppointmentModel.fromMap(doc.data()))
        .toList());
  }
}
