import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mis_turnos_app/features/home/data/models/appointment_model.dart';

abstract class AppointmentsDataSource {
  Future<List<AppointmentModel>> getAppointments();
}

class AppointmentRemoteDataSourceImpl implements AppointmentsDataSource {
  final FirebaseFirestore _firebaseFirestore = FirebaseFirestore.instance;

  @override
  Future<List<AppointmentModel>> getAppointments() async {
    try {
      QuerySnapshot snapshot =
          await _firebaseFirestore.collection('appointment').get();

      return snapshot.docs
          .map((doc) =>
              AppointmentModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener turnos: $e');
    }
  }
}
