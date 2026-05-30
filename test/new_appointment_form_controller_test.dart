import 'package:flutter_test/flutter_test.dart';
import 'package:mis_turnos_app/features/home/domain/entities/appointment.dart';
import 'package:mis_turnos_app/features/home/presentation/pages/widgets/new_appointment_form_controller.dart';

void main() {
  group('NewAppointmentFormController.durationMinutes', () {
    late NewAppointmentFormController controller;

    setUp(() => controller = NewAppointmentFormController());
    tearDown(() => controller.dispose());

    test('devuelve null si faltan horas', () {
      expect(controller.durationMinutes(), isNull);
    });

    test('calcula la duración entre inicio y fin', () {
      controller.fecha.text = '2026-05-29';
      controller.horaInicio.text = '10:00';
      controller.horaFin.text = '11:30';
      expect(controller.durationMinutes(), 90);
    });

    test('devuelve null si la hora fin es anterior a la de inicio', () {
      controller.fecha.text = '2026-05-29';
      controller.horaInicio.text = '12:00';
      controller.horaFin.text = '11:00';
      expect(controller.durationMinutes(), isNull);
    });
  });

  group('NewAppointmentFormController.loadFrom', () {
    test('hidrata los campos desde un turno existente', () {
      final controller = NewAppointmentFormController();
      addTearDown(controller.dispose);

      final appointment = Appointment(
        id: 'abc',
        clientName: 'Ana García López',
        dateTime: DateTime(2026, 5, 29, 14, 0),
        duration: 60,
        hasPaid: true,
        service: 'Uñas esculpidas',
        status: 'pendiente',
        comments: 'Color rojo',
        owner: 'uid-1',
        deposit: 500,
      );

      controller.loadFrom(appointment);

      expect(controller.nombre.text, 'Ana');
      expect(controller.apellido.text, 'García López');
      expect(controller.fecha.text, '2026-05-29');
      expect(controller.horaInicio.text, '14:00');
      expect(controller.horaFin.text, '15:00');
      expect(controller.motivo.text, 'Uñas esculpidas');
      expect(controller.observaciones.text, 'Color rojo');
    });
  });
}
