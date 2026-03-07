import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mis_turnos_app/features/home/data/models/appointment_model.dart';
import 'package:mis_turnos_app/features/home/presentation/providers/appointments_provider.dart';
import 'package:uuid/uuid.dart';

class NewAppointmentDialogWidget extends ConsumerStatefulWidget {
  const NewAppointmentDialogWidget({super.key});

  @override
  ConsumerState<NewAppointmentDialogWidget> createState() =>
      _NewAppointmentDialogWidgetState();
}

class _NewAppointmentDialogWidgetState
    extends ConsumerState<NewAppointmentDialogWidget> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _apellidoController = TextEditingController();
  final _fechaController = TextEditingController();
  final _horaController = TextEditingController();
  final _motivoController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _observacionesController = TextEditingController();

  bool _hasPaid = false;
  bool _hasDeposit = false;
  String? _selectedUser;

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidoController.dispose();
    _fechaController.dispose();
    _horaController.dispose();
    _motivoController.dispose();
    _telefonoController.dispose();
    _observacionesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(BuildContext context) async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(Duration(days: 1)),
      lastDate: DateTime.now().add(Duration(days: 365)),
    );
    if (selectedDate != null) {
      _fechaController.text = DateFormat('yyyy-MM-dd').format(selectedDate);
    }
  }

  Future<void> _pickTime(BuildContext context) async {
    final selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (selectedTime != null) {
      final now = DateTime.now();
      final dt = DateTime(
          now.year, now.month, now.day, selectedTime.hour, selectedTime.minute);
      _horaController.text = DateFormat('HH:mm').format(dt);
    }
  }

  Future<void> _guardarTurno(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final uuid = Uuid();
      final id = uuid.v4();

      final date = _fechaController.text;
      final time = _horaController.text;
      final dateTime = DateTime.parse('$date $time');

      final appointment = AppointmentModel(
        id: id,
        clientName:
            '${_nombreController.text.trim()} ${_apellidoController.text.trim()}',
        dateTime: dateTime,
        duration: 30,
        deposit: _hasDeposit ? 100 : 0,
        hasPaid: _hasPaid,
        service: _motivoController.text.trim(),
        status: 'pendiente',
        comments: _observacionesController.text.trim(),
        owner: _selectedUser ?? 'sin-usuario',
      );

      await ref.read(appointmentsProvider.notifier).addAppointment(appointment);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ Turno guardado correctamente')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error al guardar el turno: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Dialog(
      child: Container(
        height: size.height * 0.8,
        width: size.width * 0.6,
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const Text('Agendar Turno',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _nombreController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          value!.isEmpty ? 'Campo requerido' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _apellidoController,
                      decoration: const InputDecoration(
                        labelText: 'Apellido',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          value!.isEmpty ? 'Campo requerido' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _telefonoController,
                      decoration: const InputDecoration(
                        labelText: 'Teléfono',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _observacionesController,
                      decoration: const InputDecoration(
                        labelText: 'Observaciones',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _fechaController,
                      readOnly: true,
                      onTap: () => _pickDate(context),
                      decoration: const InputDecoration(
                        labelText: 'Fecha',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          value!.isEmpty ? 'Seleccioná una fecha' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _horaController,
                      readOnly: true,
                      onTap: () => _pickTime(context),
                      decoration: const InputDecoration(
                        labelText: 'Hora',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          value!.isEmpty ? 'Seleccioná una hora' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _motivoController,
                      decoration: const InputDecoration(
                        labelText: 'Motivo',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          value!.isEmpty ? 'Campo requerido' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Seleccionar usuario',
                        border: OutlineInputBorder(),
                      ),
                      value: _selectedUser,
                      items: const [
                        DropdownMenuItem(
                            value: 'Usuario 1', child: Text('Usuario 1')),
                        DropdownMenuItem(
                            value: 'Usuario 2', child: Text('Usuario 2')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedUser = value;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Row(
                    children: [
                      const Text('Pagado'),
                      Switch(
                        value: _hasPaid,
                        onChanged: (value) {
                          setState(() {
                            _hasPaid = value;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Row(
                    children: [
                      const Text('Seña'),
                      Checkbox(
                        value: _hasDeposit,
                        onChanged: (value) {
                          setState(() {
                            _hasDeposit = value ?? false;
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    onPressed: () => _guardarTurno(context),
                    child: const Text('Guardar'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade400),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
