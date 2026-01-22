class PaymentMethod {
  final int id;
  final String name;
  final String? code;
  final int? providerId;
  final String? providerName;
  final bool? active;

  PaymentMethod({
    required this.id,
    required this.name,
    this.code,
    this.providerId,
    this.providerName,
    this.active,
  });

  factory PaymentMethod.fromJson(Map<String, dynamic> json) {
    return PaymentMethod(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      code: json['code'] as String?,
      providerId: (json['provider_id'] is List)
          ? (json['provider_id'] as List).first as int?
          : json['provider_id'] as int?,
      providerName:
          (json['provider_id'] is List &&
              (json['provider_id'] as List).length > 1)
          ? (json['provider_id'] as List)[1] as String?
          : null,
      active: json['active'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (code != null) 'code': code,
      if (providerId != null) 'provider_id': providerId,
      if (active != null) 'active': active,
    };
  }
}
