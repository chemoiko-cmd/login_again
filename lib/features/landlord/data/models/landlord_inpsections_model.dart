class Inspection {
  final String name;
  final String state;
  final String propertyName;
  final String unitName;

  Inspection({
    required this.name,
    required this.state,
    required this.propertyName,
    required this.unitName,
  });

  factory Inspection.fromJson(Map<String, dynamic> json) {
    return Inspection(
      name: json['name'] ?? 'Inspection',
      state: json['state'] ?? 'pending',
      propertyName: json['property_name'] ?? '-',
      unitName: json['unit_name'] ?? '-',
    );
  }
}
