import '../models/category_model.dart';
import '../models/payment_type_model.dart';
import '../models/reminder_model.dart';
import '../models/transaction_model.dart';

abstract class FinanceRepository {
  Future<void> seedDefaultsIfEmpty();

  Stream<List<TransactionModel>> watchTransactions();
  Future<void> addTransaction(TransactionModel tx);
  Future<void> deleteTransaction(String id);

  Stream<List<PaymentTypeModel>> watchPaymentTypes();
  Future<void> addPaymentType(String name);
  Future<void> deletePaymentType(String id);

  Stream<List<CategoryModel>> watchCategories();
  Future<void> addCategory(String name, {bool isIncome = false});
  Future<void> deleteCategory(String id);

  Stream<List<ReminderModel>> watchReminders();
  Future<void> saveReminder(ReminderModel reminder);
  Future<void> toggleReminderCompleted(ReminderModel reminder, bool isCompleted);
  Future<void> deleteReminder(ReminderModel reminder, {bool deleteFuture = true});
}