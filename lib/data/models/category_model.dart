import 'package:cloud_firestore/cloud_firestore.dart';

class CategoryModel {
  final String id;
  final String name;
  final bool isIncome;

  const CategoryModel({
    required this.id,
    required this.name,
    this.isIncome = false,
  });

  Map<String, dynamic> toMap() => {'name': name, 'isIncome': isIncome};

  factory CategoryModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return CategoryModel(
      id: doc.id,
      name: d['name'] ?? '',
      isIncome: d['isIncome'] ?? false,
    );
  }
}