import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/utils/currency_formatter.dart';
import '../../data/models/transaction_model.dart';
import '../../providers/finance_providers.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  DateTimeRange _range = DateTimeRange(
    start: DateTime(DateTime.now().year, DateTime.now().month, 1),
    end: DateTime.now(),
  );
  bool _groupByPaymentType = true;

  static const _palette = [
    Color(0xFF0F766E),
    Color(0xFF2563EB),
    Color(0xFFF59E0B),
    Color(0xFFEC4899),
    Color(0xFF8B5CF6),
    Color(0xFF10B981),
  ];

  @override
  Widget build(BuildContext context) {
    final allTxs = ref.watch(transactionsProvider).valueOrNull ?? [];
    final filtered = allTxs.where((t) {
      final start = DateTime(_range.start.year, _range.start.month, _range.start.day);
      final end = DateTime(_range.end.year, _range.end.month, _range.end.day, 23, 59, 59);
      return !t.date.isBefore(start) && !t.date.isAfter(end);
    }).toList();

    final debits = filtered.where((t) => t.kind == TransactionKind.debit).toList();
    final totalDebit = debits.fold(0.0, (s, t) => s + t.amount);
    final totalCredit = filtered
        .where((t) => t.kind == TransactionKind.credit)
        .fold(0.0, (s, t) => s + t.amount);

    final Map<String, double> grouped = {};
    for (final tx in debits) {
      final key = _groupByPaymentType ? tx.paymentTypeName : tx.categoryName;
      grouped[key] = (grouped[key] ?? 0) + tx.amount;
    }
    final entries = grouped.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Financial Reports'),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.date_range),
            label: Text(
              '${DateFormat('dd MMM').format(_range.start)} - ${DateFormat('dd MMM').format(_range.end)}',
            ),
            onPressed: () async {
              final picked = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2020),
                lastDate: DateTime(2100),
                initialDateRange: _range,
              );
              if (picked != null) setState(() => _range = picked);
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
        children: [
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: true, label: Text('By Payment Type')),
              ButtonSegment(value: false, label: Text('By Category')),
            ],
            selected: {_groupByPaymentType},
            onSelectionChanged: (s) => setState(() => _groupByPaymentType = s.first),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      const Text('Total Credit'),
                      Text(
                        CurrencyFormatter.format(totalCredit),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      const Text('Total Debit'),
                      Text(
                        CurrencyFormatter.format(totalDebit),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          if (entries.isNotEmpty)
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 3,
                  centerSpaceRadius: 48,
                  sections: List.generate(entries.length, (i) {
                    final e = entries[i];
                    final pct = totalDebit == 0 ? 0 : (e.value / totalDebit * 100);
                    return PieChartSectionData(
                      value: e.value,
                      color: _palette[i % _palette.length],
                      title: '${pct.toStringAsFixed(0)}%',
                      radius: 46,
                      titleStyle: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    );
                  }),
                ),
              ),
            ),
          const SizedBox(height: 20),
          ...List.generate(entries.length, (i) {
            final e = entries[i];
            final ratio = totalDebit == 0 ? 0.0 : e.value / totalDebit;
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(e.key, style: const TextStyle(fontWeight: FontWeight.w600)),
                        Text(
                          CurrencyFormatter.format(e.value),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: ratio,
                      color: _palette[i % _palette.length],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}