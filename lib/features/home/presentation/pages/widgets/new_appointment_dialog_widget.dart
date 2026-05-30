import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mis_turnos_app/core/constants/breakpoints.dart';
import 'package:mis_turnos_app/features/home/domain/entities/appointment.dart';
import 'package:mis_turnos_app/features/home/presentation/providers/appointments_provider.dart';
import 'package:mis_turnos_app/features/home/presentation/pages/widgets/new_appointment_form_controller.dart';
import 'package:mis_turnos_app/features/home/presentation/pages/widgets/new_appointment_validators.dart';
import 'package:mis_turnos_app/features/login/presentation/providers/login_provider.dart';
import 'package:mis_turnos_app/features/services/presentation/providers/services_provider.dart';

class NewAppointmentDialogWidget extends ConsumerStatefulWidget {
  /// Si viene un [appointment], el diálogo abre en modo edición.
  const NewAppointmentDialogWidget({super.key, this.appointment});

  final Appointment? appointment;

  @override
  ConsumerState<NewAppointmentDialogWidget> createState() =>
      _NewAppointmentDialogWidgetState();
}

class _NewAppointmentDialogWidgetState
    extends ConsumerState<NewAppointmentDialogWidget> {
  final _formKey = GlobalKey<FormState>();
  late final NewAppointmentFormController _formController;
  late final TextEditingController _depositController;

  bool _hasPaid = false;
  bool _hasDeposit = false;
  int? _selectedDurationMinutes;

  bool get _isEditing => widget.appointment != null;

  @override
  void initState() {
    super.initState();
    _formController = NewAppointmentFormController();
    final appointment = widget.appointment;
    _depositController = TextEditingController(
      text: (appointment != null && appointment.deposit > 0)
          ? appointment.deposit.toStringAsFixed(0)
          : '',
    );
    if (appointment != null) {
      _formController.loadFrom(appointment);
      _hasPaid = appointment.hasPaid;
      _hasDeposit = appointment.deposit > 0;
    }
  }

  @override
  void dispose() {
    _formController.dispose();
    _depositController.dispose();
    super.dispose();
  }

  // ── date / time pickers ──────────────────────────────────────────────────

  Future<void> _pickDate(BuildContext context) async {
    final selected = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (selected != null) {
      _formController.fecha.text = DateFormat('yyyy-MM-dd').format(selected);
      setState(() {});
    }
  }

  Future<void> _pickTime(BuildContext context) async {
    final selected = await showTimePicker(
      initialEntryMode: TimePickerEntryMode.input,
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (selected != null) {
      final now = DateTime.now();
      final dt =
          DateTime(now.year, now.month, now.day, selected.hour, selected.minute);
      _formController.horaInicio.text = DateFormat('HH:mm').format(dt);
      _applyServiceDuration();
      setState(() {});
    }
  }

  Future<void> _pickTimeFin(BuildContext context) async {
    TimeOfDay initial = TimeOfDay.now();
    if (_formController.horaInicio.text.isNotEmpty) {
      try {
        final parts = _formController.horaInicio.text.split(':');
        var h = int.parse(parts[0]);
        var m = int.parse(parts[1]) + 30;
        if (m >= 60) {
          m -= 60;
          h = (h + 1) % 24;
        }
        initial = TimeOfDay(hour: h, minute: m);
      } catch (_) {}
    }
    final selected = await showTimePicker(
      context: context,
      initialTime: initial,
      initialEntryMode: TimePickerEntryMode.input,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (selected != null) {
      final now = DateTime.now();
      final dt =
          DateTime(now.year, now.month, now.day, selected.hour, selected.minute);
      _formController.horaFin.text = DateFormat('HH:mm').format(dt);
      setState(() {});
    }
  }

  void _applyServiceDuration() {
    final duration = _selectedDurationMinutes;
    if (duration == null || _formController.horaInicio.text.isEmpty) return;
    try {
      final parts = _formController.horaInicio.text.split(':');
      final start =
          DateTime(2020, 1, 1, int.parse(parts[0]), int.parse(parts[1]));
      final end = start.add(Duration(minutes: duration));
      _formController.horaFin.text = DateFormat('HH:mm').format(end);
    } catch (_) {}
  }

  // ── acciones ─────────────────────────────────────────────────────────────

  Future<void> _guardarTurno(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;

    final duration = _formController.durationMinutes();
    if (duration == null || duration <= 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('La hora de fin debe ser posterior a la hora de inicio')),
        );
      }
      return;
    }

    final ownerId = ref.read(loginProvider).currentUser?.uid;
    if (ownerId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Tu sesión expiró. Iniciá sesión de nuevo.')),
        );
      }
      return;
    }

    try {
      final existing = widget.appointment;
      final deposit = _hasDeposit
          ? (double.tryParse(_depositController.text.trim()) ?? 0)
          : 0.0;
      final appointment = _formController.buildAppointment(
        hasPaid: _hasPaid,
        deposit: deposit,
        owner: _isEditing ? existing!.owner : ownerId,
        id: existing?.id,
        status: existing?.status ?? 'pendiente',
      );

      final notifier = ref.read(appointmentsProvider.notifier);
      if (_isEditing) {
        await notifier.editAppointment(appointment);
      } else {
        await notifier.addAppointment(appointment);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing
                ? '✅ Turno actualizado correctamente'
                : '✅ Turno guardado correctamente'),
          ),
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

  Future<void> _eliminarTurno(BuildContext context) async {
    final appointment = widget.appointment;
    if (appointment == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar turno'),
        content: Text(
            '¿Seguro que querés eliminar el turno de ${appointment.clientName}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child:
                  const Text('Eliminar', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await ref
          .read(appointmentsProvider.notifier)
          .deleteAppointment(appointment.id);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('🗑️ Turno eliminado')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error al eliminar el turno: $e')),
        );
      }
    }
  }

  // ── widgets de campos ────────────────────────────────────────────────────

  Widget _buildServiceSelector() {
    final services = ref.watch(servicesProvider).valueOrNull ?? [];
    final durationByName = {for (final s in services) s.name: s.durationMinutes};

    final names = <String>{...services.map((s) => s.name)};
    final current = _formController.motivo.text;
    if (current.isNotEmpty) names.add(current);

    if (services.isEmpty && current.isEmpty) {
      return InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Servicio',
          border: OutlineInputBorder(),
        ),
        child: Text(
          'Cargá servicios en "Mis servicios"',
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
      );
    }

    return DropdownButtonFormField<String>(
      initialValue: current.isNotEmpty ? current : null,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Servicio',
        border: OutlineInputBorder(),
      ),
      items: names
          .map((name) => DropdownMenuItem(
                value: name,
                child: Text(
                  durationByName.containsKey(name)
                      ? '$name (${durationByName[name]} min)'
                      : name,
                  overflow: TextOverflow.ellipsis,
                ),
              ))
          .toList(),
      onChanged: (name) {
        if (name == null) return;
        _formController.motivo.text = name;
        _selectedDurationMinutes = durationByName[name];
        _applyServiceDuration();
        setState(() {});
      },
      validator: (v) => (v == null || v.isEmpty) ? 'Elegí un servicio' : null,
    );
  }

  // ── layout ───────────────────────────────────────────────────────────────

  /// Devuelve los campos del formulario como una lista de widgets para poder
  /// disponerlos en columna (mobile) o en grilla (desktop) sin duplicar código.
  List<Widget> _buildFields(BuildContext context) {
    return [
      // Fila 1: nombre + apellido
      _row([
        _field(_formController.nombre, 'Nombre',
            validator: NewAppointmentValidators.required),
        _field(_formController.apellido, 'Apellido',
            validator: NewAppointmentValidators.required),
      ]),
      const SizedBox(height: 14),
      // Fila 2: teléfono + observaciones
      _row([
        _field(_formController.telefono, 'Teléfono',
            keyboard: TextInputType.phone),
        _field(_formController.observaciones, 'Observaciones'),
      ]),
      const SizedBox(height: 14),
      // Fila 3: fecha + hora inicio + hora fin
      _row([
        _readonlyField(_formController.fecha, 'Fecha',
            onTap: () => _pickDate(context),
            validator: NewAppointmentValidators.fecha),
        _readonlyField(_formController.horaInicio, 'Hora inicio',
            onTap: () => _pickTime(context),
            validator: NewAppointmentValidators.horaInicio),
        _readonlyField(_formController.horaFin, 'Hora fin',
            onTap: () => _pickTimeFin(context),
            validator: (v) =>
                NewAppointmentValidators.horaFin(v, _formController)),
      ]),
      const SizedBox(height: 14),
      // Fila 4: servicio
      _buildServiceSelector(),
      const SizedBox(height: 14),
      // Fila 5: switches de pago y seña
      Wrap(
        spacing: 16,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Pagado'),
              Switch(
                value: _hasPaid,
                onChanged: (v) => setState(() => _hasPaid = v),
              ),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Seña'),
              Checkbox(
                value: _hasDeposit,
                onChanged: (v) => setState(() => _hasDeposit = v ?? false),
              ),
            ],
          ),
          if (_hasDeposit)
            SizedBox(
              width: 140,
              child: TextFormField(
                controller: _depositController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Monto seña',
                  prefixText: '\$ ',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
        ],
      ),
    ];
  }

  /// Un `Row` de campos con espacio entre ellos, cada uno en un `Expanded`.
  Widget _row(List<Widget> children) => Row(
        children: children
            .expand((w) => [Expanded(child: w), const SizedBox(width: 12)])
            .toList()
          ..removeLast(),
      );

  Widget _field(
    TextEditingController controller,
    String label, {
    String? Function(String?)? validator,
    TextInputType? keyboard,
  }) =>
      TextFormField(
        controller: controller,
        keyboardType: keyboard,
        decoration:
            InputDecoration(labelText: label, border: const OutlineInputBorder()),
        validator: validator,
      );

  Widget _readonlyField(
    TextEditingController controller,
    String label, {
    required VoidCallback onTap,
    String? Function(String?)? validator,
  }) =>
      TextFormField(
        controller: controller,
        readOnly: true,
        onTap: onTap,
        decoration:
            InputDecoration(labelText: label, border: const OutlineInputBorder()),
        validator: validator,
      );

  // ── botones de acción ────────────────────────────────────────────────────

  Widget _buildActions(BuildContext context) => Row(
        children: [
          if (_isEditing)
            TextButton.icon(
              onPressed: () => _eliminarTurno(context),
              icon: const Icon(Icons.delete, color: Colors.red),
              label:
                  const Text('Eliminar', style: TextStyle(color: Colors.red)),
            ),
          const Spacer(),
          ElevatedButton(
            onPressed: () => _guardarTurno(context),
            child: Text(_isEditing ? 'Guardar cambios' : 'Guardar'),
          ),
          const SizedBox(width: 12),
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
        ],
      );

  // ── build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isMobile = context.isMobile;
    final size = MediaQuery.of(context).size;

    // En mobile: diálogo de pantalla completa con scroll.
    // En desktop: diálogo flotante con ancho fijo.
    return Dialog(
      insetPadding: isMobile
          ? const EdgeInsets.all(12)
          : EdgeInsets.symmetric(
              horizontal: size.width * 0.2,
              vertical: size.height * 0.08,
            ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Título
              Text(
                _isEditing ? 'Editar Turno' : 'Agendar Turno',
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              // Campos scrolleables por si el teclado aparece
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: _buildFields(context),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _buildActions(context),
            ],
          ),
        ),
      ),
    );
  }
}
