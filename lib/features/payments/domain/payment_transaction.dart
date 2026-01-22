class PaymentTransaction {
  final int? id;
  final double amount;
  final int currencyId;
  final int partnerId;
  final int providerId;
  final int paymentMethodId;
  final List<int> invoiceIds;
  final String operation;
  final String?
  state; // 'draft', 'pending', 'authorized', 'done', 'canceled', 'error'
  final String? reference;
  final DateTime? createDate;

  PaymentTransaction({
    this.id,
    required this.amount,
    required this.currencyId,
    required this.partnerId,
    required this.providerId,
    required this.paymentMethodId,
    required this.invoiceIds,
    this.operation = 'online_direct',
    this.state,
    this.reference,
    this.createDate,
  });

  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'currency_id': currencyId,
      'partner_id': partnerId,
      'provider_id': providerId,
      'payment_method_id': paymentMethodId,
      'invoice_ids': [
        [6, 0, invoiceIds],
      ],
      'operation': operation,
    };
  }

  factory PaymentTransaction.fromJson(Map<String, dynamic> json) {
    return PaymentTransaction(
      id: json['id'] as int?,
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      currencyId: json['currency_id'] as int? ?? 0,
      partnerId: json['partner_id'] as int? ?? 0,
      providerId: json['provider_id'] as int? ?? 0,
      paymentMethodId: json['payment_method_id'] as int? ?? 0,
      invoiceIds: (json['invoice_ids'] as List?)?.cast<int>() ?? [],
      operation: json['operation'] as String? ?? 'online_direct',
      state: json['state'] as String?,
      reference: json['reference'] as String?,
      createDate: json['create_date'] != null
          ? DateTime.tryParse(json['create_date'].toString())
          : null,
    );
  }

  PaymentTransaction copyWith({
    int? id,
    double? amount,
    int? currencyId,
    int? partnerId,
    int? providerId,
    int? paymentMethodId,
    List<int>? invoiceIds,
    String? operation,
    String? state,
    String? reference,
    DateTime? createDate,
  }) {
    return PaymentTransaction(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      currencyId: currencyId ?? this.currencyId,
      partnerId: partnerId ?? this.partnerId,
      providerId: providerId ?? this.providerId,
      paymentMethodId: paymentMethodId ?? this.paymentMethodId,
      invoiceIds: invoiceIds ?? this.invoiceIds,
      operation: operation ?? this.operation,
      state: state ?? this.state,
      reference: reference ?? this.reference,
      createDate: createDate ?? this.createDate,
    );
  }
}
