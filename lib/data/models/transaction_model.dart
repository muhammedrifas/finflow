import 'package:cloud_firestore/cloud_firestore.dart';

enum TransactionKind { debit, credit }

class TransactionModel {
  final String id;
  final double amount;
  final TransactionKind kind;
  final String paymentTypeId;
  final String paymentTypeName;
  final String categoryId;
  final String categoryName;
  final DateTime date;
  final String note;

  const TransactionModel({
    required this.id,
    required this.amount,
    required this.kind,
    required this.paymentTypeId,
    required this.paymentTypeName,
    required this.categoryId,
    required this.categoryName,
    required this.date,
    this.note = '',
  });

  Map<String, dynamic> toMap() => {
        'amount': amount,
        'kind': kind.name,
        'paymentTypeId': paymentTypeId,
        'paymentTypeName': paymentTypeName,
        'categoryId': categoryId,
        'categoryName': categoryName,
        'date': Timestamp.fromDate(date),
        'note': note,
      };

  factory TransactionModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return TransactionModel(
      id: doc.id,
      amount: (d['amount'] as num).toDouble(),
      kind: d['kind'] == 'credit' ? TransactionKind.credit : TransactionKind.debit,
      paymentTypeId: d['paymentTypeId'] ?? '',
      paymentTypeName: d['paymentTypeName'] ?? 'Unknown',
      categoryId: d['categoryId'] ?? '',
      categoryName: d['categoryName'] ?? 'General',
      date: (d['date'] as Timestamp).toDate(),
      note: d['note'] ?? '',
    );
  }
}