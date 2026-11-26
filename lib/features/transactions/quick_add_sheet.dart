import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/transaction_model.dart';
import '../../providers/finance_providers.dart';

class QuickAddTransactionSheet extends ConsumerStatefulWidget {
  final TransactionModel? existingTransaction;
  final double? initialAmount;
  final String? initialNote;
  final String? initialPaymentTypeId;
  final String? initialCategoryId;

  const QuickAddTransactionSheet({
    super.key,
    this.existingTransaction,
    this.initialAmount,
    this.initialNote,
    this.initialPaymentTypeId,
    this.initialCategoryId,
  });

  @override
  ConsumerState<QuickAddTransactionSheet> createState() =>
      _QuickAddTransactionSheetState();
}

class _QuickAddTransactionSheetState
    extends ConsumerState<QuickAddTransactionSheet> {
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  TransactionKind _kind = TransactionKind.debit;
  String? _selectedPaymentTypeId;
  String? _selectedCategoryId;
  DateTime _date = DateTime.now();

  @override
  void initState() {
    super.initState();
    final existing = widget.existingTransaction;
    if (existing != null) {
      _amountCtrl.text = existing.amount.toStringAsFixed(
        existing.amount.truncateToDouble() == existing.amount ? 0 : 2,
      );
      _noteCtrl.text = existing.note;
      _kind = existing.kind;
      _selectedPaymentTypeId = existing.paymentTypeId;
      _selectedCategoryId = existing.categoryId;
      _date = existing.date;
    } else {
      if (widget.initialAmount != null) {
        _amountCtrl.text = widget.initialAmount!.toStringAsFixed(0);
      }
      if (widget.initialNote != null) _noteCtrl.text = widget.initialNote!;
      _selectedPaymentTypeId = widget.initialPaymentTypeId;
      _selectedCategoryId = widget.initialCategoryId;
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final amount = double.tryParse(_amountCtrl.text.trim());
    if (amount == null || amount <= 0) return;

    final pts = ref.read(paymentTypesProvider).valueOrNull ?? [];
    final cats = ref.read(categoriesProvider).valueOrNull ?? [];
    if (pts.isEmpty || cats.isEmpty) return;

    final pt = pts.firstWhere(
      (e) => e.id == _selectedPaymentTypeId,
      orElse: () => pts.first,
    );
    final cat = cats.firstWhere(
      (e) => e.id == _selectedCategoryId,
      orElse: () => cats.first,
    );

    final tx = TransactionModel(
      id: widget.existingTransaction?.id ?? const Uuid().v4(),
      amount: amount,
      kind: _kind,
      paymentTypeId: pt.id,
      paymentTypeName: pt.name,
      categoryId: cat.id,
      categoryName: cat.name,
      date: _date,
      note: _noteCtrl.text.trim(),
    );

    await ref.read(financeRepositoryProvider).addTransaction(tx);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final pts = ref.watch(paymentTypesProvider).valueOrNull ?? [];
    final cats = ref.watch(categoriesProvider).valueOrNull ?? [];

    _selectedPaymentTypeId ??= pts.isNotEmpty ? pts.first.id : null;

    // Ensure selected category still exists to prevent Dropdown assertion errors
    final validCatIds = cats.map((c) => c.id).toSet();
    if (_selectedCategoryId == null || !validCatIds.contains(_selectedCategoryId)) {
      _selectedCategoryId = cats.isNotEmpty ? cats.first.id : null;
    }

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          16,
          20,
          MediaQuery.viewInsetsOf(context).bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SegmentedButton<TransactionKind>(
                segments: const [
                  ButtonSegment(
                    value: TransactionKind.debit,
                    label: Text('Debit (Expense)'),
                    icon: Icon(Icons.arrow_upward_rounded, color: AppTheme.debitColor),
                  ),
                  ButtonSegment(
                    value: TransactionKind.credit,
                    label: Text('Credit (Income)'),
                    icon: Icon(Icons.arrow_downward_rounded, color: AppTheme.creditColor),
                  ),
                ],
                selected: {_kind},
                onSelectionChanged: (s) => setState(() => _kind = s.first),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _amountCtrl,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                decoration: const InputDecoration(
                  prefixText: '₹ ',
                  hintText: '0.00',
                ),
              ),
              const SizedBox(height: 16),
              Text('Payment Type', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: pts.map((pt) {
                  return ChoiceChip(
                    label: Text(pt.name),
                    selected: _selectedPaymentTypeId == pt.id,
                    onSelected: (_) => setState(() => _selectedPaymentTypeId = pt.id),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              Text('Category', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedCategoryId,
                isExpanded: true,
                borderRadius: BorderRadius.circular(12),
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                items: cats
                    .map(
                      (c) => DropdownMenuItem<String>(
                        value: c.id,
                        child: Text(c.name),
                      ),
                    )
                    .toList(),
                onChanged: (val) => setState(() => _selectedCategoryId = val),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _noteCtrl,
                      decoration: const InputDecoration(hintText: 'Optional note...'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _date,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) setState(() => _date = picked);
                    },
                    icon: const Icon(Icons.calendar_today, size: 16),
                    label: Text(DateFormat('dd MMM').format(_date)),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  onPressed: _submit,
                  child: Text(
                    widget.existingTransaction != null ? 'Update Transaction' : 'Save Transaction',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}