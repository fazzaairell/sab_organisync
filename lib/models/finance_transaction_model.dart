class FinanceTransactionModel {
  final String id;
  final String? organizationId;
  final String title;
  final int amount;
  final String type;
  final String date;
  final String note;

  FinanceTransactionModel({
    required this.id,
    required this.organizationId,
    required this.title,
    required this.amount,
    required this.type,
    required this.date,
    this.note = '',
  });

  bool get isIncome => type == 'in';

  FinanceTransactionModel copyWith({
    String? id,
    String? organizationId,
    String? title,
    int? amount,
    String? type,
    String? date,
    String? note,
  }) {
    return FinanceTransactionModel(
      id: id ?? this.id,
      organizationId: organizationId ?? this.organizationId,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      date: date ?? this.date,
      note: note ?? this.note,
    );
  }

  factory FinanceTransactionModel.fromJson(Map<String, dynamic> json) {
    return FinanceTransactionModel(
      id: json['id'] as String,
      organizationId: json['organizationId'] as String?,
      title: json['title'] as String,
      amount: json['amount'] as int,
      type: json['type'] as String,
      date: json['date'] as String,
      note: json['note'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'organizationId': organizationId,
      'title': title,
      'amount': amount,
      'type': type,
      'date': date,
      'note': note,
    };
  }
}
