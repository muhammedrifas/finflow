import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/services/notification_service.dart';
import '../models/category_model.dart';
import '../models/payment_type_model.dart';
import '../models/reminder_model.dart';
import '../models/transaction_model.dart';
import 'finance_repository.dart';

class FirestoreFinanceRepository implements FinanceRepository {
  final FirebaseFirestore _db;
  final String _uid;

  FirestoreFinanceRepository(this._db, this._uid);

  DocumentReference<Map<String, dynamic>> get _userDoc =>
      _db.collection('users').doc(_uid);

  CollectionReference<Map<String, dynamic>> get _txCol =>
      _userDoc.collection('transactions');
  CollectionReference<Map<String, dynamic>> get _ptCol =>
      _userDoc.collection('payment_types');
  CollectionReference<Map<String, dynamic>> get _catCol =>
      _userDoc.collection('categories');
  CollectionReference<Map<String, dynamic>> get _remCol =>
      _userDoc.collection('reminders');

  @override
  Future<void> seedDefaultsIfEmpty() async {
    final ptSnap = await _ptCol.limit(1).get();
    if (ptSnap.docs.isEmpty) {
      final batch = _db.batch();
      for (final name in ['Cash', 'UPI', 'Credit Card 1', 'Bank Account']) {
        batch.set(_ptCol.doc(), {'name': name, 'isArchived': false});
      }
      for (final cat in [
        ('Food & Dining', false),
        ('Bills & Utilities', false),
        ('Fuel & Travel', false),
        ('Groceries', false),
        ('Shopping', false),
        ('Salary / Income', true),
      ]) {
        batch.set(_catCol.doc(), {'name': cat.$1, 'isIncome': cat.$2});
      }
      await batch.commit();
    }
  }

  @override
  Stream<List<TransactionModel>> watchTransactions() => _txCol
      .orderBy('date', descending: true)
      .snapshots()
      .map((s) => s.docs.map(TransactionModel.fromDoc).toList());

  @override
  Future<void> addTransaction(TransactionModel tx) =>
      _txCol.doc(tx.id).set(tx.toMap());

  @override
  Future<void> deleteTransaction(String id) => _txCol.doc(id).delete();

  @override
  Stream<List<PaymentTypeModel>> watchPaymentTypes() => _ptCol
      .orderBy('name')
      .snapshots()
      .map((s) => s.docs.map(PaymentTypeModel.fromDoc).toList());

  @override
  Future<void> addPaymentType(String name) =>
      _ptCol.add({'name': name.trim(), 'isArchived': false});

  @override
  Future<void> deletePaymentType(String id) => _ptCol.doc(id).delete();

  @override
  Stream<List<CategoryModel>> watchCategories() => _catCol
      .orderBy('name')
      .snapshots()
      .map((s) => s.docs.map(CategoryModel.fromDoc).toList());

  @override
  Future<void> addCategory(String name, {bool isIncome = false}) =>
      _catCol.add({'name': name.trim(), 'isIncome': isIncome});

  @override
  Future<void> deleteCategory(String id) => _catCol.doc(id).delete();

  @override
  Stream<List<ReminderModel>> watchReminders() => _remCol
      .orderBy('dueDate')
      .snapshots()
      .map((s) => s.docs.map(ReminderModel.fromDoc).toList());

  @override
  Future<void> saveReminder(ReminderModel reminder) async {
    await _remCol.doc(reminder.id).set(reminder.toMap());
    await NotificationService.instance.scheduleReminder(
      id: reminder.notificationId,
      title: 'Upcoming Payment: ${reminder.title}',
      body: 'Amount due: ₹${reminder.amount.toStringAsFixed(0)}',
      scheduledTime: reminder.remindAt,
    );
  }

  @override
  Future<void> toggleReminderCompleted(
    ReminderModel reminder,
    bool isCompleted,
  ) async {
    await _remCol.doc(reminder.id).update({'isCompleted': isCompleted});

    if (isCompleted) {
      await NotificationService.instance.cancel(reminder.notificationId);
    } else {
      await NotificationService.instance.scheduleReminder(
        id: reminder.notificationId,
        title: 'Upcoming Payment: ${reminder.title}',
        body: 'Amount due: ₹${reminder.amount.toStringAsFixed(0)}',
        scheduledTime: reminder.remindAt,
      );
    }
  }

  @override
  Future<void> deleteReminder(
    ReminderModel reminder, {
    bool deleteFuture = true,
  }) async {
    await NotificationService.instance.cancel(reminder.notificationId);

    if (reminder.repeatMonthly && !deleteFuture) {
      final nextCycle = reminder.nextMonthlyCycle();
      await saveReminder(nextCycle);
    } else {
      await _remCol.doc(reminder.id).delete();
    }
  }
}