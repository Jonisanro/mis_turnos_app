import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mis_turnos_app/features/home/data/datasources/appointments_data_source.dart';

import '../../helpers/appointment_factory.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late AppointmentRemoteDataSourceImpl ds;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    ds = AppointmentRemoteDataSourceImpl(firestore: firestore);
  });

  test('getAppointments solo devuelve los turnos del owner', () async {
    await ds.addAppointment(makeAppointmentModel(id: 'a1', owner: 'uid-1'));
    await ds.addAppointment(makeAppointmentModel(id: 'a2', owner: 'uid-2'));

    final result = await ds.getAppointments('uid-1');

    expect(result.map((e) => e.id).toList(), ['a1']);
    expect(result.single.owner, 'uid-1');
  });

  test('addAppointment persiste el documento', () async {
    await ds.addAppointment(
      makeAppointmentModel(id: 'a1', owner: 'uid-1', clientName: 'Soledad'),
    );

    final snap = await firestore.collection('appointment').doc('a1').get();
    expect(snap.exists, isTrue);
    expect(snap.data()!['clientName'], 'Soledad');
    expect(snap.data()!['owner'], 'uid-1');
  });

  test('updateAppointment sobrescribe el documento existente', () async {
    await ds.addAppointment(makeAppointmentModel(id: 'a1', clientName: 'Ana'));
    await ds.updateAppointment(
      makeAppointmentModel(id: 'a1', clientName: 'Ana María'),
    );

    final snap = await firestore.collection('appointment').doc('a1').get();
    expect(snap.data()!['clientName'], 'Ana María');
  });

  test('deleteAppointment elimina el documento', () async {
    await ds.addAppointment(makeAppointmentModel(id: 'a1'));
    await ds.deleteAppointment('a1');

    final snap = await firestore.collection('appointment').doc('a1').get();
    expect(snap.exists, isFalse);
  });

  test('watchAppointments emite la lista filtrada por owner al cambiar',
      () async {
    await ds.addAppointment(makeAppointmentModel(id: 'a1', owner: 'uid-1'));

    final stream = ds.watchAppointments('uid-1');

    await expectLater(
      stream,
      emits(predicate<List>((list) => list.length == 1)),
    );

    await ds.addAppointment(makeAppointmentModel(id: 'a2', owner: 'uid-1'));
    await ds.addAppointment(makeAppointmentModel(id: 'a3', owner: 'uid-2'));

    await expectLater(
      stream,
      emits(predicate<List>(
        (list) => list.length == 2 &&
            list.every((e) => (e as dynamic).owner == 'uid-1'),
      )),
    );
  });
}
