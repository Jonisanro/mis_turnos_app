import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mis_turnos_app/features/home/data/datasources/appointments_data_source.dart';
import 'package:mis_turnos_app/features/home/domain/entities/appointment.dart';
import 'package:mis_turnos_app/features/home/presentation/providers/appointments_datasource_provider.dart';
import 'package:mis_turnos_app/features/home/presentation/providers/appointments_provider.dart';
import 'package:mis_turnos_app/features/login/presentation/providers/login_provider.dart';

import '../../helpers/appointment_factory.dart';
import '../../helpers/fakes.dart';
import '../../helpers/test_harness.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late AppointmentRemoteDataSourceImpl ds;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    ds = AppointmentRemoteDataSourceImpl(firestore: firestore);
  });

  ProviderContainer buildContainer({User? user}) {
    final container = makeContainer(
      overrides: [
        authStateProvider.overrideWith((ref) => Stream<User?>.value(user)),
        appointmentsDatasourceProvider.overrideWithValue(ds),
      ],
    );
    addTearDown(container.dispose);
    // Mantener vivo el provider para que el stream siga activo.
    final sub = container.listen(appointmentsProvider, (_, __) {});
    addTearDown(sub.close);
    return container;
  }

  /// Espera (con timeout) hasta que el valor del provider cumpla [cond].
  Future<List<Appointment>> readWhen(
    ProviderContainer c,
    bool Function(List<Appointment>) cond,
  ) async {
    for (var i = 0; i < 100; i++) {
      final v = c.read(appointmentsProvider).valueOrNull;
      if (v != null && cond(v)) return v;
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    throw StateError(
      'Condición no cumplida. Último valor: '
      '${c.read(appointmentsProvider).valueOrNull}',
    );
  }

  test('sin sesión el stream emite lista vacía', () async {
    final c = buildContainer(user: null);
    final v = await c.read(appointmentsProvider.future);
    expect(v, isEmpty);
  });

  test('addAppointment agrega el turno propio y oculta los ajenos', () async {
    // Turno de otro usuario ya presente en Firestore.
    await ds.addAppointment(makeAppointmentModel(id: 'ajeno', owner: 'uid-2'));

    final c = buildContainer(user: buildMockUser(uid: 'uid-1'));

    await c.read(appointmentsProvider.notifier).addAppointment(
          makeAppointmentModel(id: 'a1', owner: 'uid-1', clientName: 'Soledad'),
        );

    final list = await readWhen(c, (l) => l.any((a) => a.id == 'a1'));
    expect(list.map((a) => a.id).toList(), ['a1']);
    expect(list.every((a) => a.owner == 'uid-1'), isTrue);
  });

  test('editAppointment actualiza y deleteAppointment elimina', () async {
    final c = buildContainer(user: buildMockUser(uid: 'uid-1'));
    final notifier = c.read(appointmentsProvider.notifier);

    await notifier.addAppointment(
      makeAppointmentModel(id: 'a1', owner: 'uid-1', clientName: 'Ana'),
    );
    await readWhen(c, (l) => l.any((a) => a.id == 'a1'));

    await notifier.editAppointment(
      makeAppointmentModel(id: 'a1', owner: 'uid-1', clientName: 'Ana María'),
    );
    final edited = await readWhen(c, (l) => l.any((a) => a.clientName == 'Ana María'));
    expect(edited.single.clientName, 'Ana María');

    await notifier.deleteAppointment('a1');
    final afterDelete = await readWhen(c, (l) => l.isEmpty);
    expect(afterDelete, isEmpty);
  });
}
