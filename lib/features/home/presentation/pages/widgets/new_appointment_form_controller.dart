import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mis_turnos_app/features/home/data/models/appointment_model.dart';
import 'package:mis_turnos_app/features/home/domain/entities/appointment.dart';
import 'package:uuid/uuid.dart';

/// Controlador del formulario de nuevo turno.
/// Centraliza los [TextEditingController] y la lógica de duración y construcción del modelo.
class NewAppointmentFormController {
  NewAppointmentFormController()
      : nombre = TextEditingController(),
        apellido = TextEditingController(),
        fecha = TextEditingController(),
        horaInicio = TextEditingController(),
        horaFin = TextEditingController(),
        motivo = TextEditingController(),
        telefono = TextEditingController(),
        observaciones = TextEditingController();

  final TextEditingController nombre;
  final TextEditingController apellido;
  final TextEditingController fecha;
  final TextEditingController horaInicio;
  final TextEditingController horaFin;
  final TextEditingController motivo;
  final TextEditingController telefono;
  final TextEditingController observaciones;

  void dispose() {
    nombre.dispose();
    apellido.dispose();
    fecha.dispose();
    horaInicio.dispose();
    horaFin.dispose();
    motivo.dispose();
    telefono.dispose();
    observaciones.dispose();
  }

  /// Calcula la duración en minutos entre hora inicio y hora fin (mismo día).
  /// Devuelve [null] si faltan datos o la hora fin es anterior a la de inicio.
  int? durationMinutes() {
    if (horaInicio.text.isEmpty || horaFin.text.isEmpty) return null;
    try {
      final dateStr = fecha.text.isNotEmpty ? fecha.text : '2020-01-01';
      final start = DateTime.parse('$dateStr ${horaInicio.text}');
      final end = DateTime.parse('$dateStr ${horaFin.text}');
      final diff = end.difference(start);
      if (diff.inMinutes < 0) return null;
      return diff.inMinutes;
    } catch (_) {
      return null;
    }
  }

  /// Precarga los campos del formulario a partir de un turno existente
  /// (modo edición).
  void loadFrom(Appointment appointment) {
    final parts = appointment.clientName.trim().split(' ');
    nombre.text = parts.isNotEmpty ? parts.first : '';
    apellido.text = parts.length > 1 ? parts.sublist(1).join(' ') : '';
    telefono.text = appointment.phone;
    fecha.text = DateFormat('yyyy-MM-dd').format(appointment.dateTime);
    horaInicio.text = DateFormat('HH:mm').format(appointment.dateTime);
    final end =
        appointment.dateTime.add(Duration(minutes: appointment.duration));
    horaFin.text = DateFormat('HH:mm').format(end);
    motivo.text = appointment.service;
    observaciones.text = appointment.comments;
  }

  String get clientName =>
      '${nombre.text.trim()} ${apellido.text.trim()}';

  /// Fecha/hora de inicio del turno. [null] si los datos no son válidos.
  DateTime? get dateTime {
    if (fecha.text.isEmpty || horaInicio.text.isEmpty) return null;
    try {
      return DateTime.parse('${fecha.text} ${horaInicio.text}');
    } catch (_) {
      return null;
    }
  }

  /// Construye [AppointmentModel] con los datos actuales del formulario.
  /// [hasPaid] y [deposit] (monto de la seña) se pasan desde el widget; [owner]
  /// es el uid del usuario autenticado. En modo edición se pasan [id] y
  /// [status] del turno existente; en alta se genera un id nuevo.
  AppointmentModel buildAppointment({
    required bool hasPaid,
    required double deposit,
    required String owner,
    String? id,
    String status = 'pendiente',
  }) {
    final appointmentId = id ?? const Uuid().v4();
    final dt = dateTime!;
    final duration = durationMinutes()!;

    return AppointmentModel(
      id: appointmentId,
      clientName: clientName,
      phone: telefono.text.trim(),
      dateTime: dt,
      duration: duration,
      deposit: deposit,
      hasPaid: hasPaid,
      service: motivo.text.trim(),
      status: status,
      comments: observaciones.text.trim(),
      owner: owner,
    );
  }
}
