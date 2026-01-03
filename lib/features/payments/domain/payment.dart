class PaymentItem {
  final String id;
  final double amount;
  final DateTime dueDate;
  final DateTime? paidDate;
  final String status; // 'pending' | 'paid' | 'overdue'
  final String type; // 'rent' | 'utility' | other
  final String description;

  PaymentItem({
    required this.id,
    required this.amount,
    required this.dueDate,
    this.paidDate,
    required this.status,
    required this.type,
    required this.description,
  });

  PaymentItem copyWith({
    String? id,
    double? amount,
    DateTime? dueDate,
    DateTime? paidDate,
    String? status,
    String? type,
    String? description,
  }) {
    return PaymentItem(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      dueDate: dueDate ?? this.dueDate,
      paidDate: paidDate ?? this.paidDate,
      status: status ?? this.status,
      type: type ?? this.type,
      description: description ?? this.description,
    );
  }
}
