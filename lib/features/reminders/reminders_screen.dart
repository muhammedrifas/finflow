import 'package:add_2_calendar/add_2_calendar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../core/utils/currency_formatter.dart';
import '../../data/models/reminder_model.dart';
import '../../providers/finance_providers.dart';
import '../transactions/quick_add_sheet.dart';

class RemindersScreen extends ConsumerWidget {
  const RemindersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reminders = ref.watch(upcomingWindowRemindersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Upcoming Payments (±30d)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_alarm_rounded),
            tooltip: 'New Reminder',
            onPressed: () => _showReminderDialog(context, ref),
          ),
        ],
      ),
      body: reminders.isEmpty
          ? const Center(child: Text('No payments due within ±30 days.'))
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
              itemCount: reminders.length,
              itemBuilder: (context, index) {
                final r = reminders[index];
                final isOverdue = !r.isCompleted && r.dueDate.isBefore(DateTime.now());
                final completedStyle = r.isCompleted
                    ? TextStyle(
                        decoration: TextDecoration.lineThrough,
                        color: Theme.of(context).disabledColor,
                      )
                    : null;

                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    onLongPress: () => _showReminderDialog(context, ref, existing: r),
                    leading: Checkbox(
                      value: r.isCompleted,
                      onChanged: (val) => _handleToggle(context, ref, r, val ?? false),
                    ),
                    title: Text(
                      r.title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        decoration: r.isCompleted
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                        color: r.isCompleted ? Theme.of(context).disabledColor : null,
                      ),
                    ),
                    subtitle: Text(
                      'Due ${DateFormat('dd MMM').format(r.dueDate)}',
                      style: completedStyle ?? TextStyle(color: isOverdue ? Colors.red : null),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          CurrencyFormatter.format(r.amount),
                          style: (completedStyle ?? const TextStyle()).copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.event_available_outlined, size: 20),
                          tooltip: 'Add to Calendar',
                          onPressed: () => _exportToCalendar(r),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 20),
                          tooltip: 'Delete Reminder',
                          onPressed: () => _confirmDeleteReminder(context, ref, r),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  void _exportToCalendar(ReminderModel r) {
    final event = Event(
      title: 'Payment Due: ${r.title} (${CurrencyFormatter.format(r.amount)})',
      description: 'Pay via ${r.paymentTypeName} • Category: ${r.categoryName}',
      startDate: DateTime(r.dueDate.year, r.dueDate.month, r.dueDate.day, 9, 0),
      endDate: DateTime(r.dueDate.year, r.dueDate.month, r.dueDate.day, 9, 30),
      recurrence: r.repeatMonthly
          ? Recurrence(frequency: Frequency.monthly)
          : null,
    );
    Add2Calendar.addEvent2Cal(event);
  }

  Future<void> _handleToggle(
    BuildContext context,
    WidgetRef ref,
    ReminderModel r,
    bool isCompleted,
  ) async {
    await ref
        .read(financeRepositoryProvider)
        .toggleReminderCompleted(r, isCompleted);
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    if (isCompleted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
          content: Row(
            children: [
              const Expanded(child: Text('Marked paid & silenced.')),
              TextButton(
                onPressed: () =>
                    ScaffoldMessenger.of(context).hideCurrentSnackBar(),
                child: const Text('Skip'),
              ),
              TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    useSafeArea: true,
                    builder: (_) => QuickAddTransactionSheet(
                      initialAmount: r.amount,
                      initialNote: r.title,
                      initialPaymentTypeId: r.paymentTypeId,
                      initialCategoryId: r.categoryId,
                    ),
                  );
                },
                child: const Text('Log'),
              ),
            ],
          ),
        ),
      );
    }
  }

  Future<void> _confirmDeleteReminder(
    BuildContext context,
    WidgetRef ref,
    ReminderModel r,
  ) async {
    bool deleteFuture = false;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Delete Reminder?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Remove "${r.title}" (${CurrencyFormatter.format(r.amount)})?'),
              if (r.repeatMonthly) ...[
                const SizedBox(height: 12),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: const Text('Delete all future repeating reminders'),
                  subtitle: const Text(
                    'Leave unchecked to skip only this month.',
                    style: TextStyle(fontSize: 12),
                  ),
                  value: deleteFuture,
                  onChanged: (v) => setState(() => deleteFuture = v ?? false),
                ),
              ],
            ],
          ),
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
      ),
    );

    if (confirmed == true) {
      await ref
          .read(financeRepositoryProvider)
          .deleteReminder(r, deleteFuture: deleteFuture);
    }
  }

  Future<void> _showReminderDialog(
    BuildContext context,
    WidgetRef ref, {
    ReminderModel? existing,
  }) async {
    final isEdit = existing != null;
    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    final amountCtrl = TextEditingController(
      text: existing != null ? existing.amount.toStringAsFixed(0) : '',
    );

    DateTime dueDate =
        existing?.dueDate ?? DateTime.now().add(const Duration(days: 3));
    DateTime remindAt = existing?.remindAt ??
        DateTime(dueDate.year, dueDate.month, dueDate.day - 1, 9, 0);
    bool repeatMonthly = existing?.repeatMonthly ?? false;

    final pts = ref.read(paymentTypesProvider).valueOrNull ?? [];
    final cats = ref.read(categoriesProvider).valueOrNull ?? [];
    String? ptId = existing?.paymentTypeId ?? (pts.isNotEmpty ? pts.first.id : null);
    String? catId = existing?.categoryId ?? (cats.isNotEmpty ? cats.first.id : null);

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text(isEdit ? 'Edit Payment Reminder' : 'New Payment Reminder'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(
                    hintText: 'Title (e.g., Rent, Credit Card)',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: amountCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(prefixText: '₹ ', hintText: 'Amount'),
                ),
                const SizedBox(height: 10),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Payment Due Date'),
                  subtitle: Text(DateFormat('dd MMM yyyy').format(dueDate)),
                  trailing: const Icon(Icons.calendar_month),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: dueDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      setState(() {
                        dueDate = picked;
                        // Default alert to 1 day before at 9:00 AM
                        final dayBefore = picked.subtract(const Duration(days: 1));
                        remindAt = DateTime(
                          dayBefore.year,
                          dayBefore.month,
                          dayBefore.day,
                          9,
                          0,
                        );
                      });
                    }
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Reminder Date & Time'),
                  subtitle: Text(DateFormat('dd MMM yyyy, hh:mm a').format(remindAt)),
                  trailing: const Icon(Icons.notifications_active_outlined),
                  onTap: () async {
                    final pickedDate = await showDatePicker(
                      context: ctx,
                      initialDate: remindAt,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );
                    if (pickedDate == null || !ctx.mounted) return;
                    final pickedTime = await showTimePicker(
                      context: ctx,
                      initialTime: TimeOfDay.fromDateTime(remindAt),
                    );
                    if (pickedTime != null) {
                      setState(() {
                        remindAt = DateTime(
                          pickedDate.year,
                          pickedDate.month,
                          pickedDate.day,
                          pickedTime.hour,
                          pickedTime.minute,
                        );
                      });
                    }
                  },
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Repeat Monthly'),
                  value: repeatMonthly,
                  onChanged: (v) => setState(() => repeatMonthly = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final amount = double.tryParse(amountCtrl.text.trim()) ?? 0;
                if (titleCtrl.text.trim().isEmpty || amount <= 0) return;

                final pt = pts.firstWhere((e) => e.id == ptId, orElse: () => pts.first);
                final cat = cats.firstWhere((e) => e.id == catId, orElse: () => cats.first);

                final reminder = ReminderModel(
                  id: existing?.id ?? const Uuid().v4(),
                  notificationId: existing?.notificationId ??
                      DateTime.now().millisecondsSinceEpoch % 100000,
                  title: titleCtrl.text.trim(),
                  amount: amount,
                  paymentTypeId: pt.id,
                  paymentTypeName: pt.name,
                  categoryId: cat.id,
                  categoryName: cat.name,
                  dueDate: dueDate,
                  remindAt: remindAt,
                  repeatMonthly: repeatMonthly,
                  isCompleted: existing?.isCompleted ?? false,
                );
                await ref.read(financeRepositoryProvider).saveReminder(reminder);
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: Text(isEdit ? 'Update' : 'Save'),
            ),
          ],
        ),
      ),
    );
  }
}