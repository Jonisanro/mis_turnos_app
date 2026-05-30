import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mis_turnos_app/features/home/data/datasources/appointments_data_source.dart';
import 'package:mis_turnos_app/features/home/domain/entities/appointment.dart';
import 'package:mis_turnos_app/features/home/presentation/pages/widgets/new_appointment_dialog_widget.dart';
import 'package:mis_turnos_app/features/home/presentation/providers/appointments_datasource_provider.dart';
import 'package:mis_turnos_app/features/login/presentation/providers/login_provider.dart';
import 'package:mis_turnos_app/features/services/presentation/providers/services_provider.dart';

import '../../helpers/appointment_factory.dart';
import '../../helpers/fakes.dart';
import '../../helpers/test_harness.dart';

/// Host con un botón que abre el diálogo como ruta (showDialog), para que
/// Navigator.pop y los SnackBars se comporten como en producción.
class _Host extends StatelessWidget {
  const _Host({this.appointment});
  final Appointment? appointment;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Builder(
          builder: (ctx) => ElevatedButton(
            onPressed: () => showDialog(
              context: ctx,
              builder: (_) =>
                  NewAppointmentDialogWidget(appointment: appointment),
            ),
            child: const Text('OPEN'),
          ),
        ),
      ),
    );
  }
}

void main() {
  late FakeFirebaseFirestore firestore;
  late AppointmentRemoteDataSourceImpl ds;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    ds = AppointmentRemoteDataSourceImpl(firestore: firestore);
  });

  List<Override> overrides({
    bool signedIn = true,
    String uid = 'uid-1',
  }) =>
      [
        loginProvider
            .overrideWithValue(buildAuthService(signedIn: signedIn, uid: uid)),
        appointmentsDatasourceProvider.overrideWithValue(ds),
        servicesProvider.overrideWith(
          () => FakeServicesNotifier([makeService(name: 'Corte de pelo')]),
        ),
      ];

  /// Monta el host con una superficie amplia (layout desktop) para que la fila
  /// de acciones del diálogo no haga overflow.
  Future<void> pumpHost(
    WidgetTester tester, {
    Appointment? appointment,
    required List<Override> overrides,
  }) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(wrapWithProviders(
      _Host(appointment: appointment),
      overrides: overrides,
    ));
  }

  Future<void> openDialog(WidgetTester tester) async {
    await tester.tap(find.text('OPEN'));
    await tester.pumpAndSettle();
  }

  testWidgets('editar turno guarda los cambios y preserva el owner',
      (tester) async {
    // Usuario logueado distinto del owner del turno → el owner NO debe cambiar.
    await pumpHost(
      tester,
      appointment: makeAppointment(id: 'appt-1', owner: 'uid-1'),
      overrides: overrides(uid: 'uid-2'),
    );
    await openDialog(tester);

    expect(find.text('Editar Turno'), findsOneWidget);

    // El label del campo es Text.rich, así que ubicamos el primer TextFormField
    // (nombre y apellido) por posición.
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'Soledad Actualizada',
    );
    await tester.tap(find.widgetWithText(ElevatedButton, 'Guardar cambios'));
    await tester.pumpAndSettle();

    expect(find.text('✅ Turno actualizado'), findsOneWidget);

    final snap = await firestore.collection('appointment').doc('appt-1').get();
    expect(snap.data()!['clientName'], 'Soledad Actualizada');
    expect(snap.data()!['owner'], 'uid-1'); // preservado
  });

  testWidgets('eliminar turno pide confirmación y borra el documento',
      (tester) async {
    await firestore
        .collection('appointment')
        .doc('appt-1')
        .set(makeAppointmentModel(id: 'appt-1', owner: 'uid-1').toMap());

    await pumpHost(
      tester,
      appointment: makeAppointment(id: 'appt-1', owner: 'uid-1'),
      overrides: overrides(uid: 'uid-1'),
    );
    await openDialog(tester);

    // Botón de borrado del diálogo (por ícono: igual en mobile y desktop).
    // Nota: TextButton.icon devuelve una subclase, así que no usamos byType.
    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();

    expect(find.text('Eliminar turno'), findsOneWidget); // título del AlertDialog

    // Confirmar: el AlertDialog agrega un segundo "Eliminar" (el último en el árbol).
    await tester.tap(find.text('Eliminar').last);
    await tester.pumpAndSettle();

    expect(find.text('🗑️ Turno eliminado'), findsOneWidget);
    final snap = await firestore.collection('appointment').doc('appt-1').get();
    expect(snap.exists, isFalse);
  });

  testWidgets('sin sesión muestra "Tu sesión expiró"', (tester) async {
    await pumpHost(
      tester,
      appointment: makeAppointment(id: 'appt-1', owner: 'uid-1'),
      overrides: overrides(signedIn: false),
    );
    await openDialog(tester);

    await tester.tap(find.widgetWithText(ElevatedButton, 'Guardar cambios'));
    await tester.pump();
    await tester.pump();

    expect(
      find.text('Tu sesión expiró. Iniciá sesión de nuevo.'),
      findsOneWidget,
    );
  });

  testWidgets('crear sin servicio muestra el error de validación',
      (tester) async {
    await pumpHost(
      tester,
      overrides: overrides(uid: 'uid-1'), // sin appointment → modo alta
    );
    await openDialog(tester);

    expect(find.text('Agendar Turno'), findsOneWidget);

    await tester.tap(find.widgetWithText(ElevatedButton, 'Guardar'));
    await tester.pump();

    expect(find.text('Elegí un servicio'), findsOneWidget);
  });
}
