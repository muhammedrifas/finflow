import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/currency_formatter.dart';
import '../../data/models/transaction_model.dart';
import '../../providers/finance_providers.dart';
import '../transactions/quick_add_sheet.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _queryCtrl = TextEditingController();
  final _minAmountCtrl = TextEditingController();
  final _maxAmountCtrl = TextEditingController();

  TransactionKind? _kindFilter; // null = All
  String? _paymentTypeId; // null = All
  String? _categoryId; // null = All
  DateTimeRange? _dateRange;

  @override
  void dispose() {
    _queryCtrl.dispose();
    _minAmountCtrl.dispose();
    _maxAmountCtrl.dispose();
    super.dispose();
  }

  void _clearFilters() {
    setState(() {
      _queryCtrl.clear();
      _minAmountCtrl.clear();
      _maxAmountCtrl.clear();
      _kindFilter = null;
      _paymentTypeId = null;
      _categoryId = null;
      _dateRange = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final allTxs = ref.watch(transactionsProvider).valueOrNull ?? [];
    final pts = ref.watch(paymentTypesProvider).valueOrNull ?? [];
    final cats = ref.watch(categoriesProvider).valueOrNull ?? [];

    final query = _queryCtrl.text.trim().toLowerCase();
    final minAmount = double.tryParse(_minAmountCtrl.text.trim());
    final maxAmount = double.tryParse(_maxAmountCtrl.text.trim());

    final results = allTxs.where((tx) {
      if (_kindFilter != null && tx.kind != _kindFilter) return false;
      if (_paymentTypeId != null && tx.paymentTypeId != _paymentTypeId) return false;
      if (_categoryId != null && tx.categoryId != _categoryId) return false;
      if (minAmount != null && tx.amount < minAmount) return false;
      if (maxAmount != null && tx.amount > maxAmount) return false;

      if (_dateRange != null) {
        final start = DateTime(
          _dateRange!.start.year,
          _dateRange!.start.month,
          _dateRange!.start.day,
        );
        final end = DateTime(
          _dateRange!.end.year,
          _dateRange!.end.month,
          _dateRange!.end.day,
          23,
          59,
          59,
        );
        if (tx.date.isBefore(start) || tx.date.isAfter(end)) return false;
      }

      if (query.isNotEmpty) {
        final hay = '${tx.note} ${tx.categoryName} ${tx.paymentTypeName}'.toLowerCase();
        if (!hay.contains(query)) return false;
      }
      return true;
    }).toList();

    final totalDebit = results
        .where((t) => t.kind == TransactionKind.debit)
        .fold(0.0, (s, t) => s + t.amount);
    final totalCredit = results
        .where((t) => t.kind == TransactionKind.credit)
        .fold(0.0, (s, t) => s + t.amount);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Transactions'),
        actions: [
          TextButton(onPressed: _clearFilters, child: const Text('Reset')),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            TextField(
              controller: _queryCtrl,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search notes, categories, or types...',
              ),
            ),
            const SizedBox(height: 12),
            SegmentedButton<TransactionKind?>(
              segments: const [
                ButtonSegment(value: null, label: Text('All')),
                ButtonSegment(value: TransactionKind.debit, label: Text('Debit')),
                ButtonSegment(value: TransactionKind.credit, label: Text('Credit')),
              ],
              selected: {_kindFilter},
              onSelectionChanged: (s) => setState(() => _kindFilter = s.first),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String?>(
                    value: _paymentTypeId,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Payment Type'),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('All Types')),
                      ...pts.map((pt) => DropdownMenuItem(value: pt.id, child: Text(pt.name))),
                    ],
                    onChanged: (v) => setState(() => _paymentTypeId = v),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<String?>(
                    value: _categoryId,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Category'),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('All Categories')),
                      ...cats.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))),
                    ],
                    onChanged: (v) => setState(() => _categoryId = v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _minAmountCtrl,
                    onChanged: (_) => setState(() {}),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      prefixText: '₹ ',
                      labelText: 'Min Amount',
                      hintText: 'Any',
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _maxAmountCtrl,
                    onChanged: (_) => setState(() {}),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      prefixText: '₹ ',
                      labelText: 'Max Amount',
                      hintText: 'Any',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              icon: const Icon(Icons.date_range),
              label: Text(
                _dateRange == null
                    ? 'Filter by Date Range (Optional)'
                    : '${DateFormat('dd MMM yy').format(_dateRange!.start)} - ${DateFormat('dd MMM yy').format(_dateRange!.end)}',
              ),
              onPressed: () async {
                final picked = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100),
                  initialDateRange: _dateRange,
                );
                if (picked != null) setState(() => _dateRange = picked);
              },
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${results.length} match(es)', style: const TextStyle(fontWeight: FontWeight.w600)),
                    Text(
                      'In: ${CurrencyFormatter.format(totalCredit)}  •  Out: ${CurrencyFormatter.format(totalDebit)}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (results.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: Text('No transactions match these filters.')),
              )
            else
              ...results.map((tx) {
                final isCredit = tx.kind == TransactionKind.credit;
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    onLongPress: () => showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      useSafeArea: true,
                      builder: (_) => QuickAddTransactionSheet(existingTransaction: tx),
                    ),
                    title: Text(
                      tx.note.isNotEmpty ? tx.note : tx.categoryName,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      '${tx.paymentTypeName} • ${tx.categoryName} • ${DateFormat('dd MMM yyyy').format(tx.date)}',
                    ),
                    trailing: Text(
                      '${isCredit ? '+' : '-'}${CurrencyFormatter.format(tx.amount)}',
                      style: TextStyle(
                        color: isCredit ? AppTheme.creditColor : AppTheme.debitColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}