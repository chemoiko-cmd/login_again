class Invoice {
  final int id;
  final String name;
  final double amountTotal;
  final double amountResidual;
  final String? paymentState;
  final DateTime? invoiceDate;
  final DateTime? invoiceDateDue;
  final String? state;
  final String moveType;
  final int? partnerId;
  final String? partnerName;
  final int? currencyId;
  final String? currencyName;

  Invoice({
    required this.id,
    required this.name,
    required this.amountTotal,
    required this.amountResidual,
    this.paymentState,
    this.invoiceDate,
    this.invoiceDateDue,
    this.state,
    required this.moveType,
    this.partnerId,
    this.partnerName,
    this.currencyId,
    this.currencyName,
  });

  bool get isPaid => amountResidual <= 0.0001;

  bool get isOverdue {
    if (isPaid) return false;
    final dueDate = invoiceDateDue;
    if (dueDate == null) return false;
    final now = DateTime.now();
    return dueDate.isBefore(DateTime(now.year, now.month, now.day));
  }

  String get statusText {
    if (isPaid) return 'paid';
    if (isOverdue) return 'overdue';
    return 'pending';
  }

  factory Invoice.fromJson(Map<String, dynamic> json) {
    return Invoice(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      amountTotal: (json['amount_total'] as num?)?.toDouble() ?? 0.0,
      amountResidual: (json['amount_residual'] as num?)?.toDouble() ?? 0.0,
      paymentState: json['payment_state'] as String?,
      invoiceDate: json['invoice_date'] != null
          ? DateTime.tryParse(json['invoice_date'].toString())
          : null,
      invoiceDateDue: json['invoice_date_due'] != null
          ? DateTime.tryParse(json['invoice_date_due'].toString())
          : null,
      state: json['state'] as String?,
      moveType: json['move_type'] as String? ?? 'out_invoice',
      partnerId: (json['partner_id'] is List)
          ? (json['partner_id'] as List).first as int?
          : json['partner_id'] as int?,
      partnerName:
          (json['partner_id'] is List &&
              (json['partner_id'] as List).length > 1)
          ? (json['partner_id'] as List)[1] as String?
          : null,
      currencyId: (json['currency_id'] is List)
          ? (json['currency_id'] as List).first as int?
          : json['currency_id'] as int?,
      currencyName:
          (json['currency_id'] is List &&
              (json['currency_id'] as List).length > 1)
          ? (json['currency_id'] as List)[1] as String?
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'amount_total': amountTotal,
      'amount_residual': amountResidual,
      if (paymentState != null) 'payment_state': paymentState,
      if (invoiceDate != null) 'invoice_date': invoiceDate!.toIso8601String(),
      if (invoiceDateDue != null)
        'invoice_date_due': invoiceDateDue!.toIso8601String(),
      if (state != null) 'state': state,
      'move_type': moveType,
      if (partnerId != null) 'partner_id': partnerId,
      if (currencyId != null) 'currency_id': currencyId,
    };
  }
}
