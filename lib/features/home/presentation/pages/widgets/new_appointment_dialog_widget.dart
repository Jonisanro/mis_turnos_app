import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mis_turnos_app/core/constants/breakpoints.dart';
import 'package:mis_turnos_app/core/theme/app_theme.dart';
import 'package:mis_turnos_app/features/home/domain/entities/appointment.dart';
import 'package:mis_turnos_app/features/home/presentation/providers/appointments_provider.dart';
import 'package:mis_turnos_app/features/home/presentation/pages/widgets/new_appointment_form_controller.dart';
import 'package:mis_turnos_app/features/home/presentation/pages/widgets/new_appointment_validators.dart';
import 'package:mis_turnos_app/features/login/presentation/providers/login_provider.dart';
import 'package:mis_turnos_app/features/services/presentation/providers/services_provider.dart';

class NewAppointmentDialogWidget extends ConsumerStatefulWidget {
  const NewAppointmentDialogWidget({super.key, this.appointment});
  final Appointment? appointment;

  @override
  ConsumerState<NewAppointmentDialogWidget> createState() =>
      _NewAppointmentDialogWidgetState();
}

class _NewAppointmentDialogWidgetState
    extends ConsumerState<NewAppointmentDialogWidget> {
  final _formKey = GlobalKey<FormState>();
  late final NewAppointmentFormController _ctrl;
  late final TextEditingController _depositController;

  bool _hasPaid = false;
  bool _hasDeposit = false;
  bool _hasCustomEndTime = false;
  int? _selectedDurationMinutes;

  bool get _isEditing => widget.appointment != null;

  @override
  void initState() {
    super.initState();
    _ctrl = NewAppointmentFormController();
    final a = widget.appointment;
    _depositController = TextEditingController(
      text: (a != null && a.deposit > 0) ? a.deposit.toStringAsFixed(0) : '',
    );

    if (a != null) {
      // Modo edición: precargar todos los campos y mostrar la hora fin.
      _ctrl.loadFrom(a);
      _hasPaid = a.hasPaid;
      _hasDeposit = a.deposit > 0;
      _hasCustomEndTime = true; // en edición siempre mostramos la hora fin
    } else {
      // Modo alta: fecha = hoy por defecto para minimizar campos a completar.
      _ctrl.fecha.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _depositController.dispose();
    super.dispose();
  }

  // ── Pickers ──────────────────────────────────────────────────────────────

  Future<void> _pickDate(BuildContext context) async {
    final selected = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(_ctrl.fecha.text) ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (selected != null) {
      _ctrl.fecha.text = DateFormat('yyyy-MM-dd').format(selected);
      _applyServiceDuration();
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
      _ctrl.horaInicio.text = DateFormat('HH:mm').format(dt);
      _applyServiceDuration();
      setState(() {});
    }
  }

  Future<void> _pickTimeFin(BuildContext context) async {
    TimeOfDay initial = TimeOfDay.now();
    if (_ctrl.horaInicio.text.isNotEmpty) {
      try {
        final parts = _ctrl.horaInicio.text.split(':');
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
      _ctrl.horaFin.text = DateFormat('HH:mm').format(dt);
      setState(() {});
    }
  }

  /// Calcula y escribe la hora de fin en el controller a partir de la duración
  /// del servicio seleccionado. No hace nada si el override manual está activo.
  void _applyServiceDuration() {
    if (_hasCustomEndTime) return; // respetar el override manual
    final duration = _selectedDurationMinutes;
    if (duration == null || _ctrl.horaInicio.text.isEmpty) return;
    try {
      final parts = _ctrl.horaInicio.text.split(':');
      final start =
          DateTime(2020, 1, 1, int.parse(parts[0]), int.parse(parts[1]));
      _ctrl.horaFin.text =
          DateFormat('HH:mm').format(start.add(Duration(minutes: duration)));
    } catch (_) {}
  }

  // ── Acciones ─────────────────────────────────────────────────────────────

  Future<void> _guardarTurno(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;

    final duration = _ctrl.durationMinutes();
    if (duration == null || duration <= 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('La hora de fin debe ser posterior a la de inicio')),
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
      final appointment = _ctrl.buildAppointment(
        hasPaid: _hasPaid,
        deposit: deposit,
        owner: _isEditing ? existing!.owner : ownerId,
        id: existing?.id,
        status: existing?.status ?? 'pendiente',
      );

      final notifier = ref.read(appointmentsProvider.notifier);
      _isEditing
          ? await notifier.editAppointment(appointment)
          : await notifier.addAppointment(appointment);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(_isEditing ? '✅ Turno actualizado' : '✅ Turno guardado'),
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
    final a = widget.appointment;
    if (a == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar turno'),
        content: Text('¿Eliminar el turno de ${a.clientName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await ref
          .read(appointmentsProvider.notifier)
          .deleteAppointment(a.id);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('🗑️ Turno eliminado')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error al eliminar: $e')),
        );
      }
    }
  }

  // ── Selector de servicio ─────────────────────────────────────────────────

  Widget _buildServiceSelector() {
    final services = ref.watch(servicesProvider).valueOrNull ?? [];
    final durationByName = {
      for (final s in services) s.name: s.durationMinutes
    };
    final names = <String>{...services.map((s) => s.name)};
    final current = _ctrl.motivo.text;
    if (current.isNotEmpty) names.add(current);

    if (services.isEmpty && current.isEmpty) {
      return InputDecorator(
        decoration: InputDecoration(
          label: _requiredLabel('Servicio'),
        ),
        child: Text(
          'Primero cargá servicios en "Mis servicios"',
          style: TextStyle(color: Colors.grey[600], fontSize: 13),
        ),
      );
    }

    return DropdownButtonFormField<String>(
      initialValue: current.isNotEmpty ? current : null,
      isExpanded: true,
      decoration: InputDecoration(label: _requiredLabel('Servicio')),
      items: names.map((name) {
        final dur = durationByName[name];
        return DropdownMenuItem(
          value: name,
          child: Text(
            dur != null ? '$name ($dur min)' : name,
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: (name) {
        if (name == null) return;
        _ctrl.motivo.text = name;
        _selectedDurationMinutes = durationByName[name];
        _applyServiceDuration();
        setState(() {});
      },
      validator: (v) =>
          (v == null || v.isEmpty) ? 'Elegí un servicio' : null,
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  Widget _requiredLabel(String text) => Text.rich(
        TextSpan(
          text: text,
          children: const [
            TextSpan(
              text: ' *',
              style: TextStyle(color: AppColors.error, fontSize: 12),
            ),
          ],
        ),
      );

  Widget _row(List<Widget> children) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children
            .expand((w) => [Expanded(child: w), const SizedBox(width: 12)])
            .toList()
          ..removeLast(),
      );

  // ── Campos del formulario ─────────────────────────────────────────────────

  List<Widget> _buildFields(BuildContext context) {
    final isMobile = context.isMobile;

    return [
      // ── Quién ────────────────────────────────────────────────────────────
      _row([
        TextFormField(
          controller: _ctrl.clientName,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          decoration:
              InputDecoration(label: _requiredLabel('Nombre y apellido')),
          validator: NewAppointmentValidators.required,
        ),
        TextFormField(
          controller: _ctrl.telefono,
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.next,
          decoration:
              const InputDecoration(labelText: 'Teléfono (opcional)'),
          validator: NewAppointmentValidators.phone,
        ),
      ]),
      const SizedBox(height: 14),

      // ── Qué servicio ────────────────────────────────────────────────────
      _buildServiceSelector(),
      const SizedBox(height: 14),

      // ── Cuándo ──────────────────────────────────────────────────────────
      _row([
        TextFormField(
          controller: _ctrl.fecha,
          readOnly: true,
          onTap: () => _pickDate(context),
          decoration: InputDecoration(
            label: _requiredLabel('Fecha'),
            suffixIcon:
                const Icon(Icons.calendar_today_outlined, size: 18),
          ),
          validator: NewAppointmentValidators.fecha,
        ),
        TextFormField(
          controller: _ctrl.horaInicio,
          readOnly: true,
          onTap: () => _pickTime(context),
          decoration: InputDecoration(
            label: _requiredLabel('Hora inicio'),
            suffixIcon: const Icon(Icons.schedule_outlined, size: 18),
          ),
          validator: NewAppointmentValidators.horaInicio,
        ),
      ]),
      const SizedBox(height: 8),

      // ── Checkbox hora de fin personalizada ───────────────────────────────
      InkWell(
        onTap: () {
          setState(() {
            _hasCustomEndTime = !_hasCustomEndTime;
            if (!_hasCustomEndTime) {
              // Al desactivar el override, recalcular desde el servicio.
              _applyServiceDuration();
            }
          });
        },
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: Checkbox(
                  value: _hasCustomEndTime,
                  onChanged: (v) {
                    setState(() {
                      _hasCustomEndTime = v ?? false;
                      if (!_hasCustomEndTime) _applyServiceDuration();
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Personalizar hora de fin',
                style: TextStyle(fontSize: 14, color: AppColors.secondary),
              ),
            ],
          ),
        ),
      ),

      // ── Campo hora fin (solo si override activo) ─────────────────────────
      if (_hasCustomEndTime) ...[
        const SizedBox(height: 8),
        SizedBox(
          width: isMobile ? double.infinity : 180,
          child: TextFormField(
            controller: _ctrl.horaFin,
            readOnly: true,
            onTap: () => _pickTimeFin(context),
            decoration: InputDecoration(
              label: _requiredLabel('Hora de fin'),
              suffixIcon: const Icon(Icons.schedule_outlined, size: 18),
            ),
            validator: (v) =>
                _hasCustomEndTime
                    ? NewAppointmentValidators.horaFin(v, _ctrl)
                    : null,
          ),
        ),
      ],
      const SizedBox(height: 14),

      // ── Notas ────────────────────────────────────────────────────────────
      TextFormField(
        controller: _ctrl.observaciones,
        textInputAction: TextInputAction.done,
        maxLines: 3,
        decoration: const InputDecoration(labelText: 'Notas (opcional)'),
      ),
      const SizedBox(height: 14),

      // ── Pago ────────────────────────────────────────────────────────────
      Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Wrap(
          spacing: 16,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Pagado', style: TextStyle(fontSize: 14)),
                Switch(
                  value: _hasPaid,
                  onChanged: (v) => setState(() => _hasPaid = v),
                ),
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Seña', style: TextStyle(fontSize: 14)),
                Checkbox(
                  value: _hasDeposit,
                  onChanged: (v) =>
                      setState(() => _hasDeposit = v ?? false),
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
                    labelText: 'Monto *',
                    prefixText: '\$ ',
                  ),
                  validator: (v) => NewAppointmentValidators.depositAmount(
                    v,
                    hasDeposit: _hasDeposit,
                  ),
                ),
              ),
          ],
        ),
      ),

      // ── Leyenda ──────────────────────────────────────────────────────────
      const SizedBox(height: 8),
      const Text(
        '* Campos obligatorios',
        style: TextStyle(fontSize: 11, color: AppColors.secondary),
      ),
    ];
  }

  // ── Botones ──────────────────────────────────────────────────────────────

  Widget _buildActions(BuildContext context) {
    final isMobile = context.isMobile;

    // Mobile: botones apilados (evita overflow).
    // Orden: acción primaria arriba, cancelar abajo, eliminar al final.
    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton(
            onPressed: () => _guardarTurno(context),
            child: Text(_isEditing ? 'Guardar cambios' : 'Guardar'),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          if (_isEditing) ...[
            const SizedBox(height: 4),
            TextButton.icon(
              onPressed: () => _eliminarTurno(context),
              icon: const Icon(Icons.delete_outline,
                  color: AppColors.error, size: 18),
              label: const Text('Eliminar turno',
                  style: TextStyle(color: AppColors.error)),
            ),
          ],
        ],
      );
    }

    // Desktop: fila con spacer.
    return Row(
      children: [
        if (_isEditing)
          TextButton.icon(
            onPressed: () => _eliminarTurno(context),
            icon: const Icon(Icons.delete_outline, color: AppColors.error),
            label: const Text('Eliminar',
                style: TextStyle(color: AppColors.error)),
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
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isMobile = context.isMobile;
    final size = MediaQuery.sizeOf(context);

    return Dialog(
      insetPadding: isMobile
          ? const EdgeInsets.all(12)
          : EdgeInsets.symmetric(
              horizontal: size.width * 0.2,
              vertical: size.height * 0.06,
            ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _isEditing ? 'Editar Turno' : 'Agendar Turno',
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Divider(),
              const SizedBox(height: 12),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: _buildFields(context),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildActions(context),
            ],
          ),
        ),
      ),
    );
  }
}
