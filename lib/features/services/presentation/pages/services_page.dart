import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mis_turnos_app/core/theme/app_theme.dart';
import 'package:mis_turnos_app/features/login/presentation/providers/login_provider.dart';
import 'package:mis_turnos_app/features/services/data/models/service_model.dart';
import 'package:mis_turnos_app/features/services/domain/entities/service.dart';
import 'package:mis_turnos_app/features/services/presentation/providers/services_provider.dart';
import 'package:uuid/uuid.dart';

class ServicesPage extends ConsumerWidget {
  const ServicesPage({super.key});

  Future<void> _openServiceDialog(BuildContext context,
      {Service? service}) async {
    await showDialog(
      context: context,
      builder: (_) => ServiceFormDialog(service: service),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, Service s) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar servicio'),
        content: Text('¿Eliminar "${s.name}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Eliminar',
                  style: TextStyle(color: AppColors.error))),
        ],
      ),
    );
    if (confirm == true) {
      await ref.read(servicesProvider.notifier).deleteService(s.id);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final servicesState = ref.watch(servicesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Mis servicios')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openServiceDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo servicio'),
      ),
      body: servicesState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (services) {
          if (services.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.accentLight,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.design_services_outlined,
                        size: 36, color: AppColors.accent),
                  ),
                  const SizedBox(height: 16),
                  const Text('Todavía no cargaste servicios',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary)),
                  const SizedBox(height: 6),
                  const Text('Tocá "Nuevo servicio" para empezar',
                      style:
                          TextStyle(fontSize: 14, color: AppColors.secondary)),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: services.length,
            separatorBuilder: (_, __) =>
                const Divider(height: 1, indent: 72),
            itemBuilder: (context, index) {
              final s = services[index];
              final initials = s.name.isNotEmpty
                  ? s.name
                      .trim()
                      .split(' ')
                      .take(2)
                      .map((w) => w[0].toUpperCase())
                      .join()
                  : '?';

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.accentLight,
                  child: Text(
                    initials,
                    style: const TextStyle(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
                title: Text(s.name,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(
                  '${s.durationMinutes} min · \$${s.price.toStringAsFixed(0)}',
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.secondary),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined,
                          size: 20, color: AppColors.secondary),
                      onPressed: () =>
                          _openServiceDialog(context, service: s),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline,
                          size: 20, color: AppColors.error),
                      onPressed: () => _confirmDelete(context, ref, s),
                    ),
                  ],
                ),
                onTap: () => _openServiceDialog(context, service: s),
              );
            },
          );
        },
      ),
    );
  }
}

// ── Diálogo de creación/edición de servicio ──────────────────────────────────

class ServiceFormDialog extends ConsumerStatefulWidget {
  const ServiceFormDialog({super.key, this.service});
  final Service? service;

  @override
  ConsumerState<ServiceFormDialog> createState() => _ServiceFormDialogState();
}

class _ServiceFormDialogState extends ConsumerState<ServiceFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _priceController;
  late final TextEditingController _durationController;

  bool get _isEditing => widget.service != null;

  @override
  void initState() {
    super.initState();
    final s = widget.service;
    _nameController = TextEditingController(text: s?.name ?? '');
    _priceController = TextEditingController(
        text: s != null ? s.price.toStringAsFixed(0) : '');
    _durationController = TextEditingController(
        text: s != null ? s.durationMinutes.toString() : '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final ownerId = ref.read(loginProvider).currentUser?.uid;
    if (ownerId == null) return;

    final service = ServiceModel(
      id: widget.service?.id ?? const Uuid().v4(),
      name: _nameController.text.trim(),
      price: double.tryParse(_priceController.text.trim()) ?? 0,
      durationMinutes: int.tryParse(_durationController.text.trim()) ?? 0,
      owner: ownerId,
    );

    try {
      await ref.read(servicesProvider.notifier).saveService(service);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error al guardar: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEditing ? 'Editar servicio' : 'Nuevo servicio'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Nombre del servicio',
                hintText: 'Ej: Uñas esculpidas',
                prefixIcon:
                    Icon(Icons.label_outline, color: AppColors.secondary),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Campo requerido' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _durationController,
              decoration: const InputDecoration(
                labelText: 'Duración',
                hintText: '60',
                suffixText: 'min',
                prefixIcon:
                    Icon(Icons.schedule_outlined, color: AppColors.secondary),
              ),
              keyboardType: TextInputType.number,
              validator: (v) {
                final n = int.tryParse(v?.trim() ?? '');
                if (n == null || n <= 0) return 'Ingresá minutos válidos';
                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _priceController,
              decoration: const InputDecoration(
                labelText: 'Precio',
                prefixText: '\$ ',
                prefixIcon:
                    Icon(Icons.payments_outlined, color: AppColors.secondary),
              ),
              keyboardType: TextInputType.number,
              validator: (v) {
                final n = double.tryParse(v?.trim() ?? '');
                if (n == null || n < 0) return 'Ingresá un precio válido';
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _save,
          child: Text(_isEditing ? 'Guardar' : 'Crear'),
        ),
      ],
    );
  }
}
