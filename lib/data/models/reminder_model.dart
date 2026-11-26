import 'package:cloud_firestore/cloud_firestore.dart';

class ReminderModel {
  final String id;
  final int notificationId;
  final String title;
  final double amount;
  final String paymentTypeId;
  final String paymentTypeName;
  final String categoryId;
  final String categoryName;
  final DateTime dueDate;
  final DateTime remindAt;
  final bool repeatMonthly;
  final bool isCompleted;

  const ReminderModel({
    required this.id,
    required this.notificationId,
    required this.title,
    required this.amount,
    required this.paymentTypeId,
    required this.paymentTypeName,
    required this.categoryId,
    required this.categoryName,
    required this.dueDate,
    required this.remindAt,
    required this.repeatMonthly,
    this.isCompleted = false,
  });

  Map<String, dynamic> toMap() => {
        'notificationId': notificationId,
        'title': title,
        'amount': amount,
        'paymentTypeId': paymentTypeId,
        'paymentTypeName': paymentTypeName,
        'categoryId': categoryId,
        'categoryName': categoryName,
        'dueDate': Timestamp.fromDate(dueDate),
        'remindAt': Timestamp.fromDate(remindAt),
        'repeatMonthly': repeatMonthly,
        'isCompleted': isCompleted,
      };

  factory ReminderModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return ReminderModel(
      id: doc.id,
      notificationId: d['notificationId'] ?? doc.id.hashCode.abs() % 100000,
      title: d['title'] ?? '',
      amount: (d['amount'] as num).toDouble(),
      paymentTypeId: d['paymentTypeId'] ?? '',
      paymentTypeName: d['paymentTypeName'] ?? '',
      categoryId: d['categoryId'] ?? '',
      categoryName: d['categoryName'] ?? '',
      dueDate: (d['dueDate'] as Timestamp).toDate(),
      remindAt: (d['remindAt'] as Timestamp).toDate(),
      repeatMonthly: d['repeatMonthly'] ?? false,
      isCompleted: d['isCompleted'] ?? false,
    );
  }

  /// Advances dueDate and remindAt by 1 month, clamping month-end days safely.
  ReminderModel nextMonthlyCycle() {
    DateTime addOneMonth(DateTime dt) {
      final targetMonth = dt.month == 12 ? 1 : dt.month + 1;
      final targetYear = dt.month == 12 ? dt.year + 1 : dt.year;
      final lastDayOfTarget = DateTime(targetYear, targetMonth + 1, 0).day;
      final clampedDay = dt.day > lastDayOfTarget ? lastDayOfTarget : dt.day;
      return DateTime(targetYear, targetMonth, clampedDay, dt.hour, dt.minute);
    }

    return ReminderModel(
      id: id,
      notificationId: notificationId,
      title: title,
      amount: amount,
      paymentTypeId: paymentTypeId,
      paymentTypeName: paymentTypeName,
      categoryId: categoryId,
      categoryName: categoryName,
      dueDate: addOneMonth(dueDate),
      remindAt: addOneMonth(remindAt),
      repeatMonthly: repeatMonthly,
      isCompleted: false,
    );
  }
}