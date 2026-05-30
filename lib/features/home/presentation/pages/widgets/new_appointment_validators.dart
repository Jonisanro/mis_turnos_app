import 'package:mis_turnos_app/features/home/presentation/pages/widgets/new_appointment_form_controller.dart';

/// Validaciones reutilizables del formulario de nuevo turno.
class NewAppointmentValidators {
  NewAppointmentValidators._();

  static const _campoRequerido = 'Campo requerido';
  static const _seleccionaFecha = 'Seleccioná una fecha';
  static const _seleccionaHora = 'Seleccioná una hora';
  static const _seleccionaHoraFin = 'Seleccioná hora de fin';
  static const _horaFinDespuesInicio = 'La hora fin debe ser después del inicio';

  /// Campo obligatorio.
  static String? required(String? value) {
    if (value == null || value.trim().isEmpty) return _campoRequerido;
    return null;
  }

  /// Teléfono: opcional, pero si se ingresó algo debe tener al menos 6 dígitos.
  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 6) return 'Ingresá al menos 6 dígitos';
    return null;
  }

  /// Fecha obligatoria.
  static String? fecha(String? value) {
    if (value == null || value.isEmpty) return _seleccionaFecha;
    return null;
  }

  /// Hora inicio obligatoria.
  static String? horaInicio(String? value) {
    if (value == null || value.isEmpty) return _seleccionaHora;
    return null;
  }

  /// Hora fin obligatoria y debe ser posterior a la hora de inicio.
  static String? horaFin(String? value, NewAppointmentFormController form) {
    if (value == null || value.isEmpty) return _seleccionaHoraFin;
    final duration = form.durationMinutes();
    if (duration == null || duration <= 0) return _horaFinDespuesInicio;
    return null;
  }

  /// Servicio obligatorio.
  static String? motivo(String? value) => required(value);

  /// Monto de seña: requerido y > 0 cuando la seña está activada.
  static String? depositAmount(String? value, {required bool hasDeposit}) {
    if (!hasDeposit) return null;
    if (value == null || value.trim().isEmpty) return 'Ingresá el monto de la seña';
    final amount = double.tryParse(value.trim());
    if (amount == null || amount <= 0) return 'El monto debe ser mayor a 0';
    return null;
  }
}
