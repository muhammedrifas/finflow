import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentTypeModel {
  final String id;
  final String name;
  final bool isArchived;

  const PaymentTypeModel({
    required this.id,
    required this.name,
    this.isArchived = false,
  });

  Map<String, dynamic> toMap() => {'name': name, 'isArchived': isArchived};

  factory PaymentTypeModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return PaymentTypeModel(
      id: doc.id,
      name: d['name'] ?? '',
      isArchived: d['isArchived'] ?? false,
    );
  }
}