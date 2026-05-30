import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mis_turnos_app/features/home/data/models/appointment_model.dart';

abstract class AppointmentsDataSource {
  Future<List<AppointmentModel>> getAppointments(String ownerId);

  /// Stream en tiempo real de los turnos del usuario.
  Stream<List<AppointmentModel>> watchAppointments(String ownerId);

  /// Crea o reemplaza un turno.
  Future<void> addAppointment(AppointmentModel turno);

  /// Actualiza un turno existente (mismo id).
  Future<void> updateAppointment(AppointmentModel turno);

  /// Elimina el turno con el id dado.
  Future<void> deleteAppointment(String id);
}

class AppointmentRemoteDataSourceImpl implements AppointmentsDataSource {
  /// [firestore] es inyectable para poder usar un fake en tests; en producción
  /// usa la instancia por defecto.
  AppointmentRemoteDataSourceImpl({FirebaseFirestore? firestore})
      : _firebaseFirestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firebaseFirestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firebaseFirestore.collection('appointment');

  Query<Map<String, dynamic>> _ownerQuery(String ownerId) =>
      _collection.where('owner', isEqualTo: ownerId);

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

  @override
  Future<void> addAppointment(AppointmentModel turno) async {
    await _collection.doc(turno.id).set(turno.toMap());
  }

  @override
  Future<void> updateAppointment(AppointmentModel turno) async {
    await _collection.doc(turno.id).set(turno.toMap());
  }

  @override
  Future<void> deleteAppointment(String id) async {
    await _collection.doc(id).delete();
  }
}
