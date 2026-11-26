import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/finance_providers.dart';

class ManageMetadataScreen extends ConsumerWidget {
  const ManageMetadataScreen({super.key});

Future<void> _confirmDelete(
    BuildContext context,
    String label,
    VoidCallback onConfirm,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to delete "$label"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) onConfirm();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pts = ref.watch(paymentTypesProvider).valueOrNull ?? [];
    final cats = ref.watch(categoriesProvider).valueOrNull ?? [];

    
    return Scaffold(
      appBar: AppBar(title: const Text('Types & Categories')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
        children: [
          _SectionHeader(
            title: 'Payment Types',
            onAdd: () => _promptAdd(context, 'New Payment Type', (name) {
              ref.read(financeRepositoryProvider).addPaymentType(name);
            }),
          ),
          ...pts.map(
            (pt) => Card(
              child: ListTile(
                title: Text(pt.name),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _confirmDelete(
                      context,
                      pt.name,
                      () => ref.read(financeRepositoryProvider).deletePaymentType(pt.id),
                  )
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          _SectionHeader(
            title: 'Categories',
            onAdd: () => _promptAdd(context, 'New Category', (name) {
              ref.read(financeRepositoryProvider).addCategory(name);
            }),
          ),
          ...cats.map(
            (c) => Card(
              child: ListTile(
                title: Text(c.name),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _confirmDelete(
                      context,
                      c.name,
                      () => ref.read(financeRepositoryProvider).deleteCategory(c.id),
                    ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _promptAdd(
    BuildContext context,
    String title,
    ValueChanged<String> onSave,
  ) async {
    final ctrl = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(controller: ctrl, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (ctrl.text.trim().isNotEmpty) onSave(ctrl.text.trim());
              Navigator.pop(ctx);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback onAdd;
  const _SectionHeader({required this.title, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        TextButton.icon(onPressed: onAdd, icon: const Icon(Icons.add), label: const Text('Add')),
      ],
    );
  }
}