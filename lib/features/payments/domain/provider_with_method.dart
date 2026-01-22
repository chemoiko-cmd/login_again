/// Each item from the API has both provider and payment method info
class ProviderWithMethod {
  final int providerId;
  final String providerCode;
  final String providerName;
  final String providerState;
  final int companyId;
  final int paymentMethodId;
  final String paymentCode;
  final String paymentMethodName;

  ProviderWithMethod({
    required this.providerId,
    required this.providerCode,
    required this.providerName,
    required this.providerState,
    required this.companyId,
    required this.paymentMethodId,
    required this.paymentCode,
    required this.paymentMethodName,
  });

  factory ProviderWithMethod.fromJson(Map<String, dynamic> json) {
    return ProviderWithMethod(
      providerId: json['provider_id'] as int,
      providerCode: json['provider_code'] as String? ?? '',
      providerName: json['provider_name'] as String? ?? '',
      providerState: json['provider_state'] as String? ?? '',
      companyId: json['company_id'] as int? ?? 0,
      paymentMethodId: json['payment_method_id'] as int,
      paymentCode: json['payment_code'] as String? ?? '',
      paymentMethodName: json['payment_method_name'] as String? ?? '',
    );
  }
}
