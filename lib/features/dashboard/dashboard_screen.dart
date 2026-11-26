import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/currency_formatter.dart';
import '../../data/models/transaction_model.dart';
import '../../providers/finance_providers.dart';
import '../search/search_screen.dart';
import '../transactions/quick_add_sheet.dart';

class DashboardScreen extends ConsumerWidget {
  final VoidCallback? onDueTap;
  const DashboardScreen({super.key, this.onDueTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txAsync = ref.watch(transactionsProvider);
    final upcomingCount = ref.watch(homeDueRemindersCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('FinFlow', style: TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          if (upcomingCount > 0)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: ActionChip(
                avatar: const Icon(Icons.notifications_active, size: 16),
                label: Text('$upcomingCount due'),
                onPressed: onDueTap,
              ),
            ),
          IconButton(
            icon: const Icon(Icons.search_rounded),
            tooltip: 'Search Transactions',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SearchScreen()),
            ),
          ),
        ],
      ),
      body: txAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (txs) {
          final now = DateTime.now();
          final monthTxs = txs.where(
            (t) => t.date.year == now.year && t.date.month == now.month,
          );
          final totalCredit = monthTxs
              .where((t) => t.kind == TransactionKind.credit)
              .fold(0.0, (sum, t) => sum + t.amount);
          final totalDebit = monthTxs
              .where((t) => t.kind == TransactionKind.debit)
              .fold(0.0, (sum, t) => sum + t.amount);

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
            children: [
              _MonthlySummaryCard(credit: totalCredit, debit: totalDebit),
              const SizedBox(height: 20),
              Text(
                'Recent Transactions',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 10),
              if (txs.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(
                      child: Text('Tap + to log your first transaction.'),
                    ),
                  ),
                )
              else
                ...txs.take(30).map((tx) => _TransactionTile(tx: tx)),
            ],
          );
        },
      ),
    );
  }
}

class _MonthlySummaryCard extends StatelessWidget {
  final double credit;
  final double debit;
  const _MonthlySummaryCard({required this.credit, required this.debit});

  @override
  Widget build(BuildContext context) {
    final net = credit - debit;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${DateFormat('MMMM yyyy').format(DateTime.now())} Net Flow',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 6),
            Text(
              CurrencyFormatter.format(net),
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _StatPill(
                    label: 'Credit',
                    value: CurrencyFormatter.format(credit),
                    color: AppTheme.creditColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatPill(
                    label: 'Debit',
                    value: CurrencyFormatter.format(debit),
                    color: AppTheme.debitColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatPill({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _TransactionTile extends ConsumerWidget {
  final TransactionModel tx;
  const _TransactionTile({required this.tx});

  Future<bool> _confirmDelete(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Transaction?'),
        content: Text(
          'Delete ${CurrencyFormatter.format(tx.amount)} (${tx.note.isNotEmpty ? tx.note : tx.categoryName})? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppTheme.debitColor),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCredit = tx.kind == TransactionKind.credit;
    final color = isCredit ? AppTheme.creditColor : AppTheme.debitColor;

    return Dismissible(
      key: ValueKey(tx.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => _confirmDelete(context),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red.shade400,
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (_) =>
          ref.read(financeRepositoryProvider).deleteTransaction(tx.id),
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          title: Text(
            tx.note.isNotEmpty ? tx.note : tx.categoryName,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            '${tx.paymentTypeName} • ${tx.categoryName} • ${DateFormat('dd MMM').format(tx.date)}',
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${isCredit ? '+' : '-'}${CurrencyFormatter.format(tx.amount)}',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 20),
                tooltip: 'Delete',
                onPressed: () async {
                  if (await _confirmDelete(context)) {
                    await ref
                        .read(financeRepositoryProvider)
                        .deleteTransaction(tx.id);
                  }
                },
              ),
            ],
          ),
          onLongPress: () => showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            useSafeArea: true,
            builder: (_) => QuickAddTransactionSheet(existingTransaction: tx),
          ),
        ),
      ),
    );
  }
}