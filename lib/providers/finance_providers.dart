import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/category_model.dart';
import '../data/models/payment_type_model.dart';
import '../data/models/reminder_model.dart';
import '../data/models/transaction_model.dart';
import '../data/repositories/finance_repository.dart';
import '../data/repositories/firestore_finance_repository.dart';

final financeRepositoryProvider = Provider<FinanceRepository>((ref) {
  final uid = FirebaseAuth.instance.currentUser!.uid;
  return FirestoreFinanceRepository(FirebaseFirestore.instance, uid);
});

final transactionsProvider = StreamProvider<List<TransactionModel>>(
  (ref) => ref.watch(financeRepositoryProvider).watchTransactions(),
);

final paymentTypesProvider = StreamProvider<List<PaymentTypeModel>>(
  (ref) => ref.watch(financeRepositoryProvider).watchPaymentTypes(),
);

final categoriesProvider = StreamProvider<List<CategoryModel>>(
  (ref) => ref.watch(financeRepositoryProvider).watchCategories(),
);

final remindersProvider = StreamProvider<List<ReminderModel>>(
  (ref) => ref.watch(financeRepositoryProvider).watchReminders(),
);

/// Returns all reminders (checked & unchecked) within a +/- 30 day window.
final upcomingWindowRemindersProvider = Provider<List<ReminderModel>>((ref) {
  final all = ref.watch(remindersProvider).valueOrNull ?? [];
  final now = DateTime.now();
  final start = now.subtract(const Duration(days: 30));
  final end = now.add(const Duration(days: 30));
  return all
      .where((r) => r.dueDate.isAfter(start) && r.dueDate.isBefore(end))
      .toList();
});

/// Counts unchecked reminders that are either overdue (past) or due within 7 days.
final homeDueRemindersCountProvider = Provider<int>((ref) {
  final all = ref.watch(remindersProvider).valueOrNull ?? [];
  final now = DateTime.now();
  final sevenDaysFromNow = DateTime(now.year, now.month, now.day, 23, 59, 59)
      .add(const Duration(days: 7));

  return all
      .where((r) => !r.isCompleted && !r.dueDate.isAfter(sevenDaysFromNow))
      .length;
});