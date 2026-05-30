import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mis_turnos_app/features/login/presentation/providers/login_provider.dart';
import 'package:mis_turnos_app/features/services/data/models/service_model.dart';
import 'package:mis_turnos_app/features/services/domain/entities/service.dart';
import 'package:mis_turnos_app/features/services/presentation/providers/services_provider.dart';
import 'package:uuid/uuid.dart';

class ServicesPage extends ConsumerWidget {
  const ServicesPage({super.key});

  Future<void> _openServiceDialog(
    BuildContext context, {
    Service? service,
  }) async {
    await showDialog(
      context: context,
      builder: (_) => ServiceFormDialog(service: service),
    );
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
            return const Center(
              child: Text(
                  'Todavía no cargaste servicios.\nTocá "Nuevo servicio" para empezar.',
                  textAlign: TextAlign.center),
            );
          }
          return ListView.separated(
            itemCount: services.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final s = services[index];
              return ListTile(
                title: Text(s.name),
                subtitle: Text(
                    '${s.durationMinutes} min · \$${s.price.toStringAsFixed(0)}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () =>
                          _openServiceDialog(context, service: s),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () async {
                        await ref
                            .read(servicesProvider.notifier)
                            .deleteService(s.id);
                      },
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
    _priceController =
        TextEditingController(text: s != null ? s.price.toStringAsFixed(0) : '');
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
              decoration: const InputDecoration(
                labelText: 'Nombre del servicio',
                hintText: 'Ej: Uñas esculpidas',
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Campo requerido' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _durationController,
              decoration: const InputDecoration(
                labelText: 'Duración (minutos)',
              ),
              keyboardType: TextInputType.number,
              validator: (v) {
                final n = int.tryParse(v?.trim() ?? '');
                if (n == null || n <= 0) return 'Ingresá minutos válidos';
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _priceController,
              decoration: const InputDecoration(
                labelText: 'Precio',
                prefixText: '\$ ',
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
        TextButton(
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
