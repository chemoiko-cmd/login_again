class LandlordTenantRow {
  final int contractId;
  final String contractName;
  final int tenantPartnerId;
  final String tenantName;
  final String propertyName;
  final String unitName;
  final String? status; // paid | pending | overdue
  final List<int>? avatarBytes;

  const LandlordTenantRow({
    required this.contractId,
    required this.contractName,
    required this.tenantPartnerId,
    required this.tenantName,
    required this.propertyName,
    required this.unitName,
    this.status,
    this.avatarBytes,
  });

  LandlordTenantRow copyWith({
    int? contractId,
    String? contractName,
    int? tenantPartnerId,
    String? tenantName,
    String? propertyName,
    String? unitName,
    String? status,
    List<int>? avatarBytes,
  }) {
    return LandlordTenantRow(
      contractId: contractId ?? this.contractId,
      contractName: contractName ?? this.contractName,
      tenantPartnerId: tenantPartnerId ?? this.tenantPartnerId,
      tenantName: tenantName ?? this.tenantName,
      propertyName: propertyName ?? this.propertyName,
      unitName: unitName ?? this.unitName,
      status: status ?? this.status,
      avatarBytes: avatarBytes ?? this.avatarBytes,
    );
  }
}
